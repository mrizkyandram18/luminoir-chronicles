class IdleRewardSystem {
  static const int maxIdleSeconds = 12 * 3600;

  int calculateIdleGold({
    required DateTime lastLogin,
    required int accountPowerMultiplier,
    required DateTime now,
  }) {
    final idleSeconds = now.difference(lastLogin).inSeconds;
    if (idleSeconds <= 0) return 0;

    final effectiveSeconds =
        idleSeconds > maxIdleSeconds ? maxIdleSeconds : idleSeconds;

    return effectiveSeconds * accountPowerMultiplier;
  }
}
