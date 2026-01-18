import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class HeroComponent extends PositionComponent {
  double _time = 0;
  double _baseY = 0;

  HeroComponent() : super(size: Vector2(50, 50), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _baseY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final dy = 4 * math.sin(_time * 2);
    position.y = _baseY + dy;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.cyanAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 5);

    final fill = Paint()
      ..color = Colors.cyanAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), fill);
    canvas.drawRect(size.toRect(), paint);

    // "Eyes"
    canvas.drawRect(
      Rect.fromLTWH(10, 10, 10, 10),
      Paint()..color = Colors.white,
    );
    canvas.drawRect(
      Rect.fromLTWH(30, 10, 10, 10),
      Paint()..color = Colors.white,
    );
  }
}
