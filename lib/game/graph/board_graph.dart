import '../models/board_node.dart';
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
    // TODO: This should eventually be loaded from a JSON config or similar.
    // For now, we recreate the 20-tile loop as a graph for backward compatibility testing.

    // Rectangular path logic ported from GameController
    const double limit = 0.85;
    const double step = (limit * 2) / 5;

    // Helper to add node
    void add(int index, Alignment pos, NodeType type, String label) {
      final id = 'node_$index';
      final nextId = 'node_${(index + 1) % 20}';

      _nodes[id] = BoardNode(
        id: id,
        type: type,
        position: pos,
        nextNodeIds: [nextId],
        label: label,
      );
    }

    // Generate 20 nodes
    for (int i = 0; i < 20; i++) {
      Alignment pos;
      if (i < 5) {
        // Bottom: Right -> Left
        pos = Alignment(limit - (i * step), limit);
      } else if (i < 10) {
        // Left: Bottom -> Top
        pos = Alignment(-limit, limit - ((i - 5) * step));
      } else if (i < 15) {
        // Top: Left -> Right
        pos = Alignment(-limit + ((i - 10) * step), -limit);
      } else {
        // Right: Top -> Bottom
        pos = Alignment(limit, -limit + ((i - 15) * step));
      }

      NodeType type = NodeType.property; // Default
      String label = 'Node $i'; // Fallback

      // City Name Mapping (Indonesian Theme)
      const Map<int, String> cityNames = {
        1: 'Bekasi',
        2: 'Depok',
        4: 'Bogor',
        6: 'Tangerang',
        8: 'Bandung',
        9: 'Semarang',
        11: 'Yogya',
        13: 'Surabaya',
        16: 'Bali',
        17: 'Lombok',
        19: 'Papua',
      };

      if (i == 0) {
        type = NodeType.start;
        label = 'START';
      } else if (i % 5 == 0) {
        type = NodeType.minigame;
        label = 'CACHE';
      } else if (i % 7 == 0) {
        type = NodeType.prison;
        label = 'FIREWALL';
      } else if (i == 3 || i == 12 || i == 18) {
        type = NodeType.event;
        label = 'EVENT';
      } else {
        // Properties
        if (cityNames.containsKey(i)) {
          label = cityNames[i]!;
        }
      }

      add(i, pos, type, label);
    }
  }
}
