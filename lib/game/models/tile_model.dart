enum TileType { start, neutral, reward, penalty, event, property }

class Tile {
  final int id;
  final TileType type;
  final String label;
  final int value; // Reward/Penalty/Price

  // Property Fields
  final String? ownerId; // Null if bank owned
  final int rent;
  final int level; // 1-5

  const Tile({
    required this.id,
    required this.type,
    required this.label,
    this.value = 0,
    this.ownerId,
    this.rent = 0,
    this.level = 1,
  });

  // Create a copy with new owner or level
  Tile copyWith({String? ownerId, int? level, int? rent}) {
    return Tile(
      id: id,
      type: type,
      label: label,
      value: value,
      ownerId: ownerId ?? this.ownerId,
      rent: rent ?? this.rent,
      level: level ?? this.level,
    );
  }
}
