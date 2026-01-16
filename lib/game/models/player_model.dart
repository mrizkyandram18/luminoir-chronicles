import 'dart:ui';

class Player {
  final String id;
  final String name;
  final Color color;
  int position;
  int score;
  final bool isHuman;

  Player({
    required this.id,
    required this.name,
    required this.color,
    this.position = 0,
    this.score = 100,
    this.isHuman = true,
  });
}
