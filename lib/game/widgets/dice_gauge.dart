import 'package:flutter/material.dart';

class DiceGauge extends StatefulWidget {
  final VoidCallback? onHoldStart;
  final Function(double) onRelease;
  final bool enabled;

  const DiceGauge({
    super.key,
    required this.onRelease,
    this.onHoldStart,
    this.enabled = true,
  });

  @override
  State<DiceGauge> createState() => _DiceGaugeState();
}

class _DiceGaugeState extends State<DiceGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  double _currentValue = 0.0;
  bool _isHolding = false;

  @override
  void initState() {
    super.initState();
    _controller =
        AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1), // 1s to fill
          lowerBound: 0.0,
          upperBound: 1.0,
        )..addListener(() {
          setState(() {
            _currentValue = _controller.value;
          });
        });
  }

  void _startHolding() {
    if (!widget.enabled) return;
    setState(() => _isHolding = true);
    widget.onHoldStart?.call();
    _controller.repeat(reverse: true);
  }

  void _stopHolding() {
    if (!_isHolding) return;
    _controller.stop();
    setState(() => _isHolding = false);
    widget.onRelease(_currentValue);
    _controller.reset();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _stopHolding(),
      onTapCancel: _stopHolding,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.black54,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.cyanAccent.withValues(alpha: 0.5)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "HOLD TO ROLL",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            SizedBox(
              width: 100,
              height: 10,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: _currentValue,
                  backgroundColor: Colors.grey[800],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getColorForValue(_currentValue),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getColorForValue(double value) {
    if (value < 0.4) return Colors.greenAccent; // Low
    if (value > 0.6) return Colors.redAccent; // High
    return Colors.yellowAccent; // Mid/Random
  }
}
