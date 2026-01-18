import 'package:flutter/painting.dart';

enum NodeType {
  start,
  property,
  event,
  minigame,
  teleport, // Wormhole
  prison, // Firewall/Jail
  fork, // Decision point
  neutral, // Safe/Visiting
}

class BoardNode {
  final String id;
  final NodeType type;

  /// Normalized position on the board (0.0 - 1.0 for x and y)
  /// Used by the UI to render the node and tokens on top of it.
  final Alignment position;

  /// IDs of the next possible nodes.
  /// If length > 1, the player must choose a path.
  final List<String> nextNodeIds;

  // Specific data for rendering
  final String label;

  const BoardNode({
    required this.id,
    required this.type,
    required this.position,
    required this.nextNodeIds,
    required this.label,
  });

  /// Check if this node is a fork (decision point)
  bool get isFork => nextNodeIds.length > 1;
}
