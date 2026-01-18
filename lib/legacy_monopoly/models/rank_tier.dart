enum RankTier { bronze, silver, gold, cyberElite }

extension RankTierExtension on RankTier {
  String get name {
    switch (this) {
      case RankTier.bronze:
        return 'Script Kiddie';
      case RankTier.silver:
        return 'Netrunner';
      case RankTier.gold:
        return 'Cyber Lord';
      case RankTier.cyberElite:
        return 'Ghost in the Machine';
    }
  }

  int get minPoints {
    switch (this) {
      case RankTier.bronze:
        return 0;
      case RankTier.silver:
        return 500;
      case RankTier.gold:
        return 1500;
      case RankTier.cyberElite:
        return 3000;
    }
  }

  int get maxPoints {
    switch (this) {
      case RankTier.bronze:
        return 499;
      case RankTier.silver:
        return 1499;
      case RankTier.gold:
        return 2999;
      case RankTier.cyberElite:
        return 999999;
    }
  }
}

RankTier rankTierFromPoints(int points) {
  if (points >= RankTier.cyberElite.minPoints) return RankTier.cyberElite;
  if (points >= RankTier.gold.minPoints) return RankTier.gold;
  if (points >= RankTier.silver.minPoints) return RankTier.silver;
  return RankTier.bronze;
}
