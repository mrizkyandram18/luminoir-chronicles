import 'dart:ui';

class Player {
  final String id;
  final String name;
  final Color color;
  int position;
  int score;
  int credits;
  int scoreMultiplier;
  final bool isHuman;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.position = 0,
    this.score = 100,
    this.credits = 500,
    this.scoreMultiplier = 1,
    this.isHuman = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'color_a': (color.a * 255).round(),
      'color_r': (color.r * 255).round(),
      'color_g': (color.g * 255).round(),
      'color_b': (color.b * 255).round(),
      'position': position,
      'score': score,
      'credits': credits,
      'score_multiplier': scoreMultiplier,
      'is_human': isHuman,
    };
  }

  factory Player.fromMap(Map<String, dynamic> map) {
    return Player(
      id: map['id'] ?? '',
      name: map['name'] ?? 'Unknown',
      color: Color.fromARGB(
        map['color_a']?.toInt() ?? 255,
        map['color_r']?.toInt() ?? 255,
        map['color_g']?.toInt() ?? 255,
        map['color_b']?.toInt() ?? 255,
      ),
      position: map['position']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      credits: map['credits']?.toInt() ?? 500,
      scoreMultiplier: map['score_multiplier']?.toInt() ?? 1,
      isHuman: map['is_human'] ?? true,
    );
  }
}
