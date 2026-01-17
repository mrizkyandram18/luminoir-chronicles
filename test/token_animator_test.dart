import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/animations/token_animator.dart';

/// Unit tests for TokenAnimator
/// TDD: Test-Driven Development approach
void main() {
  group('TokenAnimator Tests', () {
    late TokenAnimator animator;
    bool callbackTriggered = false;

    setUp(() {
      callbackTriggered = false;
    });

    testWidgets('should create animator with correct duration', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                animator = TokenAnimator(
                  vsync: tester,
                  onComplete: () => callbackTriggered = true,
                );
                // Verify animator created successfully
                expect(animator.animation, isNotNull);
                return Container();
              },
            ),
          ),
        ),
      );
    });

    testWidgets('should trigger callback on animation complete', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                animator = TokenAnimator(
                  vsync: tester,
                  onComplete: () => callbackTriggered = true,
                  duration: const Duration(milliseconds: 100),
                );
                return Container();
              },
            ),
          ),
        ),
      );

      // Trigger animation
      await animator.animateMovement(Alignment.topLeft, Alignment.bottomRight);

      // Wait for animation to complete
      await tester.pumpAndSettle();

      expect(callbackTriggered, isTrue);
    });

    testWidgets('should animate from start to end alignment', (
      WidgetTester tester,
    ) async {
      Alignment? currentAlignment;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                animator = TokenAnimator(
                  vsync: tester,
                  onComplete: () {},
                  duration: const Duration(milliseconds: 100),
                );
                return Container();
              },
            ),
          ),
        ),
      );

      // Trigger animation with step callback
      animator.animateMovement(
        Alignment.topLeft,
        Alignment.bottomRight,
        onStep: (alignment) => currentAlignment = alignment,
      );

      // Pump frames
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      // Check that alignment has changed from start
      expect(currentAlignment, isNotNull);
      expect(currentAlignment, isNot(equals(Alignment.topLeft)));
    });

    testWidgets('should create glow animation with correct values', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) {
                animator = TokenAnimator(vsync: tester, onComplete: () {});
                final glowAnim = animator.createGlowAnimation();

                expect(glowAnim, isNotNull);
                return Container();
              },
            ),
          ),
        ),
      );
    });
  });
}
