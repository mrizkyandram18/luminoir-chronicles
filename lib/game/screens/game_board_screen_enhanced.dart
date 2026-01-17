import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import '../game_controller.dart';
import '../models/tile_model.dart';
import '../models/player_model.dart';
import '../widgets/hud_overlay.dart';
import '../widgets/action_panel.dart';
import '../animations/effects_manager.dart';

/// Enhanced Game Board Screen with integrated HUD and Action Panel
class GameBoardScreenEnhanced extends StatelessWidget {
  const GameBoardScreenEnhanced({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Stack(
          children: [
            // Main Game Board
            Column(
              children: [
                // Top Bar - Turn Indicator
                _buildTurnIndicator(controller),

                // The Board
                Expanded(child: _buildBoard(context, controller)),
              ],
            ),

            // HUD Overlay (Top Right)
            Positioned(
              top: 60,
              right: 16,
              child: HudOverlay(
                players: controller.players,
                currentPlayerIndex: controller.currentPlayerIndex,
                isOnline: true, // TODO: Get from connection state
              ),
            ),

            // Action Panel (Bottom Center)
            Positioned(
              bottom: 16,
              left: 0,
              right: 0,
              child: Center(
                child: SizedBox(
                  width: 400,
                  child: ActionPanel(
                    isMyTurn: controller.isMyTurn,
                    isAgentActive: true, // TODO: Get from gatekeeper
                    canBuyProperty: _canBuyProperty(controller),
                    canUpgradeProperty: _canUpgradeProperty(controller),
                    onRollDice: () => _handleRollDice(context, controller),
                    onBuyProperty: () =>
                        _handleBuyProperty(context, controller),
                    onUpgradeProperty: () =>
                        _handleUpgradeProperty(context, controller),
                    onSaveGame: () => _handleSaveGame(context, controller),
                    onLoadGame: () => _handleLoadGame(context, controller),
                  ),
                ),
              ),
            ),

            // Floating Effects Layer
            if (controller.lastEffectMessage != null)
              Positioned(
                top: 120,
                left: 0,
                right: 0,
                child: Center(
                  child: EffectsManager.floatingScore(
                    context: context,
                    text: controller.lastEffectMessage!,
                    color: controller.currentPlayer.color,
                  ),
                ),
              ),
          ],
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
          margin: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/board/isometric_board.png'),
              fit: BoxFit.contain,
            ),
            boxShadow: [
              BoxShadow(
                color: controller.currentPlayer.color.withValues(alpha: 0.3),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Stack(
            children: [
              // Render Tiles
              ...List.generate(controller.tiles.length, (index) {
                return _buildTile(controller, index);
              }),

              // Render Tokens with smooth animation
              ...controller.players.map((player) {
                return AnimatedAlign(
                  duration: const Duration(milliseconds: 600),
                  curve: Curves.easeOutBack,
                  alignment: controller.getPlayerAlignment(player),
                  child: _buildToken(
                    player,
                    controller.currentPlayer.id == player.id,
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTile(GameController controller, int index) {
    final tile = controller.tiles[index];
    Color tileColor;
    Color borderColor = Colors.transparent;

    // Determine Base Color
    switch (tile.type) {
      case TileType.reward:
        tileColor = Colors.greenAccent;
        break;
      case TileType.penalty:
        tileColor = Colors.redAccent;
        break;
      case TileType.event:
        tileColor = Colors.purpleAccent;
        break;
      case TileType.start:
        tileColor = Colors.white;
        break;
      case TileType.property:
        tileColor = Colors.amberAccent;
        break;
      default:
        tileColor = Colors.cyanAccent.withValues(alpha: 0.3);
    }

    // Determine Owner Border
    if (tile.ownerId != null) {
      final owner = controller.players.firstWhere(
        (p) => p.id == tile.ownerId,
        orElse: () => controller.players[0],
      );
      borderColor = owner.color;
      tileColor = owner.color.withValues(alpha: 0.2);
    }

    return Align(
      alignment: controller.boardPath[index],
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.8),
          border: Border.all(
            color: tile.ownerId != null ? borderColor : tileColor,
            width: tile.ownerId != null ? 3.0 : 1.5,
          ),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: (tile.ownerId != null ? borderColor : tileColor)
                  .withValues(alpha: 0.3),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                tile.ownerId != null ? "OWNED" : tile.label,
                textAlign: TextAlign.center,
                style: GoogleFonts.robotoMono(
                  color: tile.ownerId != null ? borderColor : tileColor,
                  fontSize: 7,
                  fontWeight: FontWeight.bold,
                ),
              ),
              // Property Info
              if (tile.type == TileType.property && tile.ownerId == null)
                Text(
                  "\$${tile.value}",
                  style: const TextStyle(color: Colors.white, fontSize: 8),
                ),
              // Upgrade Level
              if (tile.ownerId != null)
                Column(
                  children: [
                    Text(
                      "Lv ${tile.upgradeLevel}",
                      style: GoogleFonts.orbitron(
                        color: Colors.yellow,
                        fontSize: 8,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      "R: \$${tile.rent}",
                      style: const TextStyle(
                        color: Colors.white54,
                        fontSize: 7,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToken(Player player, bool isActive) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(colors: [Colors.white, player.color]),
        border: isActive ? Border.all(color: Colors.white, width: 3) : null,
        boxShadow: [
          BoxShadow(
            color: player.color.withValues(alpha: isActive ? 0.8 : 0.5),
            blurRadius: isActive ? 20 : 10,
            spreadRadius: isActive ? 3 : 1,
          ),
        ],
      ),
      child: const Icon(Icons.flight, color: Colors.black, size: 24),
    );
  }

  // Helper Methods
  bool _canBuyProperty(GameController controller) {
    final currentTile = controller.tiles[controller.currentPlayer.position];
    return currentTile.type == TileType.property && currentTile.ownerId == null;
  }

  bool _canUpgradeProperty(GameController controller) {
    final currentTile = controller.tiles[controller.currentPlayer.position];
    return currentTile.type == TileType.property &&
        currentTile.ownerId == controller.currentPlayer.id;
  }

  // Action Handlers
  Future<void> _handleRollDice(
    BuildContext context,
    GameController controller,
  ) async {
    await controller.rollDice();

    // Show Event Card if triggered
    if (context.mounted && controller.currentEventCard != null) {
      _showEventCardDialog(context, controller);
    }

    // Show effect message
    if (context.mounted && controller.lastEffectMessage != null) {
      _showSnackBar(
        context,
        controller.lastEffectMessage!,
        controller.currentPlayer.color,
      );
    }
  }

  Future<void> _handleBuyProperty(
    BuildContext context,
    GameController controller,
  ) async {
    await controller.buyProperty(controller.currentPlayer.position);
    if (context.mounted && controller.lastEffectMessage != null) {
      _showSnackBar(context, controller.lastEffectMessage!, Colors.greenAccent);
    }
  }

  Future<void> _handleUpgradeProperty(
    BuildContext context,
    GameController controller,
  ) async {
    await controller.buyPropertyUpgrade(controller.currentPlayer.position);
    if (context.mounted && controller.lastEffectMessage != null) {
      _showSnackBar(
        context,
        controller.lastEffectMessage!,
        Colors.purpleAccent,
      );
    }
  }

  Future<void> _handleSaveGame(
    BuildContext context,
    GameController controller,
  ) async {
    await controller.saveGame();
    if (context.mounted && controller.lastEffectMessage != null) {
      _showSnackBar(
        context,
        controller.lastEffectMessage!,
        Colors.orangeAccent,
      );
    }
  }

  Future<void> _handleLoadGame(
    BuildContext context,
    GameController controller,
  ) async {
    await controller.loadGame();
    if (context.mounted && controller.lastEffectMessage != null) {
      _showSnackBar(
        context,
        controller.lastEffectMessage!,
        Colors.orangeAccent,
      );
    }
  }

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
