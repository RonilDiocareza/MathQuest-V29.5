import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/math_background.dart';

class ModuleLessonScreen extends StatelessWidget {
  final Map<String, String> module;

  const ModuleLessonScreen({super.key, required this.module});

  Map<String, String> get _lesson {
    switch (module['id']) {
      case '1':
        return {
          'objective': 'Identify a pattern and write its rule.',
          'explanation': 'A sequence is an ordered list of numbers. Look at how one term changes to the next, then use that same rule to find missing terms.',
          'example': '4, 7, 10, 13, ...',
          'solution': 'Add 3 each time. The next term is 16.',
        };
      case '2':
        return {
          'objective': 'Translate words into algebraic expressions.',
          'explanation': 'A variable represents an unknown quantity. A coefficient multiplies a variable, while a constant has no variable.',
          'example': 'Five more than twice a number',
          'solution': 'Let the number be n. The expression is 2n + 5.',
        };
      case '3':
        return {
          'objective': 'Solve one-variable equations using inverse operations.',
          'explanation': 'Keep an equation balanced by doing the same operation to both sides. Undo addition with subtraction and multiplication with division.',
          'example': '3x + 2 = 14',
          'solution': 'Subtract 2, then divide by 3: x = 4.',
        };
      case '4':
        return {
          'objective': 'Use angle relationships to find unknown measures.',
          'explanation': 'Complementary angles total 90 degrees. Supplementary angles total 180 degrees. Vertical angles have equal measures.',
          'example': 'One angle in a supplementary pair is 65 degrees.',
          'solution': 'The other angle is 180 - 65 = 115 degrees.',
        };
      case '5':
        return {
          'objective': 'Classify polygons and use their angle properties.',
          'explanation': 'A triangle has three sides and its interior angles total 180 degrees. Quadrilaterals have four sides and their interior angles total 360 degrees.',
          'example': 'A triangle has angles 50 degrees and 60 degrees.',
          'solution': 'The third angle is 180 - 50 - 60 = 70 degrees.',
        };
      case '6':
        return {
          'objective': 'Choose and apply the correct measurement formula.',
          'explanation': 'Perimeter measures distance around a figure. Area measures the surface inside a flat figure. Volume measures space inside a solid.',
          'example': 'A rectangle is 8 cm long and 3 cm wide.',
          'solution': 'Area = length x width = 8 x 3 = 24 square centimeters.',
        };
      case '7':
        return {
          'objective': 'Compare and locate numbers in the real number system.',
          'explanation': 'Rational numbers can be written as a fraction. Irrational numbers cannot. All real numbers can be located on a number line.',
          'example': 'Compare -2.5 and -2.',
          'solution': '-2.5 is less because it is farther left on the number line.',
        };
      case '8':
        return {
          'objective': 'Use exponents and roots to represent quantities.',
          'explanation': 'An exponent shows repeated multiplication. A square root asks which number multiplied by itself gives the original number.',
          'example': '2^3 and square root of 49',
          'solution': '2^3 = 8 and the square root of 49 is 7.',
        };
      case '9':
        return {
          'objective': 'Select a graph that clearly represents a data set.',
          'explanation': 'Tables organize values. Bar graphs compare categories, line graphs show change, and circle graphs show parts of a whole.',
          'example': 'Track the temperature every hour for one day.',
          'solution': 'A line graph shows how the temperature changes over time.',
        };
      case '10':
        return {
          'objective': 'Describe data using center and spread.',
          'explanation': 'The mean is the average, the median is the middle value, and the range is the greatest value minus the least value.',
          'example': 'Data: 2, 4, 4, 6, 9',
          'solution': 'Mean = 5, median = 4, and range = 7.',
        };
      default:
        return {
          'objective': 'Find the probability of a simple event.',
          'explanation': 'Probability measures how likely an event is. For equally likely outcomes, divide favorable outcomes by total possible outcomes.',
          'example': 'A bag has 3 red balls and 2 blue balls.',
          'solution': 'The probability of red is 3/5, or 60%.',
        };
    }
  }

  @override
  Widget build(BuildContext context) {
    final lesson = _lesson;

    return Scaffold(
      body: MathBackground(
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        module['name']!,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _LessonPanel(
                          title: 'Learning Objective',
                          child: Text(lesson['objective']!),
                        ),
                        _LessonPanel(
                          title: 'Lesson',
                          child: Text(lesson['explanation']!),
                        ),
                        _LessonPanel(
                          title: 'Worked Example',
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                lesson['example']!,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2B3B5A),
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(lesson['solution']!),
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),
                        CustomButton(
                          text: 'Back to Modules',
                          width: double.infinity,
                          onPressed: () => Navigator.pop(context),
                        ),
                        const SizedBox(height: 12),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: CustomButton(
                    text: 'Back',
                    width: double.infinity,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _LessonPanel extends StatelessWidget {
  final String title;
  final Widget child;

  const _LessonPanel({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF3D5AA),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF2B3B5A),
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          DefaultTextStyle(
            style: const TextStyle(
              color: Color(0xFF5F6670),
              fontSize: 15,
              height: 1.4,
            ),
            child: child,
          ),
        ],
      ),
    );
  }
}