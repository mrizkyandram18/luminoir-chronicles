import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'models/raid_player.dart';
import 'models/raid_equipment.dart';

import 'systems/combat_system.dart';
import 'systems/stage_system.dart';
import 'systems/equipment_system.dart';
import 'systems/idle_system.dart';
import 'systems/prestige_system.dart';
import 'systems/save_system.dart';

import 'components/hero_component.dart';
import 'components/enemy_component.dart';

class CyberRaidGame extends FlameGame {
  final String myPlayerId;
  final PlayerJob myJob;

  late final CombatSystem combatSystem;
  late final CampaignSystem campaignSystem;
  late final EquipmentSystem equipmentSystem;
  late final IdleRewardSystem idleSystem;
  late final PrestigeSystem prestigeSystem;
  late final SaveSystem saveSystem;

  final ValueNotifier<int> goldNotifier = ValueNotifier(0);
  final ValueNotifier<int> waveNotifier = ValueNotifier(1);
  final ValueNotifier<bool> isBossWaveNotifier = ValueNotifier(false);
  final ValueNotifier<double> bossHpNotifier = ValueNotifier(1000);
  final ValueNotifier<double> bossTimerNotifier = ValueNotifier(0);

  late RaidPlayer myPlayer;

  int get stage => campaignSystem.stage;
  int get wave => campaignSystem.wave;
  double get bossHp => campaignSystem.bossCurrentHp;
  double get bossMaxHp => campaignSystem.bossMaxHp;
  double get bossTimer => campaignSystem.bossTimer;
  bool get isBossWave => campaignSystem.isBossWave;

  CyberRaidGame({
    required this.myPlayerId,
    required this.myJob,
  }) {
    idleSystem = IdleRewardSystem();
    saveSystem = SaveSystem(idleRewardSystem: idleSystem);
    combatSystem = CombatSystem(this);
    campaignSystem = CampaignSystem(this);
    equipmentSystem = EquipmentSystem();
    prestigeSystem = PrestigeSystem();
    myPlayer = RaidPlayer.create(
      myPlayerId,
      "Agent",
      myJob,
    );
  }

  @override
  Future<void> onLoad() async {
    super.onLoad();

    final snapshot = await saveSystem.loadOrCreatePlayer(myPlayerId);

    myPlayer.gold = snapshot.gold;

    campaignSystem.startWave(1);

    add(HeroComponent()..position = Vector2(size.x * 0.3, size.y * 0.6));
    add(EnemyComponent()..position = Vector2(size.x * 0.7, size.y * 0.6));
  }

  @override
  void update(double dt) {
    super.update(dt);

    campaignSystem.update(dt);
    combatSystem.update(dt);
    saveSystem.update(dt);

    final snapshot = saveSystem.currentPlayer;
    if (snapshot != null) {
      if (goldNotifier.value != snapshot.gold) {
        goldNotifier.value = snapshot.gold;
      }
      myPlayer.gold = snapshot.gold;
    }
    if (waveNotifier.value != campaignSystem.wave) {
      waveNotifier.value = campaignSystem.wave;
    }
    if (isBossWaveNotifier.value != campaignSystem.isBossWave) {
      isBossWaveNotifier.value = campaignSystem.isBossWave;
    }

    bossHpNotifier.value = campaignSystem.bossCurrentHp;
    bossTimerNotifier.value = campaignSystem.bossTimer;
  }

  // --- Actions exposed to UI ---

  void upgradeAttack() {
    final snapshot = saveSystem.currentPlayer;
    if (snapshot == null) return;
    final cost = (myPlayer.attack * 10).round();
    if (snapshot.gold < cost) return;
    saveSystem.updateGold(-cost);
    myPlayer.attack += 5;
  }

  void manualAttack() {
    final damage = myPlayer.attack;
    campaignSystem.applyBossDamage(damage);
    myPlayer.totalDamageDealt += damage.toInt();
  }

  void merge(RaidEquipment a, RaidEquipment b) {
    if (equipmentSystem.merge(myPlayer, a, b)) {
    }
  }

  Future<void> gachaSummon() async {
    final snapshot = saveSystem.currentPlayer;
    if (snapshot == null) return;
    const cost = 1000;
    if (snapshot.gold < cost) return;

    saveSystem.updateGold(-cost);

    final results = await saveSystem.performGachaDraw('hero_core', 1);
    if (results.isEmpty) return;

    final first = results.first;
    final name = first['item_code']?.toString() ?? 'Summoned Gear';
    final rarityString = first['rarity']?.toString() ?? 'common';

    final rarity = Rarity.values.firstWhere(
      (r) => r.name == rarityString,
      orElse: () => Rarity.common,
    );

    final item = RaidEquipment(
      id: first['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      name: name,
      type: EquipmentType.weapon,
      rarity: rarity,
      attackBonus: (first['attack_bonus'] as int?) ?? 5,
      speedBonus: (first['speed_bonus'] as num?)?.toDouble() ?? 0,
      critBonus: (first['crit_bonus'] as num?)?.toDouble() ?? 0,
    );

    myPlayer.equip(item);
  }

  void prestige() {
    final result = prestigeSystem.performPrestige(
      currentRelics: 0,
      stage: campaignSystem.stage,
    );

    if (result.isNotEmpty) {
      myPlayer.level = 1;
      saveSystem.updateGold(-myPlayer.gold);
      campaignSystem.reset();
    }
  }
}
