import 'package:flame/components.dart';
import 'package:flutter/material.dart';

class IsometricTile extends PositionComponent {
  final int index;
  final Vector2 gridPosition;

  IsometricTile({
    required this.index,
    required this.gridPosition,
  });

  @override
  Future<void> onLoad() async {
    position = gridPosition;
    size = Vector2.all(32);
    anchor = Anchor.center;
  }

  @override
  void render(Canvas canvas) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    final path = Path();
    final halfW = size.x / 2;
    final halfH = size.y / 2;

    path.moveTo(0, -halfH);
    path.lineTo(halfW, 0);
    path.lineTo(0, halfH);
    path.lineTo(-halfW, 0);
    path.close();

    canvas.save();
    canvas.translate(size.x / 2, size.y / 2);
    canvas.drawPath(path, paint);
    canvas.restore();
  }
}
