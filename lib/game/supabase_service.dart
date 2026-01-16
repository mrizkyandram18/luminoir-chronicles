import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';
import 'models/player_model.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;

  // Realtime channel for broadcasting turns/events if needed
  // But for simple state, we just listen to the table.

  /// Listen to the 'players' table for real-time updates.
  Stream<List<Player>> getPlayersStream() {
    return _client
        .from('players')
        .stream(primaryKey: ['id'])
        .order('id', ascending: true) // Ensure consistent order
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
    }
  }

  /// Listen to 'properties' table for ownership changes.
  Stream<List<Map<String, dynamic>>> getPropertiesStream() {
    return _client
        .from('properties')
        .stream(primaryKey: ['tile_id'])
        .map((data) => data);
  }

  /// Update property ownership
  Future<void> upsertProperty(int tileId, String ownerId) async {
    try {
      await _client.from('properties').upsert({
        'tile_id': tileId,
        'owner_id': ownerId,
      });
    } catch (e) {
      debugPrint("Supabase Error upserting property: $e");
    }
  }

  /// Reset all players (New Game)
  Future<void> resetGame(List<Player> defaults) async {
    for (final p in defaults) {
      await upsertPlayer(p);
    }
    // Also reset properties if we had a way to clear table or set owners to null
    // For now, MVP assumes manual cleanup or persistent world.
  }
}
