import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../models/rank_tier.dart';
import '../supabase_service.dart';
import 'rank_service.dart';

class LeaderboardService {
  final SupabaseService _supabase;

  LeaderboardService(this._supabase);

  Future<List<Player>> fetchGlobalLeaderboard({int limit = 100}) async {
    final response = await _supabase.queryLeaderboard(limit: limit);
    return response.map((data) => Player.fromMap(data)).toList();
  }

  Future<List<Player>> fetchFriendLeaderboard(List<String> friendIds) async {
    if (friendIds.isEmpty) return [];
    final response = await _supabase.queryPlayersByIds(friendIds);
    return response.map((data) => Player.fromMap(data)).toList();
  }

  Future<void> updatePlayerStats(Player player) async {
    try {
      await _supabase.upsertPlayer(player);
    } catch (e) {
      debugPrint('Error updating player stats: $e');
      rethrow;
    }
  }

  Future<void> updateRankAfterMatch({
    required String playerId,
    required bool won,
    required bool isRankedMode,
  }) async {
    if (!isRankedMode) return;

    final response = await _supabase.queryPlayerRankStats(playerId);
    if (response == null) return;

    final currentPoints = (response['rank_points'] as int?) ?? 0;
    final currentWins = (response['wins'] as int?) ?? 0;
    final currentLosses = (response['losses'] as int?) ?? 0;

    final newPoints = RankService.calculateNewRankPoints(currentPoints, won);
    final newWins = won ? currentWins + 1 : currentWins;
    final newLosses = won ? currentLosses : currentLosses + 1;
    final newTier = RankService.calculateTier(newPoints).name;

    await _supabase.updatePlayerRankStats(playerId, {
      'rank_points': newPoints,
      'wins': newWins,
      'losses': newLosses,
      'rank_tier': newTier,
    });
  }

  Future<int> getPlayerRankPosition(String playerId) async {
    return await _supabase.queryPlayerRankPosition(playerId);
  }
}
