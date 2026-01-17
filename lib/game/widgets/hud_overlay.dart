import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/player_model.dart';

/// Real-time HUD showing all player stats
class HudOverlay extends StatelessWidget {
  final List<Player> players;
  final int currentPlayerIndex;
  final bool isOnline;

  const HudOverlay({
    super.key,
    required this.players,
    required this.currentPlayerIndex,
    this.isOnline = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.cyanAccent.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Connection Status
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isOnline ? Icons.cloud_done : Icons.cloud_off,
                color: isOnline ? Colors.greenAccent : Colors.redAccent,
                size: 16,
              ),
              const SizedBox(width: 8),
              Text(
                isOnline ? 'ONLINE' : 'OFFLINE',
                style: GoogleFonts.orbitron(
                  fontSize: 12,
                  color: isOnline ? Colors.greenAccent : Colors.redAccent,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Divider(color: Colors.cyanAccent, height: 16),
          // Player Stats
          ...players.asMap().entries.map((entry) {
            final index = entry.key;
            final player = entry.value;
            final isActive = index == currentPlayerIndex;

            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isActive
                    ? player.color.withValues(alpha: 0.3)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive ? player.color : Colors.transparent,
                  width: 2,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: player.color.withValues(alpha: 0.5),
                          blurRadius: 10,
                        ),
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Player Color Indicator
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: player.color,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: player.color.withValues(alpha: 0.6),
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Player Name
                  SizedBox(
                    width: 80,
                    child: Text(
                      player.name,
                      style: GoogleFonts.orbitron(
                        fontSize: 12,
                        color: Colors.white,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Score
                  _buildStat('⭐', player.score.toString(), Colors.yellowAccent),
                  const SizedBox(width: 8),
                  // Credits
                  _buildStat(
                    '💰',
                    player.credits.toString(),
                    Colors.greenAccent,
                  ),
                  const SizedBox(width: 8),
                  // Multiplier
                  if (player.scoreMultiplier > 1)
                    _buildStat(
                      '×',
                      player.scoreMultiplier.toString(),
                      Colors.purpleAccent,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStat(String icon, String value, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(icon, style: const TextStyle(fontSize: 10)),
        const SizedBox(width: 2),
        Text(
          value,
          style: GoogleFonts.robotoMono(
            fontSize: 10,
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
