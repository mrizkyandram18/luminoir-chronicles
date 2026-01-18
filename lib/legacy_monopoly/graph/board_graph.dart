import '../models/board_node.dart';
import '../models/tile_model.dart';
import '../data/standard_board_data.dart';
import 'package:flutter/painting.dart';

class BoardGraph {
  final Map<String, BoardNode> _nodes = {};

  BoardGraph() {
    _initializeDefaultBoard();
  }

  /// Get a node by ID
  BoardNode? getNode(String id) => _nodes[id];

  /// Get all nodes
  Map<String, BoardNode> get nodes => _nodes;

  /// Get the start node (usually 'node_0')
  BoardNode get startNode => _nodes['node_0']!;

  void _initializeDefaultBoard() {
    // Standard Monopoly Board has 40 tiles.
    // Layout: Square. 10 steps per side between corners.
    // Total per side including corners = 11.
    // Indices:
    // Bottom: 0 (BR) -> 10 (BL)
    // Left: 10 (BL) -> 20 (TL)
    // Top: 20 (TL) -> 30 (TR)
    // Right: 30 (TR) -> 40/0 (BR)

    const double limit = 0.95;
    const double step = (limit * 2) / 10; // 10 steps per side

    for (var data in BoardData.standardBoard) {
      int i = data['id'] as int;
      String label = data['label'] as String;
      NodeType type;

      // Map TileType to NodeType
      TileType tType = data['type'] as TileType;
      switch (tType) {
        case TileType.start:
          type = NodeType.start;
          break;
        case TileType.property:
          type = NodeType.property;
          break;
        case TileType.event:
          type = NodeType.event;
          break;
        case TileType.penalty: // Tax or Jail
          if (label == 'Jail') {
            type = NodeType.neutral; // Just Visiting
          } else {
            type = NodeType.prison; // Tax / Go To Jail -> Pay Penalty
          }
          break;
        case TileType.reward:
          type = NodeType.minigame; // Free Parking -> Reward
          break;
        default:
          type = NodeType.property;
      }

      // Override for existing logic compatibility if needed
      if (label == 'Jail') type = NodeType.neutral;

      Alignment pos;
      if (i <= 10) {
        // Bottom: Right -> Left (0 at BR, 10 at BL)
        pos = Alignment(limit - (i * step), limit);
      } else if (i <= 20) {
        // Left: Bottom -> Top (10 at BL, 20 at TL)
        pos = Alignment(-limit, limit - ((i - 10) * step));
      } else if (i <= 30) {
        // Top: Left -> Right (20 at TL, 30 at TR)
        pos = Alignment(-limit + ((i - 20) * step), -limit);
      } else {
        // Right: Top -> Bottom (30 at TR, 40/0 at BR)
        pos = Alignment(limit, -limit + ((i - 30) * step));
      }

      final id = 'node_$i';
      final nextId = 'node_${(i + 1) % 40}';

      _nodes[id] = BoardNode(
        id: id,
        type: type,
        position: pos,
        nextNodeIds: [nextId],
        label: label,
      );
    }
  }
}
