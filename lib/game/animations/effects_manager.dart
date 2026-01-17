import 'package:flutter/material.dart';

/// Centralized manager for Lottie effects and floating notifications
class EffectsManager {
  /// Show floating score/credits notification
  /// Show floating score/credits notification
  static Widget floatingScore({
    required BuildContext context,
    required String text,
    required Color color,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 1500),
      builder: (context, value, child) {
        return Opacity(
          opacity: 1 - value,
          child: Transform.translate(
            offset: Offset(0, -50 * value),
            child: Text(
              text,
              style: TextStyle(
                color: color,
                fontSize: 24 + (8 * value),
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: Colors.black,
                    blurRadius: 0,
                    offset: Offset(2, 2),
                  ), // Solid Shadow
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show property upgrade particle effect
  static Widget propertyUpgradeEffect({required Color propertyColor}) {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: propertyColor,
          width: 4,
        ), // Border instead of shadow
        color: propertyColor.withValues(alpha: 0.2),
      ),
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.0, end: 1.0),
        duration: const Duration(milliseconds: 800),
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (value * 0.5),
            child: Opacity(
              opacity: 1 - value,
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: propertyColor, width: 3),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Show event card popup with slide-in animation
  static Widget eventCardPopup({
    required BuildContext context,
    required String title,
    required String description,
    required Color cardColor,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 100 * (1 - value)),
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: Container(
              padding: const EdgeInsets.all(20),
              margin: const EdgeInsets.symmetric(horizontal: 20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: const [
                  BoxShadow(
                    color: Colors.black45, // Solid shadow
                    blurRadius: 0,
                    offset: Offset(4, 4),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 4,
                    ),
                    color: Colors.black26,
                    child: Text(
                      title,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Show tile glow effect on purchase/upgrade
  static Widget tileGlow({
    required Color glowColor,
    required double intensity,
  }) {
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          color: glowColor,
          width: 2 * intensity,
        ), // Simple border glow
      ),
    );
  }
}
