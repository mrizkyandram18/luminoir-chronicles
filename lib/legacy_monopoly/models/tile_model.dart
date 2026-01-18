enum TileType { start, neutral, reward, penalty, event, property }

class Tile {
  final int id;
  final TileType type;
  final String label;
  final int value; // Reward/Penalty/Price
  final int? colorGroupId;

  // Property Fields
  final String? ownerId; // Null if bank owned
  final int rent;
  final int upgradeLevel; // default 0

  const Tile({
    required this.id,
    required this.type,
    required this.label,
    this.value = 0,
    this.colorGroupId,
    this.ownerId,
    this.rent = 0,
    this.upgradeLevel = 0,
  });

  // Create a copy with new owner or level
  Tile copyWith({
    String? ownerId,
    int? upgradeLevel,
    int? rent,
    int? colorGroupId,
  }) {
    return Tile(
      id: id,
      type: type,
      label: label,
      value: value,
      colorGroupId: colorGroupId ?? this.colorGroupId,
      ownerId: ownerId ?? this.ownerId,
      rent: rent ?? this.rent,
      upgradeLevel: upgradeLevel ?? this.upgradeLevel,
    );
  }
}
