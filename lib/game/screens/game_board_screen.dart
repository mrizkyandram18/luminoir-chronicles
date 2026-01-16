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
      body: Stack(
        children: [
          // 1. The Board Image (Centered)
          Center(
            child: AspectRatio(
              aspectRatio: 1.0,
              child: Container(
                margin: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                      'assets/images/board/isometric_board.png',
                    ),
                    fit: BoxFit.contain,
                  ),
                ),
                // 2. The Token (Overlay on top of board)
                child: Stack(
                  children: [
                    // A. Render the 20 Tiles visual
                    // We iterate through the generated path points and place a visual "Tile" at each.
                    ...List.generate(controller.tiles.length, (index) {
                      final tile = controller.tiles[index];
                      Color tileColor;
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
                        default:
                          tileColor = Colors.cyanAccent;
                      }

                      return Align(
                        alignment: controller.boardPath[index],
                        child: Container(
                          width: 60, // Requested 60x60
                          height: 60,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(
                              alpha: 0.6,
                            ), // Darker background
                            border: Border.all(
                              color: tileColor, // Tile Type color
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(
                              8,
                            ), // Slightly rounded
                            boxShadow: [
                              BoxShadow(
                                color: tileColor.withValues(
                                  alpha: 0.2,
                                ), // Glow matches type
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Center(
                            child: Text(
                              tile.label,
                              textAlign: TextAlign.center,
                              style: GoogleFonts.robotoMono(
                                color: tileColor,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),

                    // B. The Token (Overlay on top of tiles)
                    AnimatedAlign(
                      duration: const Duration(
                        milliseconds: 300,
                      ), // Snappier movement
                      curve: Curves.easeOutBack, // Bouncy feel
                      alignment: controller.currentAlignment,
                      child: Container(
                        width: 40, // Token smaller than tile to fit inside
                        height: 40,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.redAccent,
                              blurRadius: 15,
                              spreadRadius: 2,
                            ),
                          ],
                          gradient: RadialGradient(
                            colors: [Colors.white, Colors.redAccent],
                          ),
                        ),
                        child: const Icon(
                          Icons.flight,
                          color: Colors.black,
                          size: 24,
                        ), // Drone icon
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 3. HUD / Controls (Overlay on top of everything)
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Cyber Tycoon',
                        style: GoogleFonts.orbitron(
                          color: Colors.cyanAccent,
                          fontSize: 18,
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'SCORE',
                            style: GoogleFonts.robotoMono(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                          Text(
                            '${controller.score}',
                            style: GoogleFonts.orbitron(
                              color: Colors.yellowAccent,
                              fontSize: 24,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                // Bottom Controls
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.black87,
                    border: Border(
                      top: BorderSide(color: Colors.cyanAccent, width: 2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Column(
                        children: [
                          Text(
                            'ROLLED',
                            style: GoogleFonts.roboto(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          Text(
                            '${controller.diceRoll}',
                            style: GoogleFonts.orbitron(
                              color: Colors.cyanAccent,
                              fontSize: 40,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const Gap(40),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyan,
                          foregroundColor: Colors.black,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 40,
                            vertical: 20,
                          ),
                        ),
                        onPressed: () async {
                          final game = context.read<GameController>();
                          await game.rollDice();

                          if (context.mounted &&
                              game.lastEffectMessage != null) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  game.lastEffectMessage!,
                                  style: GoogleFonts.robotoMono(
                                    color: Colors.black,
                                  ),
                                ),
                                backgroundColor: Colors.cyanAccent,
                                duration: const Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        child: Text(
                          'ROLL DICE',
                          style: GoogleFonts.orbitron(
                            fontSize: 20,
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
        ],
      ),
    );
  }
}
