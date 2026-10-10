import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class LeaderboardEntry {
  final String uid;
  final String displayName;
  final int totalScore;
  final int highestCompletedLevel;

  const LeaderboardEntry({
    required this.uid,
    required this.displayName,
    required this.totalScore,
    this.highestCompletedLevel = 0,
  });
}

class LeaderboardService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static final FirebaseAuth _auth = FirebaseAuth.instance;

  static const String collectionName = 'leaderboard';

  static CollectionReference<Map<String, dynamic>> get _collection =>
      _firestore.collection(collectionName);

  static Stream<List<LeaderboardEntry>> watchTopEntries({
    int? limit,
  }) {
    Query<Map<String, dynamic>> query =
        _collection.orderBy('totalScore', descending: true);
    if (limit != null) {
      query = query.limit(limit);
    }

    return query.snapshots().map(
          (snapshot) => snapshot.docs
              .map(_entryFromDocument)
              .whereType<LeaderboardEntry>()
              .toList(),
        );
  }

  static Stream<LeaderboardEntry?> watchCurrentEntry() {
    final user = _auth.currentUser;

    if (user == null) {
      return Stream.value(null);
    }

    return _collection.doc(user.uid).snapshots().map((document) {
      if (!document.exists) {
        return null;
      }

      return _entryFromDocument(document);
    });
  }

  static LeaderboardEntry? _entryFromDocument(
    DocumentSnapshot<Map<String, dynamic>> document,
  ) {
    final data = document.data();

    if (data == null) {
      return null;
    }

    final uid = (data['uid'] ?? document.id).toString();

    final displayName =
        (data['displayName'] ?? data['displayname'] ?? data['name'] ?? 'Player')
            .toString();

    final rawScore = data['totalScore'] ?? data['totalscore'] ?? 0;

    int totalScore;

    if (rawScore is int) {
      totalScore = rawScore;
    } else if (rawScore is num) {
      totalScore = rawScore.toInt();
    } else {
      totalScore = int.tryParse(rawScore.toString()) ?? 0;
    }

    return LeaderboardEntry(
      uid: uid,
      displayName: displayName,
      totalScore: totalScore,
      highestCompletedLevel:
          (data['highestCompletedLevel'] as num?)?.toInt() ?? 0,
    );
  }

  static int _progressScore(Map<String, dynamic> userData) {
    final progress = userData['progress'] as Map<String, dynamic>? ?? {};
    final completedLevels = <int>{};
    for (final value in progress['completedLevels'] as List<dynamic>? ?? []) {
      final level = int.tryParse(value.toString());
      if (level != null && level >= 1 && level <= 60) {
        completedLevels.add(level);
      }
    }

    final questionsByLevel =
        progress['completedNpcQuestionsByLevel'] as Map<String, dynamic>? ?? {};
    var npcQuestionCount = 0;
    for (final questions in questionsByLevel.values) {
      if (questions is List) {
        npcQuestionCount += questions.toSet().length;
      }
    }
    if (!questionsByLevel.containsKey('1')) {
      npcQuestionCount +=
          (progress['completedNpcQuestions'] as List<dynamic>? ?? [])
              .toSet()
              .length;
    }

    final savedScore = userData['gameScore'];
    final baseline = userData['scoreBaseline'];
    final earned = userData['scoreEarned'];
    final storedScore = savedScore is num
        ? savedScore.toInt()
        : baseline is num && earned is num
            ? baseline.toInt() + earned.toInt()
            : 0;
    final progressScore = (completedLevels.length + npcQuestionCount) * 10;
    return storedScore > progressScore ? storedScore : progressScore;
  }

  static int _highestCompletedLevel(Map<String, dynamic> userData) {
    final progress = userData['progress'] as Map<String, dynamic>? ?? {};
    final completedLevels = (progress['completedLevels'] as List<dynamic>? ?? [])
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .where((level) => level >= 1 && level <= 60)
        .toList();
    if (completedLevels.isNotEmpty) {
      return completedLevels.reduce((a, b) => a > b ? a : b);
    }
    final unlocked = progress['unlockedLevels'];
    return unlocked is num ? unlocked.toInt() : 0;
  }

  static Future<void> createRegistrationEntry({
    required String uid,
    required String displayName,
  }) async {
    await _collection.doc(uid).set({
      'uid': uid,
      'displayName': displayName,
      'totalScore': 0,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> ensureCurrentEntry() async {
    final user = _auth.currentUser;
    if (user == null) {
      throw StateError('No logged-in user.');
    }
    final userRef = _firestore.collection('users').doc(user.uid);
    final leaderboardRef = _collection.doc(user.uid);
    await _firestore.runTransaction((transaction) async {
      final userSnapshot = await transaction.get(userRef);
      if (!userSnapshot.exists) {
        throw StateError('User profile not found.');
      }

      final userData = userSnapshot.data();
      if (userData == null ||
          userData['role']?.toString().toLowerCase() != 'student' ||
          userData['status']?.toString().toLowerCase() != 'approved') {
        throw StateError('Only approved students can join the leaderboard.');
      }

      final leaderboardSnapshot = await transaction.get(leaderboardRef);
      if (leaderboardSnapshot.exists) return;

      transaction.set(leaderboardRef, {
        'uid': user.uid,
        'displayName': (userData['name'] ?? 'Player').toString(),
        'totalScore': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> initializeApprovedStudentEntry(String uid) async {
    final admin = _auth.currentUser;
    if (admin == null) {
      throw StateError('No logged-in admin.');
    }

    final adminRef = _firestore.collection('users').doc(admin.uid);
    final studentRef = _firestore.collection('users').doc(uid);
    final leaderboardRef = _collection.doc(uid);
    await _firestore.runTransaction((transaction) async {
      final adminSnapshot = await transaction.get(adminRef);
      final studentSnapshot = await transaction.get(studentRef);
      final leaderboardSnapshot = await transaction.get(leaderboardRef);

      if (adminSnapshot.data()?['role']?.toString().toLowerCase() != 'admin') {
        throw StateError('Only admins can initialize student entries.');
      }
      final studentData = studentSnapshot.data();
      if (!studentSnapshot.exists ||
          studentData?['role']?.toString().toLowerCase() != 'student' ||
          studentData?['status']?.toString().toLowerCase() != 'approved') {
        throw StateError('Student account is not approved.');
      }
      if (leaderboardSnapshot.exists) return;

      transaction.set(leaderboardRef, {
        'uid': uid,
        'displayName': (studentData?['name'] ?? 'Player').toString(),
        'totalScore': 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });
  }

  static Future<void> addPoints(int points) async {
    if (points != 5 && points != 10) {
      throw ArgumentError.value(
        points,
        'points',
        'Leaderboard awards must be 5 or 10 points.',
      );
    }

    final user = _auth.currentUser;

    if (user == null) {
      throw Exception('No logged-in user.');
    }

    final userRef = _firestore.collection('users').doc(user.uid);

    final leaderboardRef = _collection.doc(user.uid);

    final userSnapshot = await userRef.get();

    if (!userSnapshot.exists) {
      throw Exception('User profile not found.');
    }

    final userData = userSnapshot.data();

    if (userData == null) {
      throw Exception('User profile data is empty.');
    }

    final role = userData['role']?.toString().toLowerCase();

    final status = userData['status']?.toString().toLowerCase();

    if (role != 'student') {
      throw Exception(
        'Only student accounts can have leaderboard scores.',
      );
    }

    if (status != 'approved') {
      throw Exception(
        'Student account is not approved.',
      );
    }

    final displayName = (userData['name'] ?? 'Player').toString();

    await _firestore.runTransaction(
      (transaction) async {
        final leaderboardSnapshot = await transaction.get(leaderboardRef);

        if (!leaderboardSnapshot.exists) {
          transaction.set(
            leaderboardRef,
            {
              'uid': user.uid,
              'displayName': displayName,
              'totalScore': points,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );

          return;
        }

        final existingData = leaderboardSnapshot.data() ?? {};

        final rawScore =
            existingData['totalScore'] ?? existingData['totalscore'] ?? 0;

        int oldScore;

        if (rawScore is int) {
          oldScore = rawScore;
        } else if (rawScore is num) {
          oldScore = rawScore.toInt();
        } else {
          oldScore = int.tryParse(rawScore.toString()) ?? 0;
        }

        transaction.update(
          leaderboardRef,
          {
            'uid': user.uid,
            'displayName': displayName,
            'totalScore': oldScore + points,
            'updatedAt': FieldValue.serverTimestamp(),
          },
        );
      },
    );
  }

  static Future<int?> getRank() async {
    final user = _auth.currentUser;

    if (user == null) {
      return null;
    }

    final document = await _collection.doc(user.uid).get();

    if (!document.exists) {
      return null;
    }

    final entry = _entryFromDocument(document);

    if (entry == null) {
      return null;
    }

    final result = await _collection
        .where(
          'totalScore',
          isGreaterThan: entry.totalScore,
        )
        .count()
        .get();

    return (result.count ?? 0) + 1;
  }

  static Future<int> backfillEntries() async {
    final currentUser = _auth.currentUser;

    if (currentUser == null) {
      throw Exception('No logged-in user.');
    }

    final adminSnapshot =
        await _firestore.collection('users').doc(currentUser.uid).get();

    if (!adminSnapshot.exists) {
      throw Exception('Admin account not found.');
    }

    final adminData = adminSnapshot.data();

    if (adminData == null ||
        adminData['role']?.toString().toLowerCase() != 'admin') {
      throw Exception(
        'Only admins can sync the leaderboard.',
      );
    }

    final usersSnapshot = await _firestore.collection('users').get();

    final leaderboardSnapshot = await _collection.get();

    final existingScores = <String, int>{};

    for (final document in leaderboardSnapshot.docs) {
      final data = document.data();

      final rawScore = data['totalScore'] ?? data['totalscore'] ?? 0;

      int score;

      if (rawScore is int) {
        score = rawScore;
      } else if (rawScore is num) {
        score = rawScore.toInt();
      } else {
        score = int.tryParse(rawScore.toString()) ?? 0;
      }

      existingScores[document.id] = score;
    }

    final students = usersSnapshot.docs.where(
      (document) {
        final data = document.data();

        final role = data['role']?.toString().toLowerCase();

        return role == 'student';
      },
    ).toList();

    var processed = 0;
    for (var start = 0; start < students.length; start += 400) {
      final end = start + 400 < students.length ? start + 400 : students.length;

      final batch = _firestore.batch();

      for (final userDocument in students.sublist(start, end)) {
        final data = userDocument.data();

        final uid = userDocument.id;

        final displayName = (data['name'] ?? 'Player').toString();

        final score = [
          existingScores[uid] ?? 0,
          _progressScore(data),
        ].reduce((left, right) => left > right ? left : right);
        final highestCompletedLevel = _highestCompletedLevel(data);

        final leaderboardRef = _collection.doc(uid);

        batch.set(
          leaderboardRef,
          {
            'uid': uid,
            'displayName': displayName,
            'totalScore': score,
            'highestCompletedLevel': highestCompletedLevel,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }

      await batch.commit();
      processed += end - start;
    }
    return processed;
  }
}
