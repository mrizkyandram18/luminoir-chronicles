enum EquipmentType { weapon, armor, drone }

enum Rarity { common, rare, legendary }

class RaidEquipment {
  final String id;
  final String name;
  final EquipmentType type;
  final Rarity rarity;

  // Stats
  final int attackBonus;
  final double speedBonus;
  final double critBonus;

  RaidEquipment({
    required this.id,
    required this.name,
    required this.type,
    required this.rarity,
    this.attackBonus = 0,
    this.speedBonus = 0.0,
    this.critBonus = 0.0,
  });

  // Factory for random generation
  factory RaidEquipment.random(String id) {
    // Simple Random logic (mocked for now, usually needs a weighted generator)
    final now = DateTime.now().millisecondsSinceEpoch;
    final isLegendary = (now % 100) < 5; // 5%
    final isRare = (now % 100) < 20; // 20% (if not legendary)

    Rarity r = Rarity.common;
    if (isLegendary) {
      r = Rarity.legendary;
    } else if (isRare) {
      r = Rarity.rare;
    }

    int atk = 5;
    if (r == Rarity.rare) {
      atk = 15;
    }
    if (r == Rarity.legendary) {
      atk = 50;
    }

    return RaidEquipment(
      id: id,
      name: "${r.name.toUpperCase()} Blade", // Generic name
      type: EquipmentType.weapon,
      rarity: r,
      attackBonus: atk,
    );
  }

  /// Returns a new equipment with upgraded stats (Tier + 1)
  RaidEquipment upgrade() {
    // Simple logic: +50% stats
    return RaidEquipment(
      id: id,
      name: "$name +",
      type: type,
      rarity: rarity,
      attackBonus: (attackBonus * 1.5).toInt(),
      speedBonus: speedBonus,
      critBonus: critBonus,
    );
  }
}
