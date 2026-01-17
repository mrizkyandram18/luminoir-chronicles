import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

/// Dice roll animation with number cycling effect
class DiceAnimation extends StatefulWidget {
  final VoidCallback onRollComplete;
  final int? diceResult;
  final bool isRolling;

  const DiceAnimation({
    super.key,
    required this.onRollComplete,
    this.diceResult,
    this.isRolling = false,
  });

  @override
  State<DiceAnimation> createState() => _DiceAnimationState();
}

class _DiceAnimationState extends State<DiceAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _displayValue = 0; // Default to 0 as requested
  Timer? _rollTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    if (widget.isRolling) {
      _startRolling();
    }
  }

  @override
  void didUpdateWidget(DiceAnimation oldWidget) {
    super.didUpdateWidget(oldWidget);

    // Check if we should start rolling
    if (widget.isRolling && !oldWidget.isRolling) {
      _startRolling();
    }
    // Check if we should stop rolling (either isRolling flag turned off, OR we got a result)
    else if ((!widget.isRolling && oldWidget.isRolling) ||
        (widget.isRolling &&
            widget.diceResult != null &&
            widget.diceResult != oldWidget.diceResult)) {
      _stopRolling();
    }
  }

  void _startRolling() {
    if (_rollTimer?.isActive ?? false) return; // Prevention

    _controller.repeat(reverse: true);
    _rollTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      setState(() {
        _displayValue = Random().nextInt(6) + 1;
      });
    });
  }

  void _stopRolling() {
    _rollTimer?.cancel();
    _controller.stop();

    // Ensure we show the actual result if available, otherwise just stop on last random
    if (widget.diceResult != null) {
      setState(() {
        _displayValue = widget.diceResult!;
      });
      // Trigger completion callback
      Future.delayed(const Duration(seconds: 1), () {
        if (!mounted) return;
        // Display result for 1s
        widget.onRollComplete();
      });
    }
  }

  @override
  void dispose() {
    _rollTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // If not rolling and no value, show nothing
    if (!widget.isRolling && widget.diceResult == null) {
      return const SizedBox.shrink();
    }

    return Center(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.black, width: 4),
              boxShadow: const [
                BoxShadow(
                  color: Colors.black45,
                  blurRadius: 4,
                  offset: Offset(2, 2),
                ),
              ],
            ),
            child: Center(
              child: Text(
                '$_displayValue',
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                  fontFamily: 'monospace', // Or just standard
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

// Removed DiceDotPainter class entirely as it used heavy canvas drawing.
