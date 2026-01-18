import '../cyber_raid_game.dart';

class CombatSystem {
  final CyberRaidGame game;

  double _attackGauge = 0;

  CombatSystem(this.game);

  void update(double dt) {
    final attacker = game.myPlayer;
    _attackGauge += attacker.attackSpeed * dt;

    while (_attackGauge >= 1.0) {
      _attackGauge -= 1.0;
      final damage = attacker.attack;
      game.campaignSystem.applyBossDamage(damage);
      attacker.totalDamageDealt += damage.toInt();
    }
  }
}
