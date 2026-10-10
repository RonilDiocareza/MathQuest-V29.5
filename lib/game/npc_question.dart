import 'package:flame/components.dart';
import 'dart:math';

class QuestionNpcPlacement {
  static const double physicalCollisionRadius = 8;

  final int level;
  final int questionNumber;
  final String questionId;
  final String topic;
  final Vector2 position;
  final String spriteAssetPath;
  final double collisionRadius;
  final int questionSeed;

  const QuestionNpcPlacement({
    this.level = 1,
    this.questionNumber = 1,
    required this.questionId,
    required this.topic,
    required this.position,
    this.spriteAssetPath = 'assets/images/npcs/np1.png',
    this.collisionRadius = physicalCollisionRadius,
    this.questionSeed = 0,
  });
}

class NpcQuestion {
  final String id;
  final int questionNumber;
  final String topic;
  final String prompt;
  final List<String> choices;
  final int correctAnswerIndex;

  const NpcQuestion({
    required this.id,
    this.questionNumber = 1,
    required this.topic,
    required this.prompt,
    required this.choices,
    required this.correctAnswerIndex,
  });

  NpcQuestion withTopic(String topic) => NpcQuestion(
        id: id,
        questionNumber: questionNumber,
        topic: topic,
        prompt: prompt,
        choices: choices,
        correctAnswerIndex: correctAnswerIndex,
      );

  static const List<NpcQuestion> all = [
    NpcQuestion(
      id: 'npc_question_1',
      questionNumber: 1,
      topic: 'Variables & Operations',
      prompt: 'In 3x + 5, what is the coefficient of x?',
      choices: ['3', '5', '8'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_2',
      questionNumber: 2,
      topic: 'Solving for an Unknown',
      prompt: 'Solve for x: x + 7 = 12.',
      choices: ['5', '19', '84'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_3',
      questionNumber: 3,
      topic: 'Geometric Relationships',
      prompt: 'A linear pair has one angle of 65°. What is the other angle?',
      choices: ['115°', '25°', '65°'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_4',
      questionNumber: 4,
      topic: 'Polygons & Congruence',
      prompt: 'What is the sum of the interior angles in a triangle?',
      choices: ['180°', '90°', '360°'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_5',
      questionNumber: 5,
      topic: 'Equations',
      prompt: 'Solve for x: 4x = 20.',
      choices: ['5', '16', '80'],
      correctAnswerIndex: 0,
    ),
    NpcQuestion(
      id: 'npc_question_6',
      questionNumber: 6,
      topic: 'Perimeter',
      prompt: 'What is the perimeter of a square with side length 4?',
      choices: ['16', '8', '12'],
      correctAnswerIndex: 0,
    ),
  ];

  // Tiled-world coordinates for the four building entrances, central shrine,
  // and final NPC on the southern road near the map edge.
  static const List<(double, double)> _mapNpcPositions = [
    (535, 285),
    (1062, 340),
    (397, 553),
    (651, 584),
    (1120, 550),
    (468, 1016),
  ];

  static const List<String> _npcSpritePaths = [
    'assets/images/npcs/np1.png',
    'assets/images/npcs/npc2.png',
    'assets/images/npcs/npc3.png',
    'assets/images/npcs/npc4.png',
    'assets/images/npcs/npc5.png',
    'assets/images/npcs/npc6.png',
  ];

  static List<QuestionNpcPlacement> createNpcPlacements({
    required Vector2 playerSpawn,
    required bool Function(Vector2 center, double radius) canOccupy,
    int level = 1,
    Random? random,
  }) {
    final placements = <QuestionNpcPlacement>[];

    bool isClear(Vector2 feetPosition) {
      final radius = QuestionNpcPlacement.physicalCollisionRadius;
      final center = Vector2(feetPosition.x, feetPosition.y - radius);
      if (!canOccupy(center, radius)) return false;

      final playerFeet = Vector2(playerSpawn.x, playerSpawn.y + 21);
      if (center.distanceTo(playerFeet) < radius * 2 + 4) return false;

      return placements.every((placement) {
        final otherCenter = Vector2(
          placement.position.x,
          placement.position.y - placement.collisionRadius,
        );
        return center.distanceTo(otherCenter) >=
            radius + placement.collisionRadius + 4;
      });
    }

    for (var index = 0; index < _mapNpcPositions.length; index++) {
      final (x, y) = _mapNpcPositions[index];
      final position = Vector2(x, y);
      if (!isClear(position)) {
        throw StateError(
          'Question NPC ${index + 1} cannot be placed safely at its building door.',
        );
      }
      final questionSeed = random?.nextInt(1 << 31) ?? 0;
      placements.add(_placementAt(index, position, level, questionSeed));
    }

    if (placements.length != all.length) {
      throw StateError(
        'Only ${placements.length} of ${all.length} NPCs have a safe map location.',
      );
    }

    return placements;
  }

  static QuestionNpcPlacement _placementAt(
    int index,
    Vector2 position,
    int level,
    int questionSeed,
  ) {
    final question = forLevel(index + 1, level, questionSeed: questionSeed);
    return QuestionNpcPlacement(
      level: level,
      questionNumber: question.questionNumber,
      questionId: question.id,
      topic: question.topic,
      position: position,
      spriteAssetPath: _npcSpritePaths[index],
      questionSeed: questionSeed,
    );
  }

  static NpcQuestion? forPlacement(QuestionNpcPlacement placement) {
    final original = all.firstWhere(
      (question) =>
          question.id == placement.questionId &&
          question.questionNumber == placement.questionNumber,
      orElse: () => all.first,
    );
    if (original.id != placement.questionId ||
        original.questionNumber != placement.questionNumber) {
      return null;
    }
    return forLevel(
      placement.questionNumber,
      placement.level,
      questionSeed: placement.questionSeed,
    ).withTopic(placement.topic);
  }

  static NpcQuestion forLevel(
    int questionNumber,
    int level, {
    int? questionSeed,
  }) {
    if (questionNumber < 1 || questionNumber > all.length) {
      throw ArgumentError.value(questionNumber, 'questionNumber');
    }
    if (level < 1 || level > 60) {
      throw ArgumentError.value(level, 'level');
    }
    if (level == 1 && questionSeed == null) return all[questionNumber - 1];

    final base = all[questionNumber - 1];
    final n = level + ((questionSeed ?? 0) % 5);
    final choiceSeed = questionSeed ?? level * 101 + base.questionNumber;
    switch (questionNumber) {
      case 1:
        final coefficient = n + 2;
        return _multipleChoice(
          base: base,
          level: level,
          choiceSeed: choiceSeed,
          prompt:
              'In ${coefficient}x + ${n + 3}, what is the coefficient of x?',
          answer: coefficient.toString(),
          distractors: [
            (n + 3).toString(),
            (coefficient + n + 3).toString(),
          ],
        );
      case 2:
        final coefficient = n + 1;
        final constant = n + 2;
        final answer = coefficient * 2 + constant;
        return _multipleChoice(
          base: base,
          level: level,
          choiceSeed: choiceSeed,
          prompt: 'Evaluate ${coefficient}x + $constant when x = 2.',
          answer: answer.toString(),
          distractors: [
            (coefficient + constant).toString(),
            (coefficient * 2 - constant).toString(),
          ],
        );
      case 3:
        final firstCoefficient = n + 2;
        final secondCoefficient = n + 4;
        final constant = n + 1;
        final answer = '${firstCoefficient + secondCoefficient}x - $constant';
        return _multipleChoice(
          base: base,
          level: level,
          choiceSeed: choiceSeed,
          prompt:
              'Simplify ${firstCoefficient}x + ${secondCoefficient}x - $constant.',
          answer: answer,
          distractors: [
            '${firstCoefficient + secondCoefficient + 1}x - $constant',
            '${firstCoefficient + secondCoefficient}x + $constant',
          ],
        );
      case 4:
        final coefficient = n % 5 + 2;
        final constant = n + 3;
        final solution = n + 1;
        final rightSide = coefficient * solution + constant;
        return _multipleChoice(
          base: base,
          level: level,
          choiceSeed: choiceSeed,
          prompt: 'Solve for x: ${coefficient}x + $constant = $rightSide.',
          answer: solution.toString(),
          distractors: [
            (solution + 1).toString(),
            (solution - 1).toString(),
          ],
        );
      case 5:
        final outsideCoefficient = n + 4;
        final insideConstant = n + 1;
        final subtractedCoefficient = n + 2;
        final coefficient = outsideCoefficient - subtractedCoefficient;
        final constant = outsideCoefficient * insideConstant;
        return _multipleChoice(
          base: base,
          level: level,
          choiceSeed: choiceSeed,
          prompt: 'Simplify $outsideCoefficient(x + $insideConstant) '
              '- $subtractedCoefficient x.',
          answer: '$coefficient x + $constant',
          distractors: [
            '${outsideCoefficient + subtractedCoefficient}x + $constant',
            '$coefficient x - $constant',
          ],
        );
      case 6:
        final coefficient = n % 7 + 2;
        final subtractedValue = n + 1;
        final solution = n + 3;
        final rightSide = coefficient * (solution - subtractedValue);
        return _multipleChoice(
          base: base,
          level: level,
          choiceSeed: choiceSeed,
          prompt: 'Solve for x: $coefficient(x - $subtractedValue) '
              '= $rightSide.',
          answer: solution.toString(),
          distractors: [
            (solution + 1).toString(),
            (solution - 1).toString(),
          ],
        );
    }
    throw StateError('No NPC question template for question $questionNumber.');
  }

  static NpcQuestion _multipleChoice({
    required NpcQuestion base,
    required int level,
    required int choiceSeed,
    required String prompt,
    required String answer,
    required List<String> distractors,
  }) {
    final choices = <String>{answer, ...distractors}.toList()
      ..shuffle(Random(choiceSeed));
    return NpcQuestion(
      id: base.id,
      questionNumber: base.questionNumber,
      topic: 'Algebraic Expressions',
      prompt: prompt,
      choices: choices,
      correctAnswerIndex: choices.indexOf(answer),
    );
  }
}
