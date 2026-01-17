import 'package:flutter/material.dart';

class DiceChargeWidget extends StatelessWidget {
  final double chargeValue; // 0.0 to 1.0

  const DiceChargeWidget({Key? key, required this.chargeValue})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Cyberpunk Gauge Colors
    final Color barColor =
        Color.lerp(Colors.cyanAccent, Colors.pinkAccent, chargeValue) ??
        Colors.cyanAccent;

    return Container(
      width: 200,
      height: 20,
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.8),
        border: Border.all(color: Colors.white30),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Stack(
        children: [
          // Background Grid
          Positioned.fill(child: CustomPaint(painter: _GridPainter())),

          // Fill
          FractionallySizedBox(
            widthFactor: chargeValue.clamp(0.0, 1.0),
            child: Container(
              decoration: BoxDecoration(
                color: barColor,
                boxShadow: [
                  BoxShadow(
                    color: barColor.withOpacity(0.6),
                    blurRadius: 10,
                    spreadRadius: 1,
                  ),
                ],
              ),
            ),
          ),

          // Text
          Center(
            child: Text(
              "FORCE: ${(chargeValue * 100).toInt()}%",
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white10
      ..strokeWidth = 1;

    for (double x = 0; x < size.width; x += 10) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
