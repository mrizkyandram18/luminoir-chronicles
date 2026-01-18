import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../game_controller.dart';
import '../models/tile_model.dart';

class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  // Classic Monopoly Colors
  static const Color boardBeige = Color(0xFFE2E2E2);
  static const Color boardGreen = Color(0xFFCDE6D0);
  static const Color boardBlack = Colors.black;

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<GameController>();

    return Scaffold(
      backgroundColor: boardBeige,
      body: SafeArea(
        child: Stack(
          children: [
            // 1. THE BOARD (1:1 Ratio)
            Positioned.fill(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final side = constraints.maxWidth;
                      final baseTileSize = side / 11;
                      final tokenSize = baseTileSize * 0.7;

                      return Container(
                        decoration: BoxDecoration(
                          color: boardGreen,
                          border: Border.all(color: boardBlack, width: 2),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: RotationTransition(
                                turns: const AlwaysStoppedAnimation(-45 / 360),
                                child: Text(
                                  "CYBER\nTYCOON",
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.philosopher(
                                    color: boardBlack.withValues(alpha: 0.1),
                                    fontSize: 48,
                                    fontWeight: FontWeight.bold,
                                    height: 0.9,
                                  ),
                                ),
                              ),
                            ),

                            ...List.generate(controller.tiles.length, (index) {
                              return _buildClassicTile(
                                index,
                                controller,
                                baseTileSize,
                              );
                            }),

                            ...controller.players.map((player) {
                              final isActive =
                                  controller.currentPlayer.id == player.id;
                              return AnimatedAlign(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOutBack,
                                alignment:
                                    controller.getPlayerAlignment(player),
                                child: Container(
                                  width: tokenSize,
                                  height: tokenSize,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: player.color,
                                    border: Border.all(
                                      color: Colors.white,
                                      width: isActive ? 3 : 1.5,
                                    ),
                                    boxShadow: const [
                                      BoxShadow(
                                        color: Colors.black26,
                                        blurRadius: 4,
                                        offset: Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Icon(
                                    _getTokenIcon(player.id),
                                    color: Colors.white,
                                    size: baseTileSize * 0.3,
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // 2. SIDEBAR HUD (Status & Actions)
            Positioned(
              top: 10,
              left: 10,
              bottom: 10,
              width: 140,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Turn Indicator "Card"
                    _buildIndicatorCard(
                      label: "IN TURN",
                      value: controller.currentPlayer.name.toUpperCase(),
                      color: controller.currentPlayer.color,
                    ),
                    const Gap(10),

                    // Dice Result "Card"
                    _buildStatusCard(
                      label: "DICE ROLL",
                      value: "${controller.diceRoll}",
                      icon: Icons.casino,
                    ),
                    const Gap(10),

                    // Contextual Action Button
                    _buildContextualAction(context, controller),
                    const Gap(10),

                    // Main Controls
                    if (controller.currentPlayer.jailTurns > 0)
                      _buildJailControls(controller)
                    else
                      _buildRollButton(context, controller),

                    if (controller.canEndTurn) ...[
                      const Gap(10),
                      _buildActionButton(
                        label: "END TURN",
                        color: Colors.red[700]!,
                        onPressed: () => controller.endTurn(),
                      ),
                    ],

                    const Gap(15),

                    // Players Ledger Card
                    _buildPlayersCard(controller),
                  ],
                ),
              ),
            ),

            // 3. TOP RIGHT: System Actions
            Positioned(
              top: 10,
              right: 10,
              child: Row(
                children: [
                  _buildSystemButton(
                    icon: Icons.save,
                    onPressed: () => controller.saveGame(),
                  ),
                  const Gap(8),
                  _buildSystemButton(
                    icon: Icons.settings,
                    onPressed: () => controller.loadGame(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- UI HELPER METHODS ---

  Widget _buildStatusCard({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 12, color: boardBlack),
              const Gap(4),
              Text(
                label,
                style: GoogleFonts.philosopher(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                  color: boardBlack,
                ),
              ),
            ],
          ),
          const Divider(color: boardBlack, thickness: 1),
          Text(
            value,
            style: GoogleFonts.philosopher(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: boardBlack,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIndicatorCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.philosopher(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const Gap(4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              border: Border.all(color: boardBlack, width: 1),
            ),
            child: Text(
              value,
              style: GoogleFonts.philosopher(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard(GameController controller) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 2),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(2, 2)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "LEDGER",
            style: GoogleFonts.philosopher(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
              color: boardBlack,
            ),
          ),
          const Gap(8),
          ...controller.players.map((player) {
            final isActive = controller.currentPlayer.id == player.id;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: player.color,
                      border: Border.all(color: boardBlack, width: 1),
                    ),
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      player.name,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.philosopher(
                        fontSize: 11,
                        fontWeight: isActive
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: isActive ? boardBlack : Colors.grey[700],
                      ),
                    ),
                  ),
                  Text(
                    "\$${player.credits}",
                    style: GoogleFonts.roboto(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isActive ? boardBlack : Colors.grey[700],
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12),
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: boardBlack, width: 2),
        ),
        elevation: 4,
      ),
      onPressed: onPressed,
      child: Text(
        label,
        style: GoogleFonts.philosopher(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildSystemButton({
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 2, offset: Offset(1, 1)),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, size: 20, color: boardBlack),
        onPressed: onPressed,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  Widget _buildRollButton(BuildContext context, GameController controller) {
    return _buildActionButton(
      label: "ROLL DICE",
      color: Colors.green[800]!,
      onPressed: controller.canRoll
          ? () async {
              await controller.rollDice();
              if (context.mounted) {
                if (controller.currentEventCard != null) {
                  _showEventDialog(context, controller);
                }
                if (controller.lastEffectMessage != null) {
                  _showEffectSnackBar(context, controller);
                }
              }
            }
          : null,
    );
  }

  Widget _buildJailControls(GameController controller) {
    return Column(
      children: [
        _buildActionButton(
          label: "PAY \$50",
          color: Colors.orange[800]!,
          onPressed: () => controller.payToGetOutOfJail(),
        ),
        const Gap(5),
        _buildActionButton(
          label: "WAIT TURN",
          color: Colors.blueGrey[800]!,
          onPressed: () => controller.skipJailTurn(),
        ),
      ],
    );
  }

  Widget _buildContextualAction(
    BuildContext context,
    GameController controller,
  ) {
    final tile = controller.tiles[controller.currentPlayer.position];
    final isProperty = tile.type == TileType.property;
    final isUnowned = tile.ownerId == null;
    final isMine = tile.ownerId == controller.currentPlayer.id;

    if (isProperty && isUnowned) {
      return _buildActionButton(
        label: "BUY \$${tile.value}",
        color: Colors.amber[800]!,
        onPressed: () =>
            controller.buyProperty(controller.currentPlayer.position),
      );
    } else if (isProperty && isMine) {
      return _buildActionButton(
        label: "UPGRADE \$200",
        color: Colors.blue[800]!,
        onPressed: () =>
            controller.buyPropertyUpgrade(controller.currentPlayer.position),
      );
    }

    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.5),
        border:
            Border.all(color: boardBlack.withValues(alpha: 0.2), width: 2),
      ),
      child: Center(
        child: Text(
          "PROPERTY",
          style: GoogleFonts.philosopher(color: Colors.black26, fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildClassicTile(
    int index,
    GameController controller,
    double baseSize,
  ) {
    final tile = controller.tiles[index];
    final alignment = controller.boardPath[index];

    final groupColors = {
      0: const Color(0xFF955436),
      1: const Color(0xFFAAE0FA),
      2: const Color(0xFFD93A96),
      3: const Color(0xFFF7941D),
      4: const Color(0xFFED1C24),
      5: const Color(0xFFFEF200),
      6: const Color(0xFF1FB25A),
      7: const Color(0xFF0072BB),
      8: Colors.grey,
      9: Colors.white,
    };

    final barColor = groupColors[tile.colorGroupId] ?? Colors.transparent;
    final isCorner = index % 10 == 0;

    final size = isCorner ? baseSize * 1.2 : baseSize;

    bool isBottom = index < 10;
    bool isLeft = index >= 10 && index < 20;
    bool isTop = index >= 20 && index < 30;
    bool isRight = index >= 30;

    final barThickness = baseSize * 0.22;
    final labelFontSize = baseSize * 0.26;
    final valueFontSize = baseSize * 0.22;
    final ownerDotSize = baseSize * 0.24;

    return Align(
      alignment: alignment,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: boardBlack, width: 0.5),
        ),
        child: Stack(
          children: [
            if (barColor != Colors.transparent && !isCorner)
              Positioned(
                top: isBottom ? 0 : null,
                bottom: isTop ? 0 : null,
                left: isRight ? 0 : null,
                right: isLeft ? 0 : null,
                height: (isBottom || isTop)
                    ? barThickness
                    : (isLeft || isRight ? size : null),
                width: (isLeft || isRight)
                    ? barThickness
                    : (isBottom || isTop ? size : null),
                child: Container(color: barColor),
              ),

            Center(
              child: Padding(
                padding: EdgeInsets.all(baseSize * 0.08),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      tile.label.toUpperCase(),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.roboto(
                        color: boardBlack,
                        fontSize: labelFontSize,
                        fontWeight: FontWeight.bold,
                        height: 0.8,
                      ),
                    ),
                    if (tile.type == TileType.property && tile.ownerId == null)
                      Text(
                        "\$${tile.value}",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: valueFontSize,
                        ),
                      ),
                    if (tile.ownerId != null)
                      Container(
                        width: ownerDotSize,
                        height: ownerDotSize,
                        decoration: BoxDecoration(
                          color: controller.players
                              .firstWhere((p) => p.id == tile.ownerId)
                              .color,
                          shape: BoxShape.circle,
                          border: Border.all(color: boardBlack, width: 0.5),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getTokenIcon(String playerId) {
    final icons = [
      Icons.casino,
      Icons.directions_car,
      Icons.airplanemode_active,
      Icons.sailing,
    ];
    final idInt = int.tryParse(playerId.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0;
    return icons[idInt % icons.length];
  }

  void _showEventDialog(BuildContext context, GameController game) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          side: BorderSide(color: boardBlack, width: 2),
        ),
        title: Text(
          "CHANCE / CHEST",
          style: GoogleFonts.philosopher(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              game.currentEventCard!.title,
              style: GoogleFonts.philosopher(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Gap(10),
            Text(
              game.currentEventCard!.description,
              style: GoogleFonts.philosopher(),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              "DISMISS",
              style: GoogleFonts.philosopher(
                color: boardBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEffectSnackBar(BuildContext context, GameController game) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          game.lastEffectMessage!,
          style: GoogleFonts.philosopher(color: Colors.white, fontSize: 12),
        ),
        backgroundColor: boardBlack,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}
