enum Faction {
  fire,
  water,
  thunder,
  wind,
  earth,
  yinYang,
}

enum CombatClass {
  warrior,
  mage,
  support,
  ranger,
  assassin,
}

class RestrainEffect {
  final double damageTakenMultiplier;
  final double accuracyMultiplier;

  const RestrainEffect({
    required this.damageTakenMultiplier,
    required this.accuracyMultiplier,
  });
}

const RestrainEffect neutralRestrainEffect = RestrainEffect(
  damageTakenMultiplier: 1.0,
  accuracyMultiplier: 1.0,
);

const RestrainEffect restrainedEffect = RestrainEffect(
  damageTakenMultiplier: 1.3,
  accuracyMultiplier: 0.85,
);

extension FactionRelations on Faction {
  Faction? restrains() {
    switch (this) {
      case Faction.thunder:
        return Faction.earth;
      case Faction.earth:
        return Faction.water;
      case Faction.water:
        return Faction.fire;
      case Faction.fire:
        return Faction.wind;
      case Faction.wind:
        return Faction.thunder;
      case Faction.yinYang:
        return null;
    }
  }

  Faction? restrainedBy() {
    switch (this) {
      case Faction.thunder:
        return Faction.wind;
      case Faction.earth:
        return Faction.thunder;
      case Faction.water:
        return Faction.earth;
      case Faction.fire:
        return Faction.water;
      case Faction.wind:
        return Faction.fire;
      case Faction.yinYang:
        return null;
    }
  }

  bool hasAdvantageOver(Faction other) {
    return restrains() == other;
  }

  bool hasDisadvantageAgainst(Faction other) {
    return restrainedBy() == other;
  }

  static RestrainEffect defenderEffect({
    required Faction attacker,
    required Faction defender,
  }) {
    if (attacker.restrains() == defender) {
      return restrainedEffect;
    }
    return neutralRestrainEffect;
  }
}

