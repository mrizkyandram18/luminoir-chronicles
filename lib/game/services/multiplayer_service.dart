import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/room_model.dart';

/// Service for managing multiplayer game rooms
class MultiplayerService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// Generate a random 6-character room code
  String _generateRoomCode() {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789'; // No ambiguous chars
    final random = Random();
    return List.generate(6, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Create a new game room
  /// Returns the room code on success
  Future<String> createRoom({
    required String hostChildId,
    int maxPlayers = 4,
  }) async {
    try {
      final roomCode = _generateRoomCode();

      await _supabase
          .from('game_rooms')
          .insert({
            'room_code': roomCode,
            'host_child_id': hostChildId,
            'status': 'waiting',
            'max_players': maxPlayers,
          })
          .select()
          .single();

      debugPrint("Multiplayer: Room created with code $roomCode");
      return roomCode;
    } catch (e) {
      debugPrint("Multiplayer Error creating room: $e");
      rethrow;
    }
  }

  /// Join an existing room
  /// Returns the room ID on success
  Future<String> joinRoom({
    required String roomCode,
    required String childId,
    required String playerName,
    required Color playerColor,
  }) async {
    try {
      // 1. Find room by code
      final roomResponse = await _supabase
          .from('game_rooms')
          .select()
          .eq('room_code', roomCode.toUpperCase())
          .eq('status', 'waiting')
          .single();

      final room = GameRoom.fromMap(roomResponse);

      // 2. Check if room is full
      final playersResponse = await _supabase
          .from('room_players')
          .select()
          .eq('room_id', room.id);

      if (playersResponse.length >= room.maxPlayers) {
        throw Exception('Room is full');
      }

      // 3. Add player to room
      await _supabase.from('room_players').insert({
        'room_id': room.id,
        'child_id': childId,
        'player_name': playerName,
        'player_color': playerColor.toARGB32(),
        'is_connected': true,
      });

      debugPrint("Multiplayer: $childId joined room $roomCode");
      return room.id;
    } catch (e) {
      debugPrint("Multiplayer Error joining room: $e");
      rethrow;
    }
  }

  /// Leave a room (disconnect)
  Future<void> leaveRoom({
    required String roomId,
    required String childId,
  }) async {
    try {
      // Mark player as disconnected (don't delete, for game history)
      await _supabase
          .from('room_players')
          .update({'is_connected': false})
          .eq('room_id', roomId)
          .eq('child_id', childId);

      debugPrint("Multiplayer: $childId left room $roomId");
    } catch (e) {
      debugPrint("Multiplayer Error leaving room: $e");
    }
  }

  /// Start the game (host only)
  Future<void> startGame(String roomId) async {
    try {
      // Get first player as initial turn
      final players = await _supabase
          .from('room_players')
          .select()
          .eq('room_id', roomId)
          .order('joined_at');

      if (players.isEmpty) {
        throw Exception('No players in room');
      }

      final firstPlayer = RoomPlayer.fromMap(players.first);

      await _supabase
          .from('game_rooms')
          .update({
            'status': 'playing',
            'current_turn_child_id': firstPlayer.childId,
          })
          .eq('id', roomId);

      debugPrint("Multiplayer: Game started in room $roomId");
    } catch (e) {
      debugPrint("Multiplayer Error starting game: $e");
      rethrow;
    }
  }

  /// Sync game state to Supabase (host only)
  Future<void> syncGameState({
    required String roomId,
    required Map<String, dynamic> boardState,
    required String currentTurnChildId,
  }) async {
    try {
      await _supabase
          .from('game_rooms')
          .update({
            'board_state': boardState,
            'current_turn_child_id': currentTurnChildId,
          })
          .eq('id', roomId);
    } catch (e) {
      debugPrint("Multiplayer Error syncing state: $e");
    }
  }

  /// Update player stats after action
  Future<void> updatePlayerStats({
    required String roomId,
    required String childId,
    int? position,
    int? score,
    int? credits,
  }) async {
    try {
      final updates = <String, dynamic>{
        'last_action_at': DateTime.now().toIso8601String(),
      };

      if (position != null) updates['position'] = position;
      if (score != null) updates['score'] = score;
      if (credits != null) updates['credits'] = credits;

      await _supabase
          .from('room_players')
          .update(updates)
          .eq('room_id', roomId)
          .eq('child_id', childId);
    } catch (e) {
      debugPrint("Multiplayer Error updating player stats: $e");
    }
  }

  /// Declare winner and end game
  Future<void> endGame({
    required String roomId,
    required String winnerChildId,
  }) async {
    try {
      await _supabase
          .from('game_rooms')
          .update({'status': 'finished', 'winner_child_id': winnerChildId})
          .eq('id', roomId);

      debugPrint("Multiplayer: Game ended, winner: $winnerChildId");
    } catch (e) {
      debugPrint("Multiplayer Error ending game: $e");
    }
  }

  /// Stream: Listen to room changes (realtime)
  Stream<GameRoom> getRoomStream(String roomId) {
    return _supabase
        .from('game_rooms')
        .stream(primaryKey: ['id'])
        .eq('id', roomId)
        .map((data) => GameRoom.fromMap(data.first));
  }

  /// Stream: Listen to players in room (realtime)
  Stream<List<RoomPlayer>> getPlayersStream(String roomId) {
    return _supabase
        .from('room_players')
        .stream(primaryKey: ['id'])
        .eq('room_id', roomId)
        .order('joined_at')
        .map((data) => data.map((item) => RoomPlayer.fromMap(item)).toList());
  }

  /// Get room by code (one-time fetch)
  Future<GameRoom?> getRoomByCode(String roomCode) async {
    try {
      final response = await _supabase
          .from('game_rooms')
          .select()
          .eq('room_code', roomCode.toUpperCase())
          .maybeSingle();

      if (response == null) return null;
      return GameRoom.fromMap(response);
    } catch (e) {
      debugPrint("Multiplayer Error fetching room: $e");
      return null;
    }
  }

  /// Check if player is host
  Future<bool> isHost(String roomId, String childId) async {
    try {
      final room = await _supabase
          .from('game_rooms')
          .select('host_child_id')
          .eq('id', roomId)
          .single();

      return room['host_child_id'] == childId;
    } catch (e) {
      return false;
    }
  }
}
