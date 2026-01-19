import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'idle_system.dart';

class PlayerSnapshot {
  final String id;
  int gold;
  int maxCampaignStage;
  DateTime lastLogin;
  int accountPowerMultiplier;
  int idleGoldGained;

  PlayerSnapshot({
    required this.id,
    required this.gold,
    required this.maxCampaignStage,
    required this.lastLogin,
    required this.accountPowerMultiplier,
    required this.idleGoldGained,
  });
}

class SaveSystem {
  final SupabaseClient _client = Supabase.instance.client;
  final IdleRewardSystem idleRewardSystem;

  PlayerSnapshot? _currentPlayer;
  double _saveTimer = 0;
  static const double saveIntervalSeconds = 30.0;

  SaveSystem({required this.idleRewardSystem});

  PlayerSnapshot? get currentPlayer => _currentPlayer;

  Future<PlayerSnapshot> loadOrCreatePlayer(String playerId) async {
    final now = DateTime.now().toUtc();

    final existing = await _client
        .from('players')
        .select()
        .eq('id', playerId)
        .maybeSingle();

    if (existing == null) {
      await _client.from('players').insert({
        'id': playerId,
        'gold': 0,
        'last_login': now.toIso8601String(),
        'max_campaign_stage': 1,
      });

      _currentPlayer = PlayerSnapshot(
        id: playerId,
        gold: 0,
        maxCampaignStage: 1,
        lastLogin: now,
        accountPowerMultiplier: 1,
        idleGoldGained: 0,
      );
      return _currentPlayer!;
    }

    final lastLoginRaw = existing['last_login'] as String?;
    final lastLogin =
        lastLoginRaw != null ? DateTime.parse(lastLoginRaw).toUtc() : now;
    final gold = (existing['gold'] as int?) ?? 0;
    final maxStage = (existing['max_campaign_stage'] as int?) ?? 1;

    final accountPowerMultiplier =
        (existing['account_power_multiplier'] as int?) ?? 1;

    final idleGold = idleRewardSystem.calculateIdleGold(
      lastLogin: lastLogin,
      maxStage: maxStage, // Pass maxStage for better scaling
      now: now,
    );

    final newGold = gold + idleGold;

    await _client.from('players').update({
      'gold': newGold,
      'last_login': now.toIso8601String(),
      'account_power_multiplier': accountPowerMultiplier,
    }).eq('id', playerId);

    _currentPlayer = PlayerSnapshot(
      id: playerId,
      gold: newGold,
      maxCampaignStage: maxStage,
      lastLogin: now,
      accountPowerMultiplier: accountPowerMultiplier,
      idleGoldGained: idleGold,
    );

    return _currentPlayer!;
  }

  Future<bool> upgradeAccountPower() async {
    if (_currentPlayer == null) return false;

    // Cost Formula: 100 * (1.5 ^ (Level - 1))
    // Level 1 -> 100 Gold
    // Level 2 -> 150 Gold
    // Level 10 -> ~3800 Gold
    final currentLevel = _currentPlayer!.accountPowerMultiplier;
    final cost = (100 * (matchPow(1.5, currentLevel - 1))).round();

    if (_currentPlayer!.gold < cost) {
      return false;
    }

    final newGold = _currentPlayer!.gold - cost;
    final newLevel = currentLevel + 1;

    try {
      await _client.from('players').update({
        'gold': newGold,
        'account_power_multiplier': newLevel,
      }).eq('id', _currentPlayer!.id);

      // Update local snapshot
      _currentPlayer!.gold = newGold;
      _currentPlayer!.accountPowerMultiplier = newLevel;
      return true;
    } catch (e) {
      // Handle error (e.g., network)
      return false;
    }
  }

  int getNextUpgradeCost() {
    if (_currentPlayer == null) return 0;
    final currentLevel = _currentPlayer!.accountPowerMultiplier;
    return (100 * (matchPow(1.5, currentLevel - 1))).round();
  }

  // Helper for pow since dart:math isn't imported
  double matchPow(double x, int exponent) {
    double result = 1.0;
    for (int i = 0; i < exponent; i++) {
      result *= x;
    }
    return result;
  }

  void update(double dt) {
    if (_currentPlayer == null) return;

    _saveTimer += dt;
    if (_saveTimer >= saveIntervalSeconds) {
      _saveTimer = 0;
      _persistPlayer();
    }
  }

  void updateGold(int delta) {
    if (_currentPlayer == null) return;
    _currentPlayer!.gold += delta;
  }

  void setMaxCampaignStage(int stage) {
    if (_currentPlayer == null) return;
    if (stage > _currentPlayer!.maxCampaignStage) {
      _currentPlayer!.maxCampaignStage = stage;
    }
  }

  Future<void> saveNow() async {
    await _persistPlayer();
  }

  Future<void> _persistPlayer() async {
    final player = _currentPlayer;
    if (player == null) return;

    await _client.from('players').update({
      'gold': player.gold,
      'max_campaign_stage': player.maxCampaignStage,
      'last_login': DateTime.now().toUtc().toIso8601String(),
      'account_power_multiplier': player.accountPowerMultiplier,
    }).eq('id', player.id);
  }

  Future<List<Map<String, dynamic>>> performGachaDraw(
    String poolCode,
    int count,
  ) async {
    final result = await _client.rpc(
      'perform_gacha',
      params: {'pool_code': poolCode, 'count': count},
    );

    if (result is List) {
      return result.cast<Map<String, dynamic>>();
    }

    return [];
  }

  Future<void> submitCoopResult(Map<String, dynamic> result) async {
    await _client.rpc('submit_coop_result', params: result);
  }
}
