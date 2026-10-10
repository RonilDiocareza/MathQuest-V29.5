import 'dart:async';

import 'package:flutter/material.dart';
import '../services/user_progress_service.dart';
import '../widgets/custom_button.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/math_background.dart';

class ClassroomQuestScreen extends StatefulWidget {
  const ClassroomQuestScreen({super.key});

  @override
  State<ClassroomQuestScreen> createState() => _ClassroomQuestScreenState();
}

class _ClassroomQuestScreenState extends State<ClassroomQuestScreen> {
  late TextEditingController _answerController;
  Timer? _timer;
  int _remainingSeconds = 60;
  int _attempts = 0;
  bool _isSubmitted = false;
  bool _isTimeUp = false;
  String? _feedbackMessage;
  int _currentLevel = 0;

  static const int _totalTime = 60;
  static const List<Map<String, Object>> _levels = [
    {
      'equation': '2x + 5 = 17',
      'prompt': 'What is the value of x?',
      'answer': 6,
    },
    {
      'equation': '3x - 4 = 11',
      'prompt': 'What is the value of x?',
      'answer': 5,
    },
    {
      'equation': '4x + 8 = 28',
      'prompt': 'What is the value of x?',
      'answer': 5,
    },
  ];

  Map<String, Object> get _currentProblem => _levels[_currentLevel];
  bool get _isLastLevel => _currentLevel == _levels.length - 1;

  @override
  void initState() {
    super.initState();
    _answerController = TextEditingController();
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _answerController.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer?.cancel();
    setState(() {
      _remainingSeconds = _totalTime;
      _attempts = 0;
      _isSubmitted = false;
      _isTimeUp = false;
      _feedbackMessage = null;
      _answerController.clear();
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 1) {
        timer.cancel();
        if (mounted) {
          setState(() {
            _remainingSeconds = 0;
            _isTimeUp = true;
            _feedbackMessage = 'Time is up! Attempts: $_attempts';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Time is up! You made $_attempts attempt(s).'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }
      if (mounted) {
        setState(() {
          _remainingSeconds -= 1;
        });
      }
    });
  }

  void _submitAnswer() {
    if (_isTimeUp || _isSubmitted) {
      return;
    }

    if (_answerController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter an answer first!'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final userAnswer = int.tryParse(_answerController.text.trim());
    if (userAnswer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _attempts += 1;
    });

    // Save attempt to SharedPreferences
    _saveAttempt();

    final correctAnswer = _currentProblem['answer'] as int;
    if (userAnswer == correctAnswer) {
      _timer?.cancel();
      if (_isLastLevel) {
        setState(() {
          _isSubmitted = true;
          _feedbackMessage =
              'Great job! You completed all levels in $_attempts attempt(s).';
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('All levels complete! Attempts: $_attempts'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _currentLevel += 1;
          _feedbackMessage = 'Correct! Starting level ${_currentLevel + 1}.';
          _answerController.clear();
          _isSubmitted = false;
          _isTimeUp = false;
          _remainingSeconds = _totalTime;
          _attempts = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Correct! Level ${_currentLevel + 1} ready.'),
            backgroundColor: Colors.green,
          ),
        );

        _startTimer();
      }
    } else {
      setState(() {
        _feedbackMessage = 'Wrong answer. Attempts: $_attempts';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Wrong answer. Attempts: $_attempts'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _saveAttempt() async {
    await UserProgressService.incrementQuestAttempts();
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final remaining = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$remaining';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Stack(
            children: [
              Positioned.fill(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),

                      // HEADER
                      Row(
                        children: [
                          const SizedBox(width: 48),
                          const Expanded(
                            child: Text(
                              'Classroom Quest',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // 🔥 ORANGE CARD (NUMBER WIDTH CONTROL HERE)
                      Center(
                        child: Container(
                          width: double.infinity,
                          constraints: const BoxConstraints(maxWidth: 350),
                          padding: const EdgeInsets.all(25),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1D0AD),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.2),
                                blurRadius: 10,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              const Text(
                                'Math Problem',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              const SizedBox(height: 20),
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                ),
                                child: Column(
                                  children: [
                                    Text(
                                      'Level ${_currentLevel + 1} of ${_levels.length}',
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.black87,
                                      ),
                                    ),
                                    const SizedBox(height: 12),
                                    const Text(
                                      'Solve this equation:',
                                      style: TextStyle(fontSize: 18),
                                    ),
                                    const SizedBox(height: 15),
                                    Text(
                                      _currentProblem['equation'] as String,
                                      style: const TextStyle(
                                        fontSize: 32,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Text(_currentProblem['prompt'] as String),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 30),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Time Remaining',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _formatTime(_remainingSeconds),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              const Text(
                                'Attempts',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                '$_attempts',
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      if (_feedbackMessage != null) ...[
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: Text(
                            _feedbackMessage!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 30),

                      const Text(
                        'Your Answer',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),

                      const SizedBox(height: 10),

                      Center(
                        child: CustomTextField(
                          hint: 'Enter answer...',
                          controller: _answerController,
                          keyboardType: TextInputType.number,
                          height: 60,
                          width: 200,
                          enabled: !_isTimeUp && !_isSubmitted,
                        ),
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: SizedBox(
                          width: 200,
                          child: CustomButton(
                            text: _isSubmitted
                                ? '✅ Submitted!'
                                : _isTimeUp
                                    ? "Time's Up"
                                    : 'Submit Answer',
                            onPressed: (_isSubmitted || _isTimeUp)
                                ? null
                                : _submitAnswer,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      Center(
                        child: SizedBox(
                          width: 200,
                          child: CustomButton(
                            text: 'Back',
                            onPressed: () => Navigator.pop(context),
                          ),
                        ),
                      ),

                      if (_isTimeUp || _isSubmitted) ...[
                        const SizedBox(height: 20),
                        Center(
                          child: SizedBox(
                            width: 200,
                            child: CustomButton(
                              text: 'Try Again',
                              onPressed: _startTimer,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
