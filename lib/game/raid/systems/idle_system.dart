import 'dart:math' as math;

class IdleRewardSystem {
  static const int maxIdleSeconds = 24 * 3600;

  int calculateIdleGold({
    required DateTime lastLogin,
    required int maxStage, // Changed from accountPowerMultiplier to maxStage
    required DateTime now,
  }) {
    final idleSeconds = now.difference(lastLogin).inSeconds;
    if (idleSeconds <= 60) return 0; // Minimum 1 minute to count as idle

    final effectiveSeconds =
        idleSeconds > maxIdleSeconds ? maxIdleSeconds : idleSeconds;

    final goldPerSecond = 1 + (math.pow(maxStage, 1.2) * 0.5);

    return (effectiveSeconds * goldPerSecond).round();
  }

  static int calculateIdleExpFromGold(int idleGold) {
    if (idleGold <= 0) return 0;
    return (idleGold / 10).round();
  }
}
