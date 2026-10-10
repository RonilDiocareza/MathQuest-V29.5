import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import '../widgets/math_background.dart';
import 'module_lesson_screen.dart';

class ModulesScreen extends StatefulWidget {
  const ModulesScreen({super.key});

  @override
  State<ModulesScreen> createState() => _ModulesScreenState();
}

class _ModulesScreenState extends State<ModulesScreen> {
  // Click protection flag
  bool _isProcessingClick = false;

  // Module data structure
  final List<Map<String, String>> modules = [
    {
      'id': '1',
      'quarter': 'Quarter 1 · Patterns & Algebra',
      'name': 'Patterns and Sequences',
      'description':
          'Recognize patterns, describe rules, and find missing terms.',
      'icon': '📐',
      'topic': 'Sequences & Relationships',
      'lesson': 'Use tables, diagrams, and rules to describe sequences.',
    },
    {
      'id': '2',
      'quarter': 'Quarter 1 · Patterns & Algebra',
      'name': 'Algebraic Expressions',
      'description':
          'Translate situations into expressions and simplify terms.',
      'icon': '⚖️',
      'topic': 'Variables & Operations',
      'lesson': 'Identify coefficients, constants, terms, and like terms.',
    },
    {
      'id': '3',
      'quarter': 'Quarter 1 · Patterns & Algebra',
      'name': 'Linear Equations and Inequalities',
      'description':
          'Solve and represent one-variable equations and inequalities.',
      'icon': '🧩',
      'topic': 'Solving for an Unknown',
      'lesson': 'Use inverse operations and number lines to check solutions.',
    },
    {
      'id': '4',
      'quarter': 'Quarter 2 · Geometry & Measurement',
      'name': 'Lines and Angles',
      'description': 'Explore angle relationships and properties of lines.',
      'icon': '📏',
      'topic': 'Geometric Relationships',
      'lesson':
          'Classify angles and use complementary, supplementary, and vertical pairs.',
    },
    {
      'id': '5',
      'quarter': 'Quarter 2 · Geometry & Measurement',
      'name': 'Triangles and Quadrilaterals',
      'description': 'Classify polygons and investigate their properties.',
      'icon': '🔺',
      'topic': 'Polygons & Congruence',
      'lesson':
          'Use angle sums and side relationships to solve geometric problems.',
    },
    {
      'id': '6',
      'quarter': 'Quarter 2 · Geometry & Measurement',
      'name': 'Perimeter, Area, and Volume',
      'description': 'Measure two-dimensional figures and solid objects.',
      'icon': '📦',
      'topic': 'Measurement',
      'lesson': 'Choose formulas and solve real-world measurement problems.',
    },
    {
      'id': '7',
      'quarter': 'Quarter 3 · Numbers & Number Sense',
      'name': 'The Real Number System',
      'description':
          'Compare and operate with integers, fractions, and decimals.',
      'icon': '🔢',
      'topic': 'Rational and Irrational Numbers',
      'lesson':
          'Locate numbers on a number line and explain their relationships.',
    },
    {
      'id': '8',
      'quarter': 'Quarter 3 · Numbers & Number Sense',
      'name': 'Exponents, Roots, and Scientific Notation',
      'description':
          'Use powers and roots to describe very large and small numbers.',
      'icon': '√',
      'topic': 'Powers & Radicals',
      'lesson': 'Apply exponent rules and estimate square roots in context.',
    },
    {
      'id': '9',
      'quarter': 'Quarter 4 · Statistics & Probability',
      'name': 'Data Collection and Representation',
      'description':
          'Organize, display, and interpret data from real situations.',
      'icon': '📊',
      'topic': 'Tables, Graphs & Surveys',
      'lesson':
          'Choose an appropriate display and describe what the data shows.',
    },
    {
      'id': '10',
      'quarter': 'Quarter 4 · Statistics & Probability',
      'name': 'Measures of Data',
      'description': 'Summarize data using center and spread.',
      'icon': '📈',
      'topic': 'Mean, Median & Variability',
      'lesson': 'Compare data sets using measures of center and range.',
    },
    {
      'id': '11',
      'quarter': 'Quarter 4 · Statistics & Probability',
      'name': 'Simple Probability',
      'description': 'Describe chance and calculate probabilities of events.',
      'icon': '🎲',
      'topic': 'Chance & Events',
      'lesson':
          'List outcomes and express probability as a fraction, decimal, or percent.',
    },
  ];

  void _selectModule(Map<String, String> module) {
    // Prevent multiple rapid clicks
    if (_isProcessingClick) return;

    _isProcessingClick = true;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ModuleLessonScreen(module: module),
      ),
    ).whenComplete(() {
      if (mounted) {
        _isProcessingClick = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                    const SizedBox(width: 28),
                    const SizedBox(width: 15),
                    const Text(
                      'Modules',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 25),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF9B6B30),
                    borderRadius: BorderRadius.circular(18),
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.55)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Learning Map',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Patterns & Algebra → Geometry & Measurement → Numbers & Number Sense → Statistics & Probability',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.95),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: ListView.builder(
                    itemCount: modules.length,
                    itemBuilder: (context, index) {
                      final module = modules[index];
                      return GestureDetector(
                        onTap: () => _selectModule(module),
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 15),
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF3D5AA),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Text(
                                    module['icon']!,
                                    style: const TextStyle(fontSize: 32),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          module['quarter']!,
                                          style: const TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: Color(0xFF725A41),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          module['name']!,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF2B3B5A),
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          module['description']!,
                                          style: const TextStyle(
                                            fontSize: 13,
                                            color: Color(0xFF6B7280),
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 8),
                                        Text(
                                          'Topic: ${module['topic']!}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Lesson: ${module['lesson']!}',
                                          style: const TextStyle(
                                            fontSize: 11,
                                            color: Color(0xFF6B7280),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const Icon(
                                    Icons.arrow_forward,
                                    color: Color(0xFF2B3B5A),
                                    size: 20,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Back',
                  width: double.infinity,
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(height: 10),
                Center(
                  child: CustomButton(
                    text: 'Back',
                    width: double.infinity,
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
