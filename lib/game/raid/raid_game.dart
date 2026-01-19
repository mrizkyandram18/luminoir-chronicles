import 'package:flame/game.dart';
import 'package:flutter/widgets.dart';
import 'dart:math' as math;
import 'models/raid_player.dart';
import 'models/raid_equipment.dart';
import 'models/combat_archetypes.dart';

import 'systems/combat_system.dart';
import 'systems/stage_system.dart';
import 'systems/equipment_system.dart';
import 'systems/idle_system.dart';
import 'systems/prestige_system.dart';
import 'systems/save_system.dart';

import 'components/hero_component.dart';
import 'components/enemy_component.dart';
import '../../services/supabase_service.dart';

class RaidGame extends FlameGame {
  final String myPlayerId;
  final PlayerJob myJob;

  late final CombatSystem combatSystem;
  late final CampaignSystem campaignSystem;
  late final EquipmentSystem equipmentSystem;
  late final IdleRewardSystem idleSystem;
  late final PrestigeSystem prestigeSystem;
  late final SaveSystem saveSystem;
  late final SupabaseService supabaseService;

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

  RaidGame({
    required this.myPlayerId,
    required this.myJob,
  }) {
    idleSystem = IdleRewardSystem();
    saveSystem = SaveSystem(idleRewardSystem: idleSystem);
    combatSystem = CombatSystem(this);
    campaignSystem = CampaignSystem(this);
    equipmentSystem = EquipmentSystem();
    prestigeSystem = PrestigeSystem();
    supabaseService = SupabaseService();
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

    await _applyPartyBonuses();

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

  Future<void> _applyPartyBonuses() async {
    final profile = await supabaseService.getPlayerProfile(myPlayerId);
    if (profile == null) {
      return;
    }

    final rawStats = profile['stats'];
    if (rawStats is! Map) {
      return;
    }

    final stats = rawStats.map(
      (key, value) => MapEntry(key.toString(), value),
    );

    final rawParty = stats['party'];
    if (rawParty is! List) {
      return;
    }

    if (rawParty.isEmpty) {
      return;
    }

    final heroes = rawParty
        .whereType<Map>()
        .map(
          (hero) => hero.map(
            (key, value) => MapEntry(key.toString(), value),
          ),
        )
        .toList();

    double bonusAttack = 0;
    double bonusAttackSpeed = 0;
    double bonusCritChance = 0;
    double bonusMaxHp = 0;

    for (final hero in heroes) {
      final level = (hero['level'] as int?) ?? 1;
      final rarityString = (hero['rarity'] as String?) ?? 'common';
      final heroAttack =
          (hero['attack'] as num?)?.toDouble() ?? _defaultHeroAttack(hero, level);
      final heroHp =
          (hero['hp'] as num?)?.toDouble() ?? _defaultHeroHp(hero, level);
      final rarityMultiplier = _rarityMultiplier(rarityString);
      final factionString = (hero['faction'] as String?) ?? 'yinYang';
      final faction = _parseFaction(factionString);

      final scaledAttack = heroAttack * rarityMultiplier;
      final scaledHp = heroHp * rarityMultiplier;

      switch (faction) {
        case Faction.fire:
          bonusAttack += scaledAttack * 0.05;
          break;
        case Faction.water:
          bonusMaxHp += scaledHp * 0.05;
          break;
        case Faction.thunder:
          bonusAttackSpeed += 0.05;
          break;
        case Faction.wind:
          bonusCritChance += 0.02;
          break;
        case Faction.earth:
          bonusAttack += scaledAttack * 0.025;
          bonusMaxHp += scaledHp * 0.025;
          break;
        case Faction.yinYang:
          bonusAttack += scaledAttack * 0.015;
          bonusMaxHp += scaledHp * 0.015;
          bonusAttackSpeed += 0.02;
          bonusCritChance += 0.01;
          break;
      }
    }

    myPlayer.attack += bonusAttack;
    myPlayer.attackSpeed += bonusAttackSpeed;
    myPlayer.critChance += bonusCritChance;
    myPlayer.maxHp += bonusMaxHp;
    if (myPlayer.currentHp > myPlayer.maxHp) {
      myPlayer.currentHp = myPlayer.maxHp;
    }
  }

  double _rarityMultiplier(String rarity) {
    // Flattened curve: Rarity should provide utility/variety, not just raw stats.
    // This prevents "Pay-to-Win" where Legendary is 3x stronger than Common.
    switch (rarity) {
      case 'legendary':
        return 1.4; // Was 3.0
      case 'epic':
        return 1.25; // Was 2.0
      case 'rare':
        return 1.15; // Was 1.5
      default:
        return 1.0;
    }
  }

  double _defaultHeroAttack(Map<String, dynamic> hero, int level) {
    final rarity = (hero['rarity'] as String?) ?? 'common';
    int baseAttack;
    switch (rarity) {
      case 'legendary':
        baseAttack = 25; // Was 50
        break;
      case 'epic':
        baseAttack = 20; // Was 30
        break;
      case 'rare':
        baseAttack = 15; // Was 15
        break;
      default:
        baseAttack = 10; // Was 5
        break;
    }
    // Logarithmic growth: Levels give less return as you go higher.
    // Prevents Level 100 being 100x stronger.
    return (baseAttack + (10 * math.log(level + 1))).toDouble();
  }

  double _defaultHeroHp(Map<String, dynamic> hero, int level) {
    final rarity = (hero['rarity'] as String?) ?? 'common';
    int baseHp;
    switch (rarity) {
      case 'legendary':
        baseHp = 250; // Was 300
        break;
      case 'epic':
        baseHp = 200; // Was 220
        break;
      case 'rare':
        baseHp = 180; // Was 180
        break;
      default:
        baseHp = 150; // Was 150
        break;
    }
    // Logarithmic growth for HP as well
    return (baseHp + (50 * math.log(level + 1))).toDouble();
  }

  Faction _parseFaction(String value) {
    return Faction.values.firstWhere(
      (f) => f.name == value,
      orElse: () => Faction.yinYang,
    );
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
