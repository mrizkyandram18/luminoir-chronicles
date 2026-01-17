import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_controller.dart';
import '../models/player_model.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/action_panel.dart';
import '../animations/effects_manager.dart';
import '../widgets/isometric/isometric_board.dart';
import '../animations/dice_animation.dart';
import '../../gatekeeper/gatekeeper_service.dart';
import 'leaderboard_screen.dart';

class GameBoardScreenEnhanced extends StatefulWidget {
  const GameBoardScreenEnhanced({super.key});

  @override
  State<GameBoardScreenEnhanced> createState() =>
      _GameBoardScreenEnhancedState();
}

class _GameBoardScreenEnhancedState extends State<GameBoardScreenEnhanced>
    with WidgetsBindingObserver {
  bool _isRolling = false;
  bool _isAppActive = true;
  bool _isBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!mounted) {
      return;
    }
    final controller = context.read<GameController>();
    if (state == AppLifecycleState.resumed) {
      final gatekeeper = context.read<GatekeeperService>();
      if (!gatekeeper.isGatekeeperConnected) {
        if (controller.gameMode == GameMode.practice) {
          // Practice Mode: Do nothing here, the build method will show overlay
        } else {
          // Ranked/Online: Strict Exit
          context.go('/access-denied', extra: 'OFFLINE');
        }
        return;
      }
      _isBackgrounded = false;
      setState(() {
        _isAppActive = true;
      });
      return;
    }
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      if (_isBackgrounded) {
        return;
      }
      _isBackgrounded = true;
      setState(() {
        _isAppActive = false;
        _isRolling = false;
      });
      if (controller.gameMode.canPersist) {
        controller.autosave();
      }
      return;
    }
    if (state == AppLifecycleState.detached) {
      _isBackgrounded = true;
      if (controller.gameMode.canPersist) {
        controller.autosave();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final gatekeeper = context.watch<GatekeeperService>();
    final controller = context.read<GameController>();

    // Strict Mode Check Trigger
    if (!gatekeeper.isGatekeeperConnected &&
        controller.gameMode != GameMode.practice) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        context.go('/access-denied', extra: 'OFFLINE');
      });
    }
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, dynamic result) async {
        if (didPop) return;

        final navigator = Navigator.of(context);

        // Ranked/Online: Exit App completely
        if (controller.gameMode != GameMode.practice) {
          final shouldExit = await showDialog<bool>(
            context: context,
            builder: (ctx) =>
                _buildExitDialog(ctx, "Forfeit Match & Exit App?"),
          );
          if (shouldExit == true) {
            SystemNavigator.pop();
          }
          return;
        }

        // Practice: Return to Lobby
        final phase = controller.phase;
        final isSafeToExit =
            controller.matchEnded || phase == GamePhase.waiting;
        if (isSafeToExit) {
          navigator.maybePop();
          return;
        }
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (ctx) => _buildExitDialog(ctx, "Exit to Lobby?"),
        );
        if (shouldExit == true) {
          navigator.maybePop();
        }
      },
      child: Scaffold(
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
                Column(
                  children: [
                    Selector<GameController, Player>(
                      selector: (_, ctrl) => ctrl.currentPlayer,
                      builder: (_, player, _) =>
                          _buildTurnIndicator(controller),
                    ),
                    Expanded(child: _buildBoard(context, controller)),
                  ],
                ),
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
                Positioned(
                  bottom: 16,
                  left: 0,
                  right: 0,
                  child: Center(
                    child: SizedBox(
                      width: 400,
                      child: Consumer<GameController>(
                        builder: (_, ctrl, _) {
                          final isPanelBusy =
                              _isRolling || !_isAppActive || ctrl.isMoving;
                          return ActionPanel(
                            isAgentActive: ctrl.isAgentActive,
                            canRoll: ctrl.canRoll,
                            canEndTurn: ctrl.canEndTurn,
                            canBuyProperty: ctrl.canBuyProperty,
                            canUpgradeProperty: ctrl.canUpgradeProperty,
                            canTakeoverProperty: ctrl.canTakeoverProperty,
                            rollDisabledReason: ctrl.rollDisabledReason,
                            buyDisabledReason: ctrl.buyPropertyDisabledReason,
                            upgradeDisabledReason:
                                ctrl.upgradePropertyDisabledReason,
                            takeoverDisabledReason:
                                ctrl.takeoverPropertyDisabledReason,
                            isLoading: isPanelBusy,
                            onRollDice: (gauge) async {
                              if (!_isAppActive || _isRolling) {
                                return;
                              }
                              setState(() {
                                _isRolling = true;
                              });
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
                              if (mounted) {
                                setState(() {
                                  _isRolling = false;
                                });
                              }
                            },
                            onBuyProperty: () async {
                              await ctrl.buyProperty(
                                ctrl.currentPlayer.position,
                              );
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
                Selector<GameController, String?>(
                  selector: (_, ctrl) => ctrl.lastEffectMessage,
                  builder: (_, msg, _) {
                    if (msg == null) {
                      return const SizedBox.shrink();
                    }
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
                Consumer<GameController>(
                  builder: (_, ctrl, _) {
                    if (!_isRolling && ctrl.diceRoll <= 0) {
                      return const SizedBox.shrink();
                    }
                    return Positioned(
                      bottom: 250,
                      left: 0,
                      right: 0,
                      child: IgnorePointer(
                        child: Transform.scale(
                          scale: 0.6,
                          child: DiceAnimation(
                            isRolling: _isRolling,
                            diceResult: ctrl.diceRoll > 0
                                ? ctrl.diceRoll
                                : null,
                            onRollComplete: () {
                              if (mounted) {
                                setState(() {
                                  _isRolling = false;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    );
                  },
                ),
                // Offline Overlay
                if (!gatekeeper.isGatekeeperConnected &&
                    controller.gameMode == GameMode.practice)
                  _buildOfflineOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildOfflineOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.8),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.signal_wifi_off,
              size: 60,
              color: Colors.orangeAccent,
            ),
            const SizedBox(height: 20),
            Text(
              "CONNECTION LOST",
              style: GoogleFonts.orbitron(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.orangeAccent,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Game Paused. Waiting for Agent...",
              style: GoogleFonts.robotoMono(color: Colors.white70),
            ),
            const SizedBox(height: 20),
            // Retry is automatic via Service, but visual feedback helps
            const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.orangeAccent,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExitDialog(BuildContext context, String title) {
    return AlertDialog(
      backgroundColor: Colors.black,
      shape: RoundedRectangleBorder(
        side: const BorderSide(color: Colors.redAccent),
        borderRadius: BorderRadius.circular(12),
      ),
      title: Text(title, style: GoogleFonts.orbitron(color: Colors.white)),
      content: Text(
        "Current progress will be lost.",
        style: GoogleFonts.robotoMono(color: Colors.white70),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text("CANCEL"),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(
            "EXIT",
            style: GoogleFonts.orbitron(
              color: Colors.redAccent,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
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
