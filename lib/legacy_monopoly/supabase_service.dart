import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'models/player_model.dart';

/// Enhanced Supabase service with granular sync methods and error recovery
class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  /// Listen to the 'players' table for real-time updates.
  Stream<List<Player>> getPlayersStream() {
    return _client
        .from('players')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true)
        .map((data) => data.map((json) => Player.fromMap(json)).toList());
  }

  /// Initial setup: If table empty, create default players.
  Future<void> initializeDefaultPlayersIfNeeded(List<Player> defaults) async {
    final response = await _client.from('players').select().limit(1);

    if (response.isEmpty) {
      debugPrint("Supabase: Initializing default players...");
      for (final p in defaults) {
        await upsertPlayer(p);
      }
    }
  }

  /// Update or Insert a player's state.
  Future<void> upsertPlayer(Player player) async {
    try {
      await _client.from('players').upsert(player.toMap());
    } catch (e) {
      debugPrint("Supabase Error upserting player: $e");
      rethrow;
    }
  }

  /// Update player position only (granular sync for animations)
  Future<void> updatePlayerPosition(String playerId, int newPosition) async {
    try {
      await _client
          .from('players')
          .update({'position': newPosition})
          .eq('id', playerId);
    } catch (e) {
      debugPrint("Supabase Error updating player position: $e");
      rethrow;
    }
  }

  /// Update player credits (granular sync for buy actions)
  Future<void> updatePlayerCredits(String playerId, int credits) async {
    try {
      await _client
          .from('players')
          .update({'credits': credits})
          .eq('id', playerId);
    } catch (e) {
      debugPrint("Supabase Error updating player credits: $e");
      rethrow;
    }
  }

  /// Update player score and multiplier (granular sync for upgrades)
  Future<void> updatePlayerScore(
    String playerId,
    int score,
    int scoreMultiplier,
  ) async {
    try {
      await _client
          .from('players')
          .update({'score': score, 'score_multiplier': scoreMultiplier})
          .eq('id', playerId);
    } catch (e) {
      debugPrint("Supabase Error updating player score: $e");
      rethrow;
    }
  }

  /// Listen to 'properties' table for ownership changes.
  Stream<List<Map<String, dynamic>>> getPropertiesStream() {
    return _client
        .from('properties')
        .stream(primaryKey: ['tile_id'])
        .map((data) => data);
  }

  /// Update property ownership and level
  Future<void> upsertProperty(
    int tileId,
    String ownerId,
    int upgradeLevel,
  ) async {
    try {
      await _client.from('properties').upsert({
        'tile_id': tileId,
        'owner_id': ownerId,
        'upgrade_level': upgradeLevel,
      });
    } catch (e) {
      debugPrint("Supabase Error upserting property: $e");
      rethrow;
    }
  }

  /// Reset all players (New Game)
  Future<void> resetGame(List<Player> defaults) async {
    for (final p in defaults) {
      await upsertPlayer(p);
    }
    // Reset properties by deleting all
    try {
      await _client.from('properties').delete().neq('tile_id', -1);
    } catch (e) {
      debugPrint("Supabase Error resetting properties: $e");
    }
  }

  /// Save Global Game State (Turn number, Deck, etc.)
  Future<void> saveGameState(int currentPlayerIndex) async {
    try {
      await _client.from('game_state').upsert({
        'id': 'current_session',
        'current_player_index': currentPlayerIndex,
        'updated_at': DateTime.now().toIso8601String(),
      });
    } catch (e) {
      debugPrint("Supabase Error saving game state: $e");
      rethrow;
    }
  }

  /// Load Global Game State
  Future<Map<String, dynamic>?> loadGameState() async {
    try {
      final response = await _client
          .from('game_state')
          .select()
          .eq('id', 'current_session')
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("Supabase Error loading game state: $e");
      return null;
    }
  }

  /// Record match result for rank/history
  Future<void> recordMatchResult(Map<String, dynamic> data) async {
    try {
      await _client.from('match_results').upsert(data);
    } catch (e) {
      debugPrint("Supabase Error recording match result: $e");
    }
  }

  /// Get human players sorted by rank points (for leaderboard)
  Future<List<Map<String, dynamic>>> queryLeaderboard({int limit = 100}) async {
    try {
      final response = await _client
          .from('players')
          .select()
          .eq('is_human', true)
          .order('rank_points', ascending: false)
          .order('wins', ascending: false)
          .limit(limit);
      return (response as List).cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint("Supabase Error querying leaderboard: $e");
      return [];
    }
  }

  /// Get specific players data (for friend leaderboard)
  Future<List<Map<String, dynamic>>> queryPlayersByIds(List<String> ids) async {
    if (ids.isEmpty) return [];
    try {
      final response = await _client
          .from('players')
          .select()
          .eq('is_human', true)
          .order('rank_points', ascending: false);

      final data = (response as List).cast<Map<String, dynamic>>();
      return data.where((p) => ids.contains(p['id'])).toList();
    } catch (e) {
      debugPrint("Supabase Error querying players by ids: $e");
      return [];
    }
  }

  /// Get player rank stats
  Future<Map<String, dynamic>?> queryPlayerRankStats(String playerId) async {
    try {
      return await _client
          .from('players')
          .select('rank_points, wins, losses')
          .eq('id', playerId)
          .single();
    } catch (e) {
      debugPrint("Supabase Error querying player rank stats: $e");
      return null;
    }
  }

  /// Get player position in leaderboard
  Future<int> queryPlayerRankPosition(String playerId) async {
    try {
      final response = await _client
          .from('leaderboard')
          .select('rank_position')
          .eq('id', playerId)
          .maybeSingle();
      return (response?['rank_position'] as int?) ?? 0;
    } catch (e) {
      debugPrint("Supabase Error querying player rank position: $e");
      return 0;
    }
  }

  /// Update player rank stats
  Future<void> updatePlayerRankStats(
    String playerId,
    Map<String, dynamic> updates,
  ) async {
    try {
      await _client.from('players').update(updates).eq('id', playerId);
    } catch (e) {
      debugPrint("Supabase Error updating player rank stats: $e");
      rethrow;
    }
  }
}
