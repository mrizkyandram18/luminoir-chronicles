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
    this.credits = 500, // Starting credits
    this.scoreMultiplier = 1, // Default multiplier
    this.isHuman = true,
  });
}
