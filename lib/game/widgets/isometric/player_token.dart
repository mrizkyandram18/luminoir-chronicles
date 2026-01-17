import 'package:flutter/material.dart';
import '../../models/player_model.dart';

class PlayerToken extends StatelessWidget {
  final Player player;
  final double size;

  const PlayerToken({super.key, required this.player, required this.size});

  @override
  Widget build(BuildContext context) {
    // We purposefully offset the token UP (negative Y) so it stands ON the tile, not centered IN it.
    return Transform.translate(
      offset: Offset(0, -size / 2),
      child: SizedBox(
        width: size,
        height: size,
        // The token container itself needs to "Stand Up"
        child: Transform(
          alignment: Alignment.bottomCenter,
          transform: Matrix4.identity()
            ..rotateZ(-3.14159 / 4) // Undo Board Z
            ..rotateX(
              -3.14159 / 2.5,
            ), // Undo Board X (slightly less than full 60 to look down)
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              Container(
                width: size * 0.65,
                height: size * 0.65,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: player.color, width: 3),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black38,
                      blurRadius: 5,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Center(child: Icon(Icons.person, color: player.color)),
              ),
              // Name Tag
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.black87,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  player.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
