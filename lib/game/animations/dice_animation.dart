import 'package:flutter/material.dart';

/// Dice roll animation controller using Rive
class DiceAnimation extends StatefulWidget {
  final VoidCallback onRollComplete;
  final int? diceResult;

  const DiceAnimation({
    super.key,
    required this.onRollComplete,
    this.diceResult,
  });

  @override
  State<DiceAnimation> createState() => _DiceAnimationState();
}

class _DiceAnimationState extends State<DiceAnimation> {
  void triggerRoll(int result) {
    // Trigger completion callback after animation duration
    Future.delayed(const Duration(milliseconds: 1000), () {
      widget.onRollComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    // Fallback to simple animation if Rive file not available
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent, width: 2),
      ),
      child: Center(
        child: widget.diceResult != null
            ? Text(
                '${widget.diceResult}',
                style: const TextStyle(
                  fontSize: 48,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                ),
              )
            : const Icon(Icons.casino, size: 48, color: Colors.cyanAccent),
      ),
    );
  }
}
