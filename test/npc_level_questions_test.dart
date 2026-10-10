import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/game/npc_question.dart';
import 'package:flutter_mathquest/services/user_progress_service.dart';

void main() {
  test('every NPC gets a distinct algebra question at each level', () {
    for (var questionNumber = 1;
        questionNumber <= NpcQuestion.all.length;
        questionNumber++) {
      final prompts = <String>{};
      for (var level = 2; level <= 60; level++) {
        final question = NpcQuestion.forLevel(questionNumber, level);
        expect(question.topic, 'Algebraic Expressions');
        expect(prompts.add(question.prompt), isTrue);
        expect(question.choices, hasLength(3));
        expect(
          question.correctAnswerIndex,
          inInclusiveRange(0, question.choices.length - 1),
        );
        expect(question.choices.toSet(), hasLength(3));
      }
    }
  });

  test('Game Mode algebra questions vary by session and keep valid answers',
      () {
    for (var questionNumber = 1;
        questionNumber <= NpcQuestion.all.length;
        questionNumber++) {
      final first = NpcQuestion.forLevel(
        questionNumber,
        1,
        questionSeed: 0,
      );
      final second = NpcQuestion.forLevel(
        questionNumber,
        1,
        questionSeed: 1,
      );

      expect(second.prompt, isNot(first.prompt));
      expect(first.choices[first.correctAnswerIndex], isNotEmpty);
      expect(second.choices[second.correctAnswerIndex], isNotEmpty);
      expect(first.choices.toSet(), hasLength(3));
      expect(second.choices.toSet(), hasLength(3));
    }
  });

  test('NPC completion is isolated to its Game Mode level', () {
    final progress = UserProgress(
      completedLevels: const [],
      completedNpcQuestions: const [1, 2, 3, 4, 5, 6],
      completedNpcQuestionsByLevel: const {
        2: [1, 2],
        3: [1, 2, 3, 4, 5, 6],
      },
      unlockedLevels: 1,
      questAttempts: 0,
      maxUnlockedSubLevel: const {1: 1, 2: 1, 3: 1},
    );

    expect(progress.areNpcQuestionsCompletedForLevel(1), isTrue);
    expect(progress.currentNpcQuestionNumberForLevel(2), 3);
    expect(progress.areNpcQuestionsCompletedForLevel(3), isTrue);
    expect(progress.currentNpcQuestionNumberForLevel(4), 1);
    expect(progress.areNpcQuestionsCompletedForLevel(4), isFalse);
  });

  test('badge progress counts completed NPC answers and rounds', () {
    final progress = UserProgress(
      completedLevels: const [1, 2],
      completedNpcQuestions: const [1, 2, 3, 4, 5, 6],
      completedNpcQuestionsByLevel: const {
        2: [1, 2, 3],
        3: [1, 2, 3, 4, 5, 6],
      },
      unlockedLevels: 2,
      questAttempts: 4,
      maxUnlockedSubLevel: const {1: 1, 2: 1, 3: 1},
    );

    expect(progress.completedNpcQuestionCount, 15);
    expect(progress.completedNpcRoundCount, 2);
  });

  test('badge progress avoids double-counting legacy NPC level one data', () {
    final progress = UserProgress(
      completedLevels: const [],
      completedNpcQuestions: const [1, 2, 3, 4, 5, 6],
      completedNpcQuestionsByLevel: const {
        1: [1, 2, 3, 4, 5, 6],
      },
      unlockedLevels: 1,
      questAttempts: 0,
      maxUnlockedSubLevel: const {1: 1, 2: 1, 3: 1},
    );

    expect(progress.completedNpcQuestionCount, 6);
    expect(progress.completedNpcRoundCount, 1);
  });
}
