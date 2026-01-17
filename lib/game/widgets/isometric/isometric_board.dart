import 'dart:math';
import 'package:flutter/material.dart';
import '../../graph/board_graph.dart';
import '../../models/player_model.dart';
import 'isometric_tile.dart';
import 'player_token.dart';

import '../../models/property_details.dart';

class IsometricBoard extends StatefulWidget {
  final BoardGraph graph;
  final List<Player> players;
  final double tileSize;
  final Map<String, PropertyDetails> properties; // New: Properties Data

  const IsometricBoard({
    super.key,
    required this.graph,
    required this.players,
    this.tileSize = 64.0,
    this.properties = const {}, // Default empty
  });

  @override
  State<IsometricBoard> createState() => _IsometricBoardState();
}

class _IsometricBoardState extends State<IsometricBoard> {
  // Transformation Constants for standard Isometric view
  static const double _angleX = pi / 3; // 60 degrees
  static const double _angleZ = pi / 4; // 45 degrees

  @override
  Widget build(BuildContext context) {
    // Determine board bounds to center it
    final boardSize = 20 * widget.tileSize;

    return InteractiveViewer(
      minScale: 0.5,
      maxScale: 2.0,
      boundaryMargin: const EdgeInsets.all(double.infinity),
      child: Center(
        child: SizedBox(
          width: boardSize,
          height: boardSize,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..rotateX(_angleX)
              ..rotateZ(_angleZ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // 1. Render Tiles & Buildings (Bottom Layer)
                ...widget.graph.nodes.values.map((node) {
                  final int nodeId = int.tryParse(node.id.split('_').last) ?? 0;
                  final gridPos = _getGridPosition(nodeId, 20);
                  final prop = widget.properties[node.id];

                  return Positioned(
                    left: gridPos.dx * widget.tileSize,
                    top: gridPos.dy * widget.tileSize,
                    child: IsometricTile(
                      node: node,
                      size: widget.tileSize,
                      property: prop,
                      onlyLabel: false, // Don't render label here
                    ),
                  );
                }),

                // 2. Render Players (Middle Layer)
                ...widget.players.map((player) {
                  final node = widget.graph.getNode(player.nodeId);
                  if (node == null) return const SizedBox.shrink();

                  final int nodeId =
                      int.tryParse(player.nodeId.split('_').last) ?? 0;
                  final gridPos = _getGridPosition(nodeId, 20);

                  return AnimatedPositioned(
                    duration: const Duration(milliseconds: 300), // Snappier
                    curve: Curves.easeInOutQuad,
                    left: gridPos.dx * widget.tileSize,
                    top: gridPos.dy * widget.tileSize,
                    child: PlayerToken(player: player, size: widget.tileSize),
                  );
                }),

                // 3. Render Labels (Top Layer - Always Visible)
                ...widget.graph.nodes.values.map((node) {
                  final int nodeId = int.tryParse(node.id.split('_').last) ?? 0;
                  final gridPos = _getGridPosition(nodeId, 20);

                  return Positioned(
                    left: gridPos.dx * widget.tileSize,
                    top: gridPos.dy * widget.tileSize,
                    child: IgnorePointer(
                      child: IsometricTile(
                        node: node,
                        size: widget.tileSize,
                        onlyLabel: true, // Render ONLY label
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper to layout tiles in a square loop (monopoly style)
  // Total 20 tiles -> 5x5 grid (approx)
  // 0-4 (Bottom), 5-9 (Right), 10-14 (Top), 15-19 (Left)
  Offset _getGridPosition(int index, int total) {
    // Simplified logic for 20 tiles:
    // Bottom: 0..5 (x:0..5, y:5)
    // Right: 6..10 (x:5, y:4..0)
    // Top: 11..15 (x:4..0, y:0)
    // Left: 16..19 (x:0, y:1..4)

    // Hardcoding specific loop for safety if dynamic logic breaks
    if (index <= 5) return Offset(index.toDouble(), 5);
    if (index <= 10) return Offset(5, 5 - (index - 5).toDouble());
    if (index <= 15) return Offset(5 - (index - 10).toDouble(), 0);
    return Offset(0, (index - 15).toDouble());
  }
}
