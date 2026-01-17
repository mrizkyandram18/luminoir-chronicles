import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_controller.dart';
import '../models/tile_model.dart';
import '../models/player_model.dart'; // Added missing import

import '../widgets/hud_overlay.dart';
import '../widgets/action_panel.dart';
import '../animations/effects_manager.dart';
import '../widgets/isometric/isometric_board.dart';
import '../animations/dice_animation.dart'; // Added import for DiceAnimation
import 'leaderboard_screen.dart';

/// Enhanced Game Board Screen with integrated HUD and Action Panel
class GameBoardScreenEnhanced extends StatefulWidget {
  // Changed to StatefulWidget
  const GameBoardScreenEnhanced({super.key});

  @override
  State<GameBoardScreenEnhanced> createState() =>
      _GameBoardScreenEnhancedState();
}

class _GameBoardScreenEnhancedState extends State<GameBoardScreenEnhanced> {
  // Added State class
  // State
  bool _isRolling = false;

  @override
  Widget build(BuildContext context) {
    // OPTIMIZATION: Use read() here. We DO NOT want the entire Scaffold to rebuild on every tick.
    final controller = context.read<GameController>();

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            colors: [Color(0xFF1a237e), Colors.black],
            center: Alignment.center,
            radius: 1.5,
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              // Main Game Board
              Column(
                children: [
                  // Top Bar - Turn Indicator (Wrapped in Selector)
                  Selector<GameController, Player>(
                    selector: (_, ctrl) => ctrl.currentPlayer,
                    builder: (_, player, _) => _buildTurnIndicator(controller),
                  ),

                  // The Board (Already handles its own Selector internally)
                  Expanded(child: _buildBoard(context, controller)),
                ],
              ),

              // HUD Overlay (Top Right) -> Needs updates on credits/turn
              Positioned(
                top: 60,
                right: 16,
                child: Consumer<GameController>(
                  builder: (_, ctrl, _) => HudOverlay(
                    players: ctrl.players,
                    currentPlayerIndex: ctrl.currentPlayerIndex,
                    isOnline: true,
                  ),
                ),
              ),

              // Leaderboard Button (Below HUD)
              Positioned(
                top: 180,
                right: 16,
                child: FloatingActionButton.small(
                  backgroundColor: Colors.black.withValues(alpha: 0.8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                    side: const BorderSide(color: Colors.cyanAccent),
                  ),
                  onPressed: () => _showLeaderboard(context, controller),
                  child: const Icon(
                    Icons.leaderboard,
                    color: Colors.cyanAccent,
                  ),
                ),
              ),

              // Action Panel (Bottom Center) -> Critical for State
              Positioned(
                bottom: 16,
                left: 0,
                right: 0,
                child: Center(
                  child: SizedBox(
                    width: 400,
                    child: Consumer<GameController>(
                      builder: (_, ctrl, _) {
                        final currentTile =
                            ctrl.tiles[ctrl.currentPlayer.position];
                        return ActionPanel(
                          isMyTurn: ctrl.isMyTurn,
                          isAgentActive: true,
                          canEndTurn: ctrl.canEndTurn,
                          canBuyProperty:
                              currentTile.type == TileType.property &&
                              currentTile.ownerId == null &&
                              ctrl.currentPlayer.credits >= currentTile.value &&
                              !ctrl.actionTakenThisTurn,
                          canUpgradeProperty:
                              currentTile.type == TileType.property &&
                              currentTile.ownerId == ctrl.currentPlayer.id &&
                              ctrl.currentPlayer.credits >=
                                  (currentTile.value * 0.5).round() &&
                              currentTile.upgradeLevel < 4 &&
                              !ctrl.actionTakenThisTurn,
                          canTakeoverProperty:
                              currentTile.type == TileType.property &&
                              currentTile.ownerId != null &&
                              currentTile.ownerId != ctrl.currentPlayer.id &&
                              ctrl.currentPlayer.credits >=
                                  (currentTile.value * 2) &&
                              currentTile.upgradeLevel < 4 &&
                              !ctrl.actionTakenThisTurn,
                          isLoading: _isRolling,
                          onRollDice: (gauge) async {
                            setState(() => _isRolling = true);
                            await ctrl.rollDice(gaugeValue: gauge);
                            if (context.mounted &&
                                ctrl.currentEventCard != null) {
                              _showEventCardDialog(context, ctrl);
                            }
                            if (context.mounted &&
                                ctrl.lastEffectMessage != null) {
                              _showSnackBar(
                                context,
                                ctrl.lastEffectMessage!,
                                ctrl.currentPlayer.color,
                              );
                            }
                            if (mounted) setState(() => _isRolling = false);
                          },
                          onBuyProperty: () async {
                            await ctrl.buyProperty(ctrl.currentPlayer.position);
                            if (context.mounted &&
                                ctrl.lastEffectMessage != null) {
                              _showSnackBar(
                                context,
                                ctrl.lastEffectMessage!,
                                Colors.greenAccent,
                              );
                            }
                          },
                          onUpgradeProperty: () async {
                            await ctrl.buyPropertyUpgrade(
                              ctrl.currentPlayer.position,
                            );
                            if (context.mounted &&
                                ctrl.lastEffectMessage != null) {
                              _showSnackBar(
                                context,
                                ctrl.lastEffectMessage!,
                                Colors.blueAccent,
                              );
                            }
                          },
                          onTakeoverProperty: () async {
                            await ctrl.buyPropertyTakeover(
                              ctrl.currentPlayer.position,
                            );
                            if (context.mounted &&
                                ctrl.lastEffectMessage != null) {
                              _showSnackBar(
                                context,
                                ctrl.lastEffectMessage!,
                                Colors.redAccent,
                              );
                            }
                          },
                          onEndTurn: () => ctrl.endTurn(),
                          onSaveGame: () => ctrl.saveGame(),
                          onLoadGame: () => ctrl.loadGame(),
                          showSaveLoad: ctrl.gameMode == GameMode.practice,
                        );
                      },
                    ),
                  ),
                ),
              ),

              // Floating Effects Layer
              // Uses Selector to only rebuild when message changes
              Selector<GameController, String?>(
                selector: (_, ctrl) => ctrl.lastEffectMessage,
                builder: (_, msg, _) {
                  if (msg == null) return const SizedBox.shrink();
                  // We need the color too, but let's grab it from controller since it's cheap
                  return Positioned(
                    top: 120,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: EffectsManager.floatingScore(
                        context: context,
                        text: msg,
                        color: controller.currentPlayer.color,
                      ),
                    ),
                  );
                },
              ),

              // DICE ANIMATION
              // Local state _isRolling + Controller.diceRoll
              Consumer<GameController>(
                builder: (_, ctrl, _) {
                  if (!_isRolling && ctrl.diceRoll <= 0) {
                    return const SizedBox.shrink();
                  }
                  return Positioned(
                    bottom: 160,
                    left: 0,
                    right: 0,
                    child: IgnorePointer(
                      child: Transform.scale(
                        scale: 0.6,
                        child: DiceAnimation(
                          isRolling: _isRolling,
                          diceResult: ctrl.diceRoll > 0 ? ctrl.diceRoll : null,
                          onRollComplete: () {
                            if (mounted) setState(() => _isRolling = false);
                          },
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTurnIndicator(GameController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.black,
            controller.currentPlayer.color.withValues(alpha: 0.2),
            Colors.black,
          ],
        ),
        border: Border(
          bottom: BorderSide(color: controller.currentPlayer.color, width: 2),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.flight, color: controller.currentPlayer.color, size: 20),
          const SizedBox(width: 8),
          Text(
            "${controller.currentPlayer.name}'s Turn",
            style: GoogleFonts.orbitron(
              color: controller.currentPlayer.color,
              fontSize: 18,
              fontWeight: FontWeight.bold,
              shadows: [
                Shadow(color: controller.currentPlayer.color, blurRadius: 10),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoard(BuildContext context, GameController controller) {
    return Center(
      child: AspectRatio(
        aspectRatio: 1.0,
        child: Container(
          clipBehavior: Clip.none,
          // Use Selector to ONLY rebuild board when ESSENTIAL data changes
          // The MAP itself (nodes) is static, so we don't need to rebuild it for movement.
          // BUT IsometricBoard handles both layers.
          // Ideally: IsometricBoard should be smarter.
          // For now, we pass the controller, but inside IsometricBoard is where we must optimize.
          // OPTIMIZATION:
          // We wrap the board in a RepaintBoundary here as well to catch external rebuilds.
          child: Selector<GameController, int>(
            selector: (_, ctrl) =>
                ctrl.currentPlayerIndex, // Only rebuild on turn change?
            // Actually, movement updates 'position' but not 'currentPlayerIndex' often.
            // We need to rebuild when players move.
            shouldRebuild: (prev, next) =>
                true, // We will handle optimization inside IsometricBoard
            builder: (ctx, _, _) {
              return IsometricBoard(
                graph: controller.boardGraph,
                players: controller.players,
                tileSize: 64.0,
                properties: controller.properties,
              );
            },
          ),
        ),
      ),
    );
  }

  // Helper Methods
  void _showEventCardDialog(BuildContext context, GameController controller) {
    final card = controller.currentEventCard!;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.purpleAccent, width: 2),
        ),
        content: EffectsManager.eventCardPopup(
          context: context,
          title: card.title,
          description: card.description,
          cardColor: Colors.purple.shade900,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "ACKNOWLEDGE",
              style: GoogleFonts.orbitron(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showLeaderboard(BuildContext context, GameController controller) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.8),
      builder: (_) => LeaderboardScreen(
        leaderboardService: controller.leaderboardService,
        currentUserId: controller.currentPlayer.id,
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.robotoMono(color: Colors.black),
        ),
        backgroundColor: color,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
