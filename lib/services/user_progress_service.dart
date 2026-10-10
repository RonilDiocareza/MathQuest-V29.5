import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class UserProgress {
  static const int npcQuestionCount = 6;

  final List<int> completedLevels;
  final List<int> completedNpcQuestions;
  final Map<int, List<int>> completedNpcQuestionsByLevel;
  final int unlockedLevels;
  final int questAttempts;
  final Map<int, int> maxUnlockedSubLevel;

  UserProgress({
    required this.completedLevels,
    required this.completedNpcQuestions,
    this.completedNpcQuestionsByLevel = const {},
    required this.unlockedLevels,
    required this.questAttempts,
    required this.maxUnlockedSubLevel,
  });

  int get completedCount => completedLevels.length;

  int get completedNpcQuestionCount {
    var count = 0;
    for (final entry in completedNpcQuestionsByLevel.entries) {
      count += entry.value.length;
    }
    if (!completedNpcQuestionsByLevel.containsKey(1)) {
      count += completedNpcQuestions.toSet().length;
    }
    return count;
  }

  int get completedNpcRoundCount {
    var count = completedNpcQuestionsByLevel.values
        .where((questions) => questions.length >= npcQuestionCount)
        .length;
    if (!completedNpcQuestionsByLevel.containsKey(1) &&
        completedNpcQuestions.toSet().length >= npcQuestionCount) {
      count++;
    }
    return count;
  }

  int get currentNpcQuestionNumber {
    for (var questionNumber = 1;
        questionNumber <= npcQuestionCount;
        questionNumber++) {
      if (!completedNpcQuestions.contains(questionNumber)) {
        return questionNumber;
      }
    }
    return npcQuestionCount;
  }

  bool get areNpcQuestionsCompleted =>
      List.generate(npcQuestionCount, (index) => index + 1)
          .every(completedNpcQuestions.contains);

  List<int> completedNpcQuestionsForLevel(int level) =>
      completedNpcQuestionsByLevel[level] ??
      (level == 1 ? completedNpcQuestions : const []);

  int currentNpcQuestionNumberForLevel(int level) {
    final completed = completedNpcQuestionsForLevel(level);
    for (var questionNumber = 1;
        questionNumber <= npcQuestionCount;
        questionNumber++) {
      if (!completed.contains(questionNumber)) return questionNumber;
    }
    return npcQuestionCount;
  }

  bool areNpcQuestionsCompletedForLevel(int level) {
    final completed = completedNpcQuestionsForLevel(level);
    return List.generate(npcQuestionCount, (index) => index + 1)
        .every(completed.contains);
  }

  int get highestCompletedLevel =>
      completedLevels.isEmpty ? 0 : completedLevels.reduce(max);
}

class UserProgressService {
  static final _users = FirebaseFirestore.instance.collection('users');
  static String? _cachedCurrentUid;
  static Future<UserProgress>? _cachedCurrentProgress;

  static String _uid([String? uid]) {
    final resolved = uid ?? FirebaseAuth.instance.currentUser?.uid;
    if (resolved == null || resolved.isEmpty) {
      throw StateError('Not signed in.');
    }
    return resolved;
  }

  static UserProgress _fromData(Map<String, dynamic>? data) {
    final progress = data?['progress'] as Map<String, dynamic>? ?? {};
    final completed = (progress['completedLevels'] as List<dynamic>? ?? [])
        .map((value) => int.tryParse(value.toString()))
        .whereType<int>()
        .toSet()
        .toList()
      ..sort();
    final completedNpcQuestions =
        (progress['completedNpcQuestions'] as List<dynamic>? ?? [])
            .map((value) => int.tryParse(value.toString()))
            .where((value) => value != null && value >= 1 && value <= 8)
            .cast<int>()
            .toSet()
            .toList()
          ..sort();
    final rawNpcQuestionsByLevel =
        progress['completedNpcQuestionsByLevel'] as Map<String, dynamic>? ?? {};
    final completedNpcQuestionsByLevel = <int, List<int>>{};
    for (final entry in rawNpcQuestionsByLevel.entries) {
      final level = int.tryParse(entry.key);
      final questions = (entry.value as List<dynamic>? ?? [])
          .map((value) => int.tryParse(value.toString()))
          .where((value) =>
              value != null &&
              value >= 1 &&
              value <= UserProgress.npcQuestionCount)
          .cast<int>()
          .toSet()
          .toList()
        ..sort();
      if (level != null && level >= 1 && level <= 60) {
        completedNpcQuestionsByLevel[level] = questions;
      }
    }
    final rawSublevels =
        progress['maxUnlockedSubLevel'] as Map<String, dynamic>? ?? {};
    return UserProgress(
      completedLevels: completed,
      completedNpcQuestions: completedNpcQuestions,
      completedNpcQuestionsByLevel: completedNpcQuestionsByLevel,
      unlockedLevels: (progress['unlockedLevels'] as num?)?.toInt() ?? 1,
      questAttempts: (progress['questAttempts'] as num?)?.toInt() ?? 0,
      maxUnlockedSubLevel: {
        1: (rawSublevels['1'] as num?)?.toInt() ?? 1,
        2: (rawSublevels['2'] as num?)?.toInt() ?? 1,
        3: (rawSublevels['3'] as num?)?.toInt() ?? 1,
      },
    );
  }

  static Future<UserProgress> getProgressForUid(String uid) async {
    final snapshot = await _users.doc(uid).get();
    return _fromData(snapshot.data());
  }

  static Future<UserProgress> getProgressForEmail(String email) async {
    final snapshot =
        await _users.where('email', isEqualTo: email).limit(1).get();
    return snapshot.docs.isEmpty
        ? _fromData(null)
        : _fromData(snapshot.docs.first.data());
  }

  static Future<UserProgress> getCurrentUserProgress() {
    final uid = _uid();
    if (_cachedCurrentUid != uid || _cachedCurrentProgress == null) {
      _cachedCurrentUid = uid;
      _cachedCurrentProgress = getProgressForUid(uid).then<UserProgress>(
        (progress) => progress,
        onError: (Object error, StackTrace stackTrace) {
          if (_cachedCurrentUid == uid) {
            _cachedCurrentUid = null;
            _cachedCurrentProgress = null;
          }
          Error.throwWithStackTrace(error, stackTrace);
        },
      );
    }
    return _cachedCurrentProgress!;
  }

  static Future<void> preloadCurrentUserProgress() async {
    await getCurrentUserProgress();
  }

  static void _invalidateCurrentProgressCache() {
    _cachedCurrentUid = null;
    _cachedCurrentProgress = null;
  }

  static Future<void> saveLevelCompletion(int level, {String? email}) async {
    final userRef = _users.doc(_uid());
    await FirebaseFirestore.instance.runTransaction((transaction) async {
      final snapshot = await transaction.get(userRef);
      final progress = _fromData(snapshot.data());
      final completed = {...progress.completedLevels, level}.toList()..sort();
      final mainLevel = ((level - 1) ~/ 20) + 1;
      final displayNumber = level % 20 == 0 ? 20 : level % 20;
      final nextSubLevel = displayNumber + 1;
      final sublevels = {...progress.maxUnlockedSubLevel};
      if (nextSubLevel <= 20 && nextSubLevel > (sublevels[mainLevel] ?? 1)) {
        sublevels[mainLevel] = nextSubLevel;
      }
      final unlockedLevels = displayNumber == 20 && mainLevel < 3
          ? max(progress.unlockedLevels, mainLevel + 1)
          : progress.unlockedLevels;
      transaction.set(
        userRef,
        {
          'progress': {
            'completedLevels': completed,
            'unlockedLevels': unlockedLevels,
            'questAttempts': progress.questAttempts,
            'maxUnlockedSubLevel': {
              '1': sublevels[1] ?? 1,
              '2': sublevels[2] ?? 1,
              '3': sublevels[3] ?? 1,
            },
          },
        },
        SetOptions(merge: true),
      );
    });
    _invalidateCurrentProgressCache();
  }

  static Future<bool> completeNpcQuestion(
    int questionNumber, {
    String? uid,
    int level = 1,
  }) async {
    if (questionNumber < 1 || questionNumber > UserProgress.npcQuestionCount) {
      throw ArgumentError.value(questionNumber, 'questionNumber');
    }
    if (level < 1 || level > 60) {
      throw ArgumentError.value(level, 'level');
    }

    final userRef = _users.doc(_uid(uid));
    return FirebaseFirestore.instance.runTransaction<bool>((transaction) async {
      final snapshot = await transaction.get(userRef);
      final progress = _fromData(snapshot.data());
      if (progress.areNpcQuestionsCompletedForLevel(level) ||
          progress.currentNpcQuestionNumberForLevel(level) != questionNumber) {
        return false;
      }

      final completed = {
        ...progress.completedNpcQuestionsForLevel(level),
        questionNumber,
      }.toList()
        ..sort();
      final completedByLevel = {
        for (final entry in progress.completedNpcQuestionsByLevel.entries)
          entry.key.toString(): entry.value,
        level.toString(): completed,
      };
      final updatedProgress = <String, dynamic>{
        'completedNpcQuestionsByLevel': completedByLevel,
      };
      if (level == 1) {
        updatedProgress['completedNpcQuestions'] = completed;
      }
      transaction.set(
        userRef,
        {'progress': updatedProgress},
        SetOptions(merge: true),
      );
      return true;
    }).then((completed) {
      if (completed) _invalidateCurrentProgressCache();
      return completed;
    });
  }

  static Future<void> resetNpcQuestionsForLevel(
    int level, {
    String? uid,
  }) async {
    if (level < 1 || level > 60) {
      throw ArgumentError.value(level, 'level');
    }

    final userRef = _users.doc(_uid(uid));
    await FirebaseFirestore.instance.runTransaction<void>((transaction) async {
      final snapshot = await transaction.get(userRef);
      if (!snapshot.exists) return;

      final updates = <String, dynamic>{
        'progress.completedNpcQuestionsByLevel.$level': FieldValue.delete(),
      };
      if (level == 1) {
        updates['progress.completedNpcQuestions'] = <int>[];
      }
      transaction.update(userRef, updates);
    });
    _invalidateCurrentProgressCache();
  }

  static Future<void> incrementQuestAttempts({String? email}) async {
    final userRef = _users.doc(_uid());
    await userRef.set({
      'progress': {'questAttempts': FieldValue.increment(1)},
    }, SetOptions(merge: true));
    _invalidateCurrentProgressCache();
  }
}
