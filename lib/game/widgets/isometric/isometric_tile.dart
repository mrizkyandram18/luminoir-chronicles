import 'package:flutter/material.dart';
import '../../models/board_node.dart';
import '../../models/property_details.dart';

class IsometricTile extends StatelessWidget {
  final BoardNode node;
  final double size;
  final PropertyDetails? property; // New: Property Data
  final bool onlyLabel; // New Flag

  const IsometricTile({
    super.key,
    required this.node,
    required this.size,
    this.property,
    this.onlyLabel = false,
  });

  @override
  Widget build(BuildContext context) {
    // If onlyLabel is true, return ONLY the floating label
    if (onlyLabel) {
      return SizedBox(
        width: size,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              bottom: size * 0.1, // Lifting it WAY up to avoid overlap
              right: 0,
              left: 0,
              child: _buildLabel(),
            ),
          ],
        ),
      );
    }

    // ---------------------------------------------------------
    // NORMAL RENDER (Base + Building, NO LABEL)
    // ---------------------------------------------------------

    // 1. Determine Tile APPEARANCE (Pure Code, No Assets)
    Color tileColor = Colors.grey;
    IconData? tileIcon;

    switch (node.type) {
      case NodeType.start:
        tileColor = Colors.green;
        tileIcon = Icons.flag;
        break;
      case NodeType.event:
        tileColor = Colors.purple;
        tileIcon = Icons.flash_on;
        break;
      case NodeType.teleport:
        tileColor = Colors.indigo;
        tileIcon = Icons.public;
        break;
      case NodeType.prison:
        tileColor = Colors.red;
        tileIcon = Icons.lock;
        break;
      case NodeType.minigame:
        tileColor = Colors.amber;
        tileIcon = Icons.videogame_asset;
        break;
      default: // NodeType.property
        tileColor = const Color(0xFF1E3A8A); // Deep Blue (Instead of Grey)
    }

    // 2. Building Logic REMOVED (User Request: Clean Look)
    // Just show flat tiles.

    // 2. Render as a 3D Slab (Thick Block)
    // "maksud saya jelek adalah... bukan pakai building" -> User wants DEPTH.
    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // A. The 3D Slab (Base thickness)
          // We simulate a block by drawing the distinct "Sidewalls" and "Top"
          _build3DBlock(
            width: size * 0.9, // Slightly smaller than slot
            height: size * 0.2, // Thickness of the tile (Slab)
            color: tileColor,
            icon: tileIcon,
          ),
        ],
      ),
    );
  }

  Widget _build3DBlock({
    required double width,
    required double height,
    required Color color,
    IconData? icon,
  }) {
    // 3D Projection Mockup
    // We need to render this "Standing Up" relative to the board
    // The "Top Face" is the main tile.

    // Actually, in the current IsometricBoard setup, the "Tile" widget is flat on the floor.
    // To make it look thick, we can't just draw a box.
    // We will draw:
    // 1. A "Shadow/Side" offset down.
    // 2. The "Top" face.

    // BUT, since we removed the 3D transforms, let's keep it simple.
    // We will effectively make a "Button" shape.

    final Color sideColor = Color.lerp(color, Colors.black, 0.4)!;

    return Center(
      child: SizedBox(
        width: width,
        height: width, // Square Top
        child: Stack(
          children: [
            // 1. The "Side/Thickness" (Shifted down Y) - Performance: Solid Color, No Shadow
            // In Isometry, 'Down' on screen is 'Down' in Z? No.
            // We can simulate thickness by rendering a copies offset downwards.
            Transform.translate(
              offset: const Offset(0, 8), // 8px thickness
              child: Container(
                decoration: BoxDecoration(
                  color: sideColor,
                  borderRadius: BorderRadius.circular(8),
                  // No BoxShadow here. Pure container.
                ),
              ),
            ),

            // 2. The "Main Top Face"
            Container(
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.white24, width: 1),
                // Gradient is okay, but keep it simple
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [color.withValues(alpha: 0.9), color],
                ),
                // Minimal shadow
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 0,
                  ),
                ],
              ),
              child: Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // Icon
                    if (icon != null)
                      Icon(icon, color: Colors.white24, size: width * 0.5),

                    // Level Indicators (Dots)
                    if (property != null && property!.buildingLevel > 0)
                      Positioned(
                        top: 4,
                        right: 4,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(
                            property!.hasLandmark ? 1 : property!.buildingLevel,
                            (i) => Padding(
                              padding: const EdgeInsets.only(left: 2),
                              child: Icon(
                                property!.hasLandmark
                                    ? Icons.star
                                    : Icons.circle,
                                color: property!.hasLandmark
                                    ? Colors.amber
                                    : Colors.cyanAccent,
                                size: 6,
                              ),
                            ),
                          ),
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

  Widget _buildLabel() {
    return Transform(
      alignment: Alignment.center,
      transform: Matrix4.identity()
        ..rotateZ(-3.14159 / 4)
        ..rotateX(-3.14159 / 3),
      child: Text(
        node.label,
        style: const TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.bold,
          color: Colors.white,
          shadows: [Shadow(color: Colors.black, blurRadius: 4)],
        ),
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
