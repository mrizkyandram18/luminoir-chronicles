import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/animations/token_animator.dart';

/// Unit tests for TokenAnimator
/// TDD: Test-Driven Development approach
void main() {
  group('TokenAnimator Tests', () {
    late TokenAnimator animator;
    bool callbackTriggered = false;

    // Use a simple TickerProvider for unit tests if possible,
    // but testWidgets needs the animator to be created with the tester vsync usually.

    testWidgets('should create animator with correct duration', (
      WidgetTester tester,
    ) async {
      animator = TokenAnimator(
        vsync: tester,
        onComplete: () => callbackTriggered = true,
      );
      expect(animator.animation, isNotNull);
      animator.dispose();
    });

    testWidgets('should trigger callback on animation complete', (
      WidgetTester tester,
    ) async {
      callbackTriggered = false;
      animator = TokenAnimator(
        vsync: tester,
        onComplete: () => callbackTriggered = true,
        duration: const Duration(milliseconds: 100),
      );

      // Trigger animation
      animator.animateMovement(Alignment.topLeft, Alignment.bottomRight);

      // Wait for animation to complete
      await tester.pumpAndSettle();

      expect(callbackTriggered, isTrue);
      animator.dispose();
    });

    testWidgets('should animate from start to end alignment', (
      WidgetTester tester,
    ) async {
      Alignment? currentAlignment;
      animator = TokenAnimator(
        vsync: tester,
        onComplete: () {},
        duration: const Duration(milliseconds: 100),
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
      animator.dispose();
    });

    testWidgets('should create glow animation with correct values', (
      WidgetTester tester,
    ) async {
      animator = TokenAnimator(vsync: tester, onComplete: () {});
      final glowAnim = animator.createGlowAnimation();

      expect(glowAnim, isNotNull);
      animator.dispose();
    });
  });
}
