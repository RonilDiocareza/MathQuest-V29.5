import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_account.dart';
import 'leaderboard_service.dart';

class AuthService {
  static final _auth = FirebaseAuth.instance;
  static final _users = FirebaseFirestore.instance.collection('users');
  static final _sessions =
      FirebaseFirestore.instance.collection('activeSessions');
  static const _deviceIdKey = 'mathquest_device_id';
  static const _sessionIdKeyPrefix = 'mathquest_session_id_';

  static User? get currentUser => _auth.currentUser;

  static Future<UserAccount> signIn(String email, String password) async {
    final credential = await _auth.signInWithEmailAndPassword(
      email: email.trim().toLowerCase(),
      password: password,
    );
    final uid = credential.user!.uid;
    String? sessionId;
    String? deviceId;
    try {
      deviceId = await _getDeviceId();
      sessionId = await _claimLoginSession(uid, deviceId);

      final account = await getAccount(uid);
      if (account == null) {
        throw StateError(
          'Your account profile is missing for UID $uid. '
          'Create the users document with this exact ID in the same Firebase project.',
        );
      }
      final preferences = await SharedPreferences.getInstance();
      await preferences.setString(
        '$_sessionIdKeyPrefix$uid',
        sessionId,
      );
      return account;
    } catch (_) {
      var failedSessionId = sessionId;
      failedSessionId ??= sessionId;
      if (failedSessionId != null && deviceId != null) {
        try {
          await _releaseLoginSession(uid, deviceId, failedSessionId);
        } catch (error, stackTrace) {
          debugPrint('Unable to release failed login session: $error');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      await _auth.signOut();
      rethrow;
    }
  }

  static Future<UserAccount> register({
    required String email,
    required String password,
    required String name,
    required String address,
    required String lrn,
    required String character,
  }) async {
    late UserCredential credential;
    var createdAuthUser = false;
    try {
      credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
      createdAuthUser = true;
    } on FirebaseAuthException catch (error) {
      if (error.code != 'email-already-in-use') rethrow;
      credential = await _auth.signInWithEmailAndPassword(
        email: email.trim().toLowerCase(),
        password: password,
      );
    }
    final account = UserAccount(
      uid: credential.user!.uid,
      email: email.trim().toLowerCase(),
      role: 'student',
      status: 'pending',
      name: name,
      address: address,
      lrn: lrn,
      character: character,
    );
    try {
      await FirebaseFunctions.instance.httpsCallable('registerStudent').call({
        'name': name,
        'address': address,
        'lrn': lrn,
        'character': character,
      });
      if (createdAuthUser) {
        await LeaderboardService.createRegistrationEntry(
          uid: credential.user!.uid,
          displayName: name,
        );
      }
    } catch (error) {
      if (createdAuthUser &&
          error is FirebaseFunctionsException &&
          (error.code == 'already-exists' ||
              error.code == 'invalid-argument')) {
        try {
          await credential.user!.delete();
        } catch (cleanupError, stackTrace) {
          debugPrint('Unable to clean up rejected registration: $cleanupError');
          debugPrintStack(stackTrace: stackTrace);
        }
      }
      await _auth.signOut();
      rethrow;
    }
    await _auth.signOut();
    return account;
  }

  static Future<UserAccount?> getAccount(String uid) async {
    final snapshot = await _users.doc(uid).get();
    if (!snapshot.exists) return null;
    return UserAccount.fromJson({...snapshot.data()!, 'uid': snapshot.id});
  }

  static Future<List<UserAccount>> loadAccounts() async {
    final snapshot = await _users.orderBy('name').get();
    return snapshot.docs
        .map((doc) => UserAccount.fromJson({...doc.data(), 'uid': doc.id}))
        .toList();
  }

  static Future<void> updateAccount(UserAccount account) {
    final currentLrn = account.lrn.trim();
    return _users.doc(account.uid).get().then((snapshot) {
      if (snapshot.data()?['lrn'] != currentLrn) {
        throw StateError('An account LRN cannot be changed.');
      }
      final data = account.toJson()..remove('uid');
      return _users.doc(account.uid).update(data);
    });
  }

  static Future<void> deleteAccount(UserAccount account) {
    return _users.doc(account.uid).delete();
  }

  static Future<void> updateCurrentProfile({
    required String name,
    required String address,
    String? profilePhotoUrl,
  }) async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in.');
    final updates = <String, dynamic>{
      'name': name,
      'address': address,
    };
    if (profilePhotoUrl != null) {
      updates['profilePhotoUrl'] = profilePhotoUrl;
    }
    await _users.doc(user.uid).update(updates);
  }

  static Future<void> updateCurrentProfilePhotoUrl(String photoUrl) async {
    final user = currentUser;
    if (user == null) throw StateError('Not signed in.');
    await _users.doc(user.uid).update({'profilePhotoUrl': photoUrl});
  }

  static Future<String> _getDeviceId() async {
    final preferences = await SharedPreferences.getInstance();
    final existing = preferences.getString(_deviceIdKey);
    if (existing != null && existing.length >= 16) return existing;

    final random = Random.secure();
    final deviceId = List<int>.generate(
      32,
      (_) => random.nextInt(256),
    ).map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();
    await preferences.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  static Future<String> _claimLoginSession(String uid, String deviceId) {
    final sessionRef = _sessions.doc(uid);
    return FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (snapshot.exists) {
        final data = snapshot.data()!;
        if (data['deviceId'] != deviceId) {
          throw StateError(
            'This account is already active on another device. '
            'Sign out there first, or ask an admin to clear its session.',
          );
        }
        final existingSessionId = data['sessionId'];
        if (existingSessionId is! String || existingSessionId.isEmpty) {
          throw StateError(
            'This device session is incomplete. Ask an administrator to clear it.',
          );
        }
        return existingSessionId;
      }

      final sessionId = _generateSessionId();
      transaction.set(sessionRef, {
        'deviceId': deviceId,
        'sessionId': sessionId,
        'claimedAt': FieldValue.serverTimestamp(),
      });
      return sessionId;
    });
  }

  static String _generateSessionId() {
    final random = Random.secure();
    return List<int>.generate(32, (_) => random.nextInt(256))
        .map((byte) => byte.toRadixString(16).padLeft(2, '0'))
        .join();
  }

  static Future<void> _releaseLoginSession(
    String uid,
    String deviceId,
    String sessionId,
  ) async {
    final sessionRef = _sessions.doc(uid);
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(sessionRef);
      if (!snapshot.exists) return;
      final data = snapshot.data()!;
      if (data['deviceId'] == deviceId && data['sessionId'] == sessionId) {
        transaction.delete(sessionRef);
      }
    });
  }

  static Future<void> signOut() async {
    final currentUid = _auth.currentUser?.uid;
    final uid = currentUid;
    final preferences = await SharedPreferences.getInstance();
    String? sessionId =
        uid == null ? null : preferences.getString('$_sessionIdKeyPrefix$uid');
    if (uid != null && _auth.currentUser != null) {
      final deviceId = await _getDeviceId();
      if (sessionId == null) {
        final snapshot = await _sessions.doc(uid).get();
        final data = snapshot.data();
        if (data?['deviceId'] == deviceId && data?['sessionId'] is String) {
          sessionId = data!['sessionId'] as String;
        }
      }
      if (sessionId != null) {
        await _releaseLoginSession(uid, deviceId, sessionId);
      }
    }
    if (uid != null) await preferences.remove('$_sessionIdKeyPrefix$uid');
    await _auth.signOut();
  }

  static Future<void> clearAccountLoginSession(String uid) async {
    await _sessions.doc(uid).delete();
  }
}
