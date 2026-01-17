import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Action panel with gatekeeper-aware buttons
class ActionPanel extends StatelessWidget {
  final bool isMyTurn;
  final bool isAgentActive;
  final bool canBuyProperty;
  final bool canUpgradeProperty;
  final VoidCallback onRollDice;
  final VoidCallback onBuyProperty;
  final VoidCallback onUpgradeProperty;
  final VoidCallback onSaveGame;
  final VoidCallback onLoadGame;
  final bool isLoading;

  const ActionPanel({
    super.key,
    required this.isMyTurn,
    required this.isAgentActive,
    required this.canBuyProperty,
    required this.canUpgradeProperty,
    required this.onRollDice,
    required this.onBuyProperty,
    required this.onUpgradeProperty,
    required this.onSaveGame,
    required this.onLoadGame,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.cyanAccent.withOpacity(0.3), width: 1),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionButton(
            label: 'ROLL DICE',
            icon: Icons.casino,
            enabled: isMyTurn && isAgentActive && !isLoading,
            onPressed: onRollDice,
            color: Colors.cyanAccent,
            disabledReason: !isAgentActive
                ? 'Agent Offline'
                : !isMyTurn
                ? 'Not Your Turn'
                : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'BUY PROPERTY',
            icon: Icons.store,
            enabled: canBuyProperty && isAgentActive && !isLoading,
            onPressed: onBuyProperty,
            color: Colors.greenAccent,
            disabledReason: !isAgentActive
                ? 'Agent Offline'
                : !canBuyProperty
                ? 'Not Available'
                : null,
          ),
          const SizedBox(height: 12),
          _buildActionButton(
            label: 'UPGRADE',
            icon: Icons.upgrade,
            enabled: canUpgradeProperty && isAgentActive && !isLoading,
            onPressed: onUpgradeProperty,
            color: Colors.purpleAccent,
            disabledReason: !isAgentActive
                ? 'Agent Offline'
                : !canUpgradeProperty
                ? 'Not Your Property'
                : null,
          ),
          const Divider(color: Colors.cyanAccent, height: 24),
          Row(
            children: [
              Expanded(
                child: _buildActionButton(
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
      ),
    );
  }

  Widget _buildActionButton({
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
