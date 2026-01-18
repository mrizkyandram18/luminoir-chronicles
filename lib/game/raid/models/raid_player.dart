import 'raid_equipment.dart';

enum PlayerJob { warrior, mage, archer, assassin }

enum RaidStat { attack, attackSpeed, critChance }

class RaidPlayer {
  final String id;
  final String name;
  final PlayerJob job;

  // Dynamic Stats
  double currentHp;
  double maxHp;
  double attack; // Damage per hit
  double get dps => attack * attackSpeed;
  double attackSpeed; // Attacks per second
  double critChance; // 0.0 to 1.0
  double criticalMultiplier; // e.g. 2.0x

  // Economy
  int gold;
  int diamonds; // Premium currency (optional)

  // Match Progress
  int totalDamageDealt;
  int level;
  double currentExp;
  double expToNextLevel;

  RaidPlayer({
    required this.id,
    required this.name,
    required this.job,
    this.currentHp = 100,
    this.maxHp = 100,
    this.attack = 10,
    this.attackSpeed = 1.0,
    this.critChance = 0.05,
    this.criticalMultiplier = 1.5,
    this.gold = 0,
    this.diamonds = 0,
    this.totalDamageDealt = 0,
    this.level = 1,
    this.currentExp = 0,
    this.expToNextLevel = 100,
  });

  // Factory to create base stats based on Job
  factory RaidPlayer.create(String id, String name, PlayerJob job) {
    switch (job) {
      case PlayerJob.warrior:
        return RaidPlayer(
          id: id,
          name: name,
          job: job,
          attack: 20, // High Dmg
          attackSpeed: 0.8, // Slow
          critChance: 0.05,
        );
      case PlayerJob.archer:
        return RaidPlayer(
          id: id,
          name: name,
          job: job,
          attack: 8, // Low Dmg
          attackSpeed: 2.5, // Fast
          critChance: 0.1,
        );
      case PlayerJob.mage:
        return RaidPlayer(
          id: id,
          name: name,
          job: job,
          attack: 30, // Very High Dmg
          attackSpeed: 0.5, // Very Slow
          critChance: 0.0, // Stable
        );
      case PlayerJob.assassin:
        return RaidPlayer(
          id: id,
          name: name,
          job: job,
          attack: 12,
          attackSpeed: 1.5,
          critChance: 0.3, // High Crit
          criticalMultiplier: 2.5,
        );
    }
  }

  void addExp(int amount) {
    currentExp += amount;
    if (currentExp >= expToNextLevel) {
      _levelUp();
    }
  }

  void _levelUp() {
    currentExp -= expToNextLevel;
    level++;
    expToNextLevel *= 1.2; // Curve

    // Stat Growth
    attack *= 1.1;
    maxHp *= 1.1;
    currentHp = maxHp; // Full Heal
  }

  // Equipment
  List<RaidEquipment> equipment = [];

  void equip(RaidEquipment item) {
    equipment.add(item);
    // Apply Stats
    attack += item.attackBonus;
    attackSpeed += item.speedBonus;
    critChance += item.critBonus;
  }
}
