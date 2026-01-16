enum TileType {
  neutral, // Standard tile, no effect
  reward, // Gives points
  penalty, // Deducts points
  event, // Special event (future use)
  start, // Starting tile
}

class Tile {
  final int id;
  final TileType type;
  final int value; // Score value (positive or negative)
  final String label;

  const Tile({
    required this.id,
    required this.type,
    this.value = 0,
    required this.label,
  });
}
