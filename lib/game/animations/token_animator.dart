import 'package:flutter/material.dart';

/// Token movement animator with easing curves
class TokenAnimator {
  final AnimationController controller;
  final Animation<double> animation;
  final VoidCallback onComplete;

  TokenAnimator({
    required TickerProvider vsync,
    required this.onComplete,
    Duration duration = const Duration(milliseconds: 600),
  }) : controller = AnimationController(vsync: vsync, duration: duration),
       animation = CurvedAnimation(
         parent: AnimationController(vsync: vsync, duration: duration),
         curve: Curves.easeOutBack,
       ) {
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        onComplete();
      }
    });
  }

  /// Animate token movement from current position to target position
  /// Moves tile-by-tile with easing curve
  Future<void> animateMovement(
    Alignment start,
    Alignment end, {
    Function(Alignment)? onStep,
  }) async {
    controller.reset();

    final tween = AlignmentTween(begin: start, end: end);
    final tweenAnimation = tween.animate(
      CurvedAnimation(parent: controller, curve: Curves.easeOutBack),
    );

    if (onStep != null) {
      tweenAnimation.addListener(() {
        onStep(tweenAnimation.value);
      });
    }

    await controller.forward();
  }

  /// Animate glow intensity (for level-up effects)
  Animation<double> createGlowAnimation() {
    return Tween<double>(
      begin: 0.5,
      end: 1.5,
    ).animate(CurvedAnimation(parent: controller, curve: Curves.easeInOut));
  }

  void dispose() {
    controller.dispose();
  }
}
