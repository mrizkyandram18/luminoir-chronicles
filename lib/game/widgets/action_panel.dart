import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dice_charge_widget.dart';

/// Action panel with Glassmorphism and Takeover logic
class ActionPanel extends StatelessWidget {
  final bool isMyTurn;
  final bool isAgentActive;
  final bool canBuyProperty;
  final bool canUpgradeProperty;
  final bool canTakeoverProperty;
  final Function(double) onRollDice;
  final VoidCallback onBuyProperty;
  final VoidCallback onUpgradeProperty;
  final VoidCallback onTakeoverProperty;
  final VoidCallback onSaveGame;
  final VoidCallback onLoadGame;
  final bool showSaveLoad;
  final bool isLoading;

  const ActionPanel({
    super.key,
    required this.isMyTurn,
    required this.isAgentActive,
    required this.canBuyProperty,
    required this.canUpgradeProperty,
    this.canTakeoverProperty = false,
    required this.onRollDice,
    required this.onBuyProperty,
    required this.onUpgradeProperty,
    required this.onTakeoverProperty,
    required this.onSaveGame,
    required this.onLoadGame,
    this.showSaveLoad = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.3),
          width: 1,
        ),
        boxShadow: const [
          BoxShadow(color: Colors.black, offset: Offset(0, 4), blurRadius: 0),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // DICE ACTION
          if (isMyTurn && isAgentActive && !isLoading)
            HoldToRollButton(key: const Key('gauge_roll'), onRoll: onRollDice)
          else
            _buildActionButton(
              key: const Key('btn_roll_disabled'),
              label: 'ROLL DICE',
              icon: Icons.casino,
              enabled: false,
              onPressed: () {},
              color: Colors.grey,
              disabledReason: !isAgentActive
                  ? 'Agent Offline'
                  : !isMyTurn
                  ? 'Not Your Turn'
                  : null,
            ),
          const SizedBox(height: 12),

          // CONTEXTUAL ACTIONS
          if (canTakeoverProperty)
            _buildActionButton(
              key: const Key('btn_takeover'),
              label: 'TAKEOVER (2x)',
              icon: Icons.monetization_on,
              enabled: isAgentActive && !isLoading,
              onPressed: onTakeoverProperty,
              color: Colors.redAccent,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    key: const Key('btn_buy'),
                    label: 'BUY',
                    icon: Icons.store,
                    enabled: canBuyProperty && isAgentActive && !isLoading,
                    onPressed: onBuyProperty,
                    color: Colors.greenAccent,
                    disabledReason: !canBuyProperty ? 'No Sale' : null,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    key: const Key('btn_upgrade'),
                    label: 'UPGRADE',
                    icon: Icons.upgrade,
                    enabled: canUpgradeProperty && isAgentActive && !isLoading,
                    onPressed: onUpgradeProperty,
                    color: Colors.purpleAccent,
                    disabledReason: !canUpgradeProperty ? 'No Access' : null,
                    compact: true,
                  ),
                ),
              ],
            ),

          if (showSaveLoad) ...[
            const Divider(color: Colors.cyanAccent, height: 24),
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    key: const Key('btn_save'),
                    label: 'SAVE',
                    icon: Icons.save,
                    enabled: isAgentActive && !isLoading,
                    onPressed: onSaveGame,
                    color: Colors.orangeAccent,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildActionButton(
                    key: const Key('btn_load'),
                    label: 'LOAD',
                    icon: Icons.folder_open,
                    enabled: isAgentActive && !isLoading,
                    onPressed: onLoadGame,
                    color: Colors.orangeAccent,
                    compact: true,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildActionButton({
    Key? key,
    required String label,
    required IconData icon,
    required bool enabled,
    required VoidCallback onPressed,
    required Color color,
    String? disabledReason,
    bool compact = false,
  }) {
    return Tooltip(
      message: disabledReason ?? label,
      child: ElevatedButton.icon(
        key: key,
        onPressed: enabled ? onPressed : null,
        icon: Icon(icon, size: compact ? 16 : 20),
        label: Text(
          label,
          style: GoogleFonts.orbitron(
            fontSize: compact ? 12 : 14,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade800,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 12 : 16,
            horizontal: 16,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: enabled ? 8 : 0,
        ),
      ),
    );
  }
}

class HoldToRollButton extends StatefulWidget {
  final Function(double) onRoll;

  const HoldToRollButton({super.key, required this.onRoll});

  @override
  State<HoldToRollButton> createState() => _HoldToRollButtonState();
}

class _HoldToRollButtonState extends State<HoldToRollButton> {
  Timer? _timer;
  double _charge = 0.0;
  bool _isHolding = false;

  void _startHolding() {
    setState(() {
      _isHolding = true;
      _charge = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        // Charge fills in 2.0 seconds
        _charge += 0.016 / 2.0;
        if (_charge >= 1.0) {
          _charge = 1.0;
          timer.cancel();
        }
      });
    });
  }

  void _release() {
    _timer?.cancel();
    if (_isHolding) {
      widget.onRoll(_charge);
      setState(() {
        _isHolding = false;
        _charge = 0.0;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _release(),
      onTapCancel: () => _release(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: _isHolding ? Colors.grey.shade900 : Colors.cyanAccent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _isHolding ? Colors.cyanAccent : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            if (!_isHolding)
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.5),
                blurRadius: 10,
              ),
          ],
        ),
        child: Column(
          children: [
            if (_isHolding)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                child: DiceChargeWidget(chargeValue: _charge),
              ),

            Center(
              child: Text(
                _isHolding ? "CHARGING..." : "HOLD TO ROLL",
                style: GoogleFonts.orbitron(
                  color: _isHolding ? Colors.cyanAccent : Colors.black,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
