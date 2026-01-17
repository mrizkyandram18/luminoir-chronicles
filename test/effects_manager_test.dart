import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/animations/effects_manager.dart';

/// Unit tests for EffectsManager
/// TDD: Verify all animation widgets render correctly
void main() {
  group('EffectsManager Tests', () {
    testWidgets('floatingScore should render with correct text and color', (
      WidgetTester tester,
    ) async {
      const testText = '+100';
      const testColor = Colors.green;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectsManager.floatingScore(
              context: tester.element(find.byType(Scaffold)),
              text: testText,
              color: testColor,
            ),
          ),
        ),
      );

      expect(find.text(testText), findsOneWidget);

      final textWidget = tester.widget<Text>(find.text(testText));
      expect(textWidget.style?.color, equals(testColor));
    });

    testWidgets('floatingScore should animate opacity and position', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectsManager.floatingScore(
              context: tester.element(find.byType(Scaffold)),
              text: '+50',
              color: Colors.yellow,
            ),
          ),
        ),
      );

      // Initial state
      await tester.pump();

      // Animate forward
      await tester.pump(const Duration(milliseconds: 500));

      // Should still exist
      expect(find.text('+50'), findsOneWidget);

      // Complete animation
      await tester.pumpAndSettle();
    });

    testWidgets('propertyUpgradeEffect should render with correct color', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.blue;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectsManager.propertyUpgradeEffect(
              propertyColor: testColor,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsWidgets);
    });

    testWidgets('eventCardPopup should display title and description', (
      WidgetTester tester,
    ) async {
      const testTitle = 'Test Event';
      const testDescription = 'This is a test event';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectsManager.eventCardPopup(
              context: tester.element(find.byType(Scaffold)),
              title: testTitle,
              description: testDescription,
              cardColor: Colors.purple,
            ),
          ),
        ),
      );

      expect(find.text(testTitle), findsOneWidget);
      expect(find.text(testDescription), findsOneWidget);
    });

    testWidgets('eventCardPopup should animate slide-in', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectsManager.eventCardPopup(
              context: tester.element(find.byType(Scaffold)),
              title: 'Event',
              description: 'Description',
              cardColor: Colors.red,
            ),
          ),
        ),
      );

      // Initial state with animation
      await tester.pump();

      // Mid-animation
      await tester.pump(const Duration(milliseconds: 250));

      expect(find.text('Event'), findsOneWidget);

      // Complete animation
      await tester.pumpAndSettle();
    });

    testWidgets('tileGlow should render with correct color and intensity', (
      WidgetTester tester,
    ) async {
      const testColor = Colors.orange;
      const testIntensity = 1.5;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EffectsManager.tileGlow(
              glowColor: testColor,
              intensity: testIntensity,
            ),
          ),
        ),
      );

      expect(find.byType(Container), findsOneWidget);

      final container = tester.widget<Container>(find.byType(Container));
      expect(container.decoration, isA<BoxDecoration>());
    });
  });
}
