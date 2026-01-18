class PrestigeSystem {
  bool canPrestige(int stage) {
    return stage >= 10;
  }

  Map<String, dynamic> performPrestige({
    required int currentRelics,
    required int stage,
  }) {
    if (!canPrestige(stage)) return {};

    final earnedRelics = 1; // Simplify formula for MVP
    final newRelicCount = currentRelics + earnedRelics;

    return {
      'relics': newRelicCount,
      'reset_stage': 1,
      'reset_gold': 0,
      'reset_level': 1,
    };
  }
}
