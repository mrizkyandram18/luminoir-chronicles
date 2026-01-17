import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../game_controller.dart';
import '../models/tile_model.dart';

class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Access the state
    final controller = context.watch<GameController>();

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // 0. Top Controls (Save/Load)
            Container(
              color: Colors.grey[900],
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.save, size: 16, color: Colors.blueGrey),
                    label: Text(
                      "SAVE",
                      style: GoogleFonts.robotoMono(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      context.read<GameController>().saveGame();
                    },
                  ),
                  const Gap(10),
                  TextButton.icon(
                    icon: Icon(
                      Icons.download,
                      size: 16,
                      color: Colors.blueGrey,
                    ),
                    label: Text(
                      "LOAD",
                      style: GoogleFonts.robotoMono(
                        color: Colors.blueGrey,
                        fontSize: 12,
                      ),
                    ),
                    onPressed: () {
                      context.read<GameController>().loadGame();
                    },
                  ),
                ],
              ),
            ),

            // 1. Top Bar - Player Scores
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              color: Colors.black54,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: controller.players.map((player) {
                  final isActive = controller.currentPlayer.id == player.id;
                  return AnimatedOpacity(
                    duration: const Duration(milliseconds: 300),
                    opacity: isActive ? 1.0 : 0.5,
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: isActive
                          ? BoxDecoration(
                              border: Border.all(color: player.color, width: 2),
                              borderRadius: BorderRadius.circular(8),
                              color: player.color.withValues(alpha: 0.1),
                            )
                          : null,
                      child: Column(
                        children: [
                          Text(
                            player.name,
                            style: GoogleFonts.robotoMono(
                              color: player.color,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '${player.score}',
                            style: GoogleFonts.orbitron(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                          Text(
                            '\$${player.credits}',
                            style: GoogleFonts.sourceCodePro(
                              color: Colors.yellowAccent,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // 2. Turn Indicator
            Padding(
              padding: const EdgeInsets.only(top: 5, bottom: 5),
              child: Text(
                "${controller.currentPlayer.name}'s Turn",
                style: GoogleFonts.orbitron(
                  color: controller.currentPlayer.color,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      color: controller.currentPlayer.color,
                      blurRadius: 10,
                    ),
                  ],
                ),
              ),
            ),

            // 3. The Board (Expanded to fit remaining space)
            Expanded(
              child: Center(
                child: AspectRatio(
                  aspectRatio: 1.0,
                  child: Container(
                    margin: const EdgeInsets.all(8), // Small margin
                    decoration: BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage(
                          'assets/images/board/isometric_board.png',
                        ),
                        fit: BoxFit.contain,
                      ),
                    ),
                    child: Stack(
                      children: [
                        // A. Render the 20 Tiles visual
                        ...List.generate(controller.tiles.length, (index) {
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
                              tileColor = Colors.cyanAccent.withValues(
                                alpha: 0.3,
                              );
                          }

                          // Determine Owner Border
                          if (tile.ownerId != null) {
                            final owner = controller.players.firstWhere(
                              (p) => p.id == tile.ownerId,
                              orElse: () => controller.players[0], // Fallback
                            );
                            borderColor = owner.color;
                            tileColor = owner.color.withValues(
                              alpha: 0.2,
                            ); // Tint tile with owner color
                          }

                          return Align(
                            alignment: controller.boardPath[index],
                            child: Container(
                              width: 60,
                              height: 60,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.8),
                                border: Border.all(
                                  color: tile.ownerId != null
                                      ? borderColor
                                      : tileColor,
                                  width: tile.ownerId != null ? 3.0 : 1.5,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color:
                                        (tile.ownerId != null
                                                ? borderColor
                                                : tileColor)
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
                                      tile.ownerId != null
                                          ? "OWNED"
                                          : tile.label,
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.robotoMono(
                                        color: tile.ownerId != null
                                            ? borderColor
                                            : tileColor,
                                        fontSize: 7,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    // Price or Value
                                    if (tile.type == TileType.property &&
                                        tile.ownerId == null)
                                      Text(
                                        "\$${tile.value}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                      ),
                                    if (tile.value != 0 &&
                                        tile.type != TileType.property &&
                                        tile.type != TileType.start)
                                      Text(
                                        "${tile.value > 0 ? '+' : ''}${tile.value}",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                        ),
                                      ),

                                    // Rent Indicator
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
                                            style: TextStyle(
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
                        }),

                        // B. The Tokens
                        ...controller.players.map((player) {
                          return AnimatedAlign(
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutBack,
                            alignment: controller.getPlayerAlignment(player),
                            child: Container(
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.white,
                                boxShadow: [
                                  BoxShadow(
                                    color: player.color.withValues(alpha: 0.8),
                                    blurRadius: 15,
                                    spreadRadius: 2,
                                  ),
                                ],
                                gradient: RadialGradient(
                                  colors: [Colors.white, player.color],
                                ),
                                border: controller.currentPlayer.id == player.id
                                    ? Border.all(color: Colors.white, width: 3)
                                    : null,
                              ),
                              child: Icon(
                                Icons.flight,
                                color: Colors.black,
                                size: 24,
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // 4. Bottom Controls
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
              decoration: BoxDecoration(
                color: Colors.black87,
                border: Border(
                  top: BorderSide(
                    color: controller.currentPlayer.color,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Buy Property Button (Conditional)
                  if (controller
                              .tiles[controller.currentPlayer.position]
                              .type ==
                          TileType.property &&
                      controller
                              .tiles[controller.currentPlayer.position]
                              .ownerId ==
                          null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.amber,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        context.read<GameController>().buyProperty(
                          controller.currentPlayer.position,
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            "BUY PROP",
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "\$${controller.tiles[controller.currentPlayer.position].value}",
                            style: GoogleFonts.orbitron(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else if (controller
                              .tiles[controller.currentPlayer.position]
                              .type ==
                          TileType.property &&
                      controller
                              .tiles[controller.currentPlayer.position]
                              .ownerId ==
                          controller.currentPlayer.id)
                    // Upgrade Property Button
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blueAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        context.read<GameController>().buyPropertyUpgrade(
                          controller.currentPlayer.position,
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            "UPGRADE",
                            style: GoogleFonts.robotoMono(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "\$200",
                            style: GoogleFonts.orbitron(fontSize: 12),
                          ),
                        ],
                      ),
                    )
                  else
                    // Player Upgrade Button (Default)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.grey[900],
                        foregroundColor: Colors.yellowAccent,
                        side: BorderSide(color: Colors.yellowAccent),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 15,
                        ),
                      ),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text("Tycoon Boosts coming soon!"),
                            duration: Duration(seconds: 1),
                          ),
                        );
                      },
                      child: Column(
                        children: [
                          Text(
                            "BOOST",
                            style: GoogleFonts.robotoMono(fontSize: 10),
                          ),
                          Text(
                            "\$200",
                            style: GoogleFonts.orbitron(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const Gap(20),

                  // Roll Stats
                  Column(
                    children: [
                      Text(
                        'ROLLED',
                        style: GoogleFonts.roboto(
                          color: Colors.white54,
                          fontSize: 10,
                        ),
                      ),
                      Text(
                        '${controller.diceRoll}',
                        style: GoogleFonts.orbitron(
                          color: controller.currentPlayer.color,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const Gap(20),

                  // Roll Button
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: controller.currentPlayer.color,
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 30,
                        vertical: 20,
                      ),
                    ),
                    onPressed: () async {
                      final game = context.read<GameController>();
                      await game.rollDice();

                      // Check for Event Card after roll
                      if (context.mounted && game.currentEventCard != null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                              side: BorderSide(
                                color: Colors.purpleAccent,
                                width: 2,
                              ),
                            ),
                            title: Text(
                              "EVENT INTERCEPTED",
                              style: GoogleFonts.orbitron(
                                color: Colors.purpleAccent,
                              ),
                            ),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  game.currentEventCard!.title,
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Gap(10),
                                Text(
                                  game.currentEventCard!.description,
                                  style: GoogleFonts.roboto(
                                    color: Colors.white70,
                                  ),
                                ),
                                const Gap(20),
                                Text(
                                  game.currentEventCard!.value.toString(),
                                  style: GoogleFonts.sourceCodePro(
                                    color: Colors.purpleAccent,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(ctx),
                                child: Text(
                                  "ACKNOWLEDGE",
                                  style: GoogleFonts.orbitron(
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      if (context.mounted && game.lastEffectMessage != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              game.lastEffectMessage!,
                              style: GoogleFonts.robotoMono(
                                color: Colors.black,
                              ),
                            ),
                            backgroundColor: game.currentPlayer.color,
                            duration: const Duration(seconds: 2),
                          ),
                        );
                      }
                    },
                    child: Text(
                      'ROLL',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
