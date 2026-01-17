import 'dart:ui';

class Player {
  final String id;
  final String name;
  final Color color;
  int position;
  String nodeId; // Graph-based position
  int score;
  int credits;
  int gems; // Hard Currency
  int scoreMultiplier;
  final bool isHuman;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.position = 0,
    this.nodeId = 'node_0', // Default start node
    this.score = 100,
    this.credits = 500,
    this.gems = 0,
    this.scoreMultiplier = 1,
    this.isHuman = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      // Store color as a single integer (ARGB)
      'color_value': color.toARGB32(),
      'position': position,
      'node_id': nodeId,
      'score': score,
      'credits': credits,
      'gems': gems,
      'score_multiplier': scoreMultiplier,
      'is_human': isHuman,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      // Load color from integer, default to blue if missing
      color: map['color_value'] != null
          ? Color(map['color_value'])
          : const Color(0xFF2196F3),
      position: map['position']?.toInt() ?? 0,
      nodeId: map['node_id'] ?? 'node_0',
      score: map['score']?.toInt() ?? 0,
      credits: map['credits']?.toInt() ?? 500,
      gems: map['gems']?.toInt() ?? 0,
      scoreMultiplier: map['score_multiplier']?.toInt() ?? 1,
      isHuman: map['is_human'] ?? true,
    );
  }
}
