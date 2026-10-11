import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_mathquest/widgets/first_time_tutorial_overlay.dart';

void main() {
  testWidgets('tutorial advances and saves on the final action',
      (WidgetTester tester) async {
    final targetKey = GlobalKey();
    var homeActionTriggered = false;
    var completed = false;
    final steps = [
      const FirstTimeTutorialStep(
        title: 'Welcome',
        message: 'Meet your guide.',
      ),
      FirstTimeTutorialStep(
        title: 'Levels',
        message: 'Choose a level to play.',
        targetKey: targetKey,
      ),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              Center(
                child: ElevatedButton(
                  onPressed: () => homeActionTriggered = true,
                  child: const Text('Home action'),
                ),
              ),
              Align(
                alignment: Alignment.topCenter,
                child: Container(
                  key: targetKey,
                  width: 120,
                  height: 50,
                  color: Colors.blue,
                ),
              ),
              Positioned.fill(
                child: FirstTimeTutorialOverlay(
                  steps: steps,
                  onComplete: () async => completed = true,
                ),
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
    expect(find.image(const AssetImage('assets/images/npcs/npc6.png')),
        findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Levels'), findsOneWidget);
    expect(find.text('2/2'), findsOneWidget);
    expect(tester.takeException(), isNull);

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(completed, isTrue);
    expect(find.text('Welcome'), findsNothing);
    expect(find.text('Home action'), findsOneWidget);
    await tester.tap(find.text('Home action'));
    expect(homeActionTriggered, isTrue);
  });

  testWidgets('tutorial layout fits small and landscape screens',
      (WidgetTester tester) async {
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    tester.view.devicePixelRatio = 1;

    for (final size in [const Size(320, 568), const Size(812, 375)]) {
      tester.view.physicalSize = size;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FirstTimeTutorialOverlay(
              steps: const [
                FirstTimeTutorialStep(
                  title: 'Welcome',
                  message: 'Explore the game with NPC6.',
                ),
              ],
              onComplete: () async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      final nextButton = tester.getRect(find.text('Finish'));
      expect(nextButton.left, greaterThanOrEqualTo(0));
      expect(nextButton.right, lessThanOrEqualTo(size.width));
      expect(nextButton.bottom, lessThanOrEqualTo(size.height));
    }
  });
}
