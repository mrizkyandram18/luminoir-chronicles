enum TileType { start, neutral, reward, penalty, event, property }

class Tile {
  final int id;
  final TileType type;
  final String label;
  final int value; // Reward/Penalty/Price

  // Property Fields
  final String? ownerId; // Null if bank owned
  final int rent;

  const Tile({
    required this.id,
    required this.type,
    required this.label,
    this.value = 0,
    this.ownerId,
    this.rent = 0,
  });

  // Create a copy with new owner
  Tile copyWith({String? ownerId}) {
    return Tile(
      id: id,
      type: type,
      label: label,
      value: value,
      ownerId: ownerId ?? this.ownerId,
      rent: rent,
    );
  }
}
