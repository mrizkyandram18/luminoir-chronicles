import 'package:flutter/material.dart';

class PixelButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color color;

  const PixelButton({
    super.key,
    required this.label,
    this.onPressed,
    this.color = Colors.cyanAccent,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 200,
      height: 60,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.black,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(0), // Pixel style usually sharp
          ),
        ),
        child: Text(
          label.toUpperCase(),
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
    );
  }
}
