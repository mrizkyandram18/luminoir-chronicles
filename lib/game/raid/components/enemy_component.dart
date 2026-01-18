import 'dart:math' as math;
import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class EnemyComponent extends PositionComponent {
  double _time = 0;
  double _baseY = 0;

  EnemyComponent() : super(size: Vector2(60, 60), anchor: Anchor.center);

  @override
  Future<void> onLoad() async {
    _baseY = position.y;
  }

  @override
  void update(double dt) {
    super.update(dt);
    _time += dt;
    final dy = 4 * math.cos(_time * 2);
    position.y = _baseY + dy;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.redAccent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2
      ..maskFilter = const MaskFilter.blur(BlurStyle.outer, 8);

    final fill = Paint()
      ..color = Colors.redAccent.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;

    canvas.drawRect(size.toRect(), fill);
    canvas.drawRect(size.toRect(), paint);

    // Angry "Eyes"
    final eyePaint = Paint()..color = Colors.yellow;
    canvas.drawRect(Rect.fromLTWH(10, 15, 15, 5), eyePaint);
    canvas.drawRect(Rect.fromLTWH(35, 15, 15, 5), eyePaint);
  }
}
