import 'dart:math' as math;

class IdleRewardSystem {
  // Max idle time increased to 24 hours
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

    // Gold per second based on Stage progression
    // Formula: Base 1 Gold + (Stage^1.2) * 0.5
    // Stage 1: ~1.5 Gold/sec
    // Stage 10: ~8 Gold/sec
    // Stage 100: ~125 Gold/sec
    final goldPerSecond = 1 + (math.pow(maxStage, 1.2) * 0.5);

    return (effectiveSeconds * goldPerSecond).round();
  }
}
