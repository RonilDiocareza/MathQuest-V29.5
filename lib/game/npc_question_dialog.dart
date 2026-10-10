import 'package:flutter/material.dart';

import 'npc_question.dart';

class NpcQuestionDialog extends StatelessWidget {
  final NpcQuestion question;

  const NpcQuestionDialog({super.key, required this.question});

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 560,
          maxHeight: screenHeight * 0.88,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Question ${question.questionNumber}',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF52698F),
                    ),
              ),
              const SizedBox(height: 6),
              Text(
                question.topic,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF2B3B5A),
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                question.prompt,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 16),
              for (var index = 0; index < question.choices.length; index++)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(
                      index == question.correctAnswerIndex,
                    ),
                    child: Text(
                      question.choices[index],
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Not now'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
