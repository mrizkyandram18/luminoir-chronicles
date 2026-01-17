import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dice_charge_widget.dart';

/// Action panel with Glassmorphism and Takeover logic
class ActionPanel extends StatelessWidget {
  final bool isAgentActive;
  final bool canRoll;
  final bool canEndTurn;
  final bool canBuyProperty;
  final bool canUpgradeProperty;
  final bool canTakeoverProperty;
  final String? rollDisabledReason;
  final String? buyDisabledReason;
  final String? upgradeDisabledReason;
  final String? takeoverDisabledReason;
  final Function(double) onRollDice;
  final VoidCallback onBuyProperty;
  final VoidCallback onUpgradeProperty;
  final VoidCallback onTakeoverProperty;
  final VoidCallback onEndTurn;
  final VoidCallback onSaveGame;
  final VoidCallback onLoadGame;
  final bool showSaveLoad;
  final bool isLoading;

  const ActionPanel({
    super.key,
    required this.isAgentActive,
    required this.canRoll,
    required this.canEndTurn,
    required this.canBuyProperty,
    required this.canUpgradeProperty,
    this.canTakeoverProperty = false,
    this.rollDisabledReason,
    this.buyDisabledReason,
    this.upgradeDisabledReason,
    this.takeoverDisabledReason,
    required this.onRollDice,
    required this.onBuyProperty,
    required this.onUpgradeProperty,
    required this.onTakeoverProperty,
    required this.onEndTurn,
    required this.onSaveGame,
    required this.onLoadGame,
    this.showSaveLoad = true,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
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
          if (canRoll && isAgentActive && !isLoading)
            Column(
              children: [
                if (!canEndTurn)
                  Transform.scale(
                    scale: 0.85, // Scale down the hold button
                    child: HoldToRollButton(
                      key: const Key('gauge_roll'),
                      onRoll: onRollDice,
                    ),
                  )
                else
                  _buildActionButton(
                    key: const Key('btn_end_turn'),
                    label: 'END TURN',
                    icon: Icons.done_all,
                    enabled: true,
                    onPressed: onEndTurn,
                    color: Colors.cyanAccent,
                    compact: true, // Force compact
                  ),
              ],
            )
          else
            _buildActionButton(
              key: const Key('btn_roll_disabled'),
              label: 'ROLL DICE',
              icon: Icons.casino,
              enabled: false,
              onPressed: () {},
              color: Colors.grey,
              disabledReason: isLoading
                  ? 'Rolling...'
                  : rollDisabledReason ?? 'Unavailable',
              compact: true, // Force compact
            ),
          const SizedBox(height: 6), // Reduce gap
          // CONTEXTUAL ACTIONS
          if (canTakeoverProperty)
            _buildActionButton(
              key: const Key('btn_takeover'),
              label: 'TAKEOVER (2x)',
              icon: Icons.monetization_on,
              enabled: canTakeoverProperty && !isLoading,
              onPressed: onTakeoverProperty,
              color: Colors.redAccent,
              disabledReason: canTakeoverProperty
                  ? null
                  : takeoverDisabledReason,
              compact: true,
            )
          else
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    key: const Key('btn_buy'),
                    label: 'BUY',
                    icon: Icons.store,
                    enabled: canBuyProperty && !isLoading,
                    onPressed: onBuyProperty,
                    color: Colors.greenAccent,
                    disabledReason: canBuyProperty ? null : buyDisabledReason,
                    compact: true,
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: _buildActionButton(
                    key: const Key('btn_upgrade'),
                    label: 'UPGRADE',
                    icon: Icons.upgrade,
                    enabled: canUpgradeProperty && !isLoading,
                    onPressed: onUpgradeProperty,
                    color: Colors.purpleAccent,
                    disabledReason: canUpgradeProperty
                        ? null
                        : upgradeDisabledReason,
                    compact: true,
                  ),
                ),
              ],
            ),

          if (showSaveLoad) ...[
            const Divider(color: Colors.cyanAccent, height: 12),
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
                const SizedBox(width: 6),
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
          textAlign: TextAlign.center,
          style: GoogleFonts.orbitron(
            fontSize: compact ? 10 : 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? color : Colors.grey.shade800,
          foregroundColor: Colors.black,
          padding: EdgeInsets.symmetric(
            vertical: compact ? 10 : 16,
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
    _timer?.cancel();
    setState(() {
      _isHolding = true;
      _charge = 0.0;
    });

    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
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
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _startHolding(),
      onTapUp: (_) => _release(),
      onTapCancel: () => _release(),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
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
