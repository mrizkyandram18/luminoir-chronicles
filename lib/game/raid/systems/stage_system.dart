import '../cyber_raid_game.dart';

class CampaignSystem {
  final CyberRaidGame game;

  int stage = 1;
  int wave = 1;
  double bossTimer = 0;
  bool isBossWave = false;

  double bossMaxHp = 1000;
  double bossCurrentHp = 1000;

  CampaignSystem(this.game);

  void update(double dt) {
    if (isBossWave) {
      bossTimer -= dt;
      if (bossTimer <= 0) {
        _failBoss();
      }
    }
  }

  void startWave(int newWave) {
    wave = newWave;
    isBossWave = (wave % 10 == 0) || (stage == 1 && wave == 1);
    if (isBossWave) {
      bossTimer = 30.0;
      bossMaxHp = _scaledBossHp();
      bossCurrentHp = bossMaxHp;
    }
  }

  void reset() {
    stage = 1;
    startWave(1);
  }

  void applyBossDamage(double amount) {
    if (!isBossWave) {
      return;
    }
    bossCurrentHp -= amount;
    if (bossCurrentHp <= 0) {
      _onBossDefeated();
    }
  }

  void _onBossDefeated() {
    stage++;
    wave = 1;
    game.saveSystem.setMaxCampaignStage(stage);
    startWave(wave);
  }

  double _scaledBossHp() {
    final baseHp = 1000.0;
    return baseHp * (1.0 + (stage - 1) * 0.25);
  }

  void _failBoss() {
    // Reset to wave 1 (farming)
    startWave(1);
    // Notify Game/UI
  }
}
