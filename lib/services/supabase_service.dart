import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class SupabaseService {
  final SupabaseClient _client = Supabase.instance.client;
  SupabaseClient get client => _client;

  // --- Realtime Channels ---
  RealtimeChannel? _gameChannel;

  /// Joins a Raid Room and listens for updates
  Future<void> joinRaidRoom(
    String roomId,
    Function(Map<String, dynamic>) onPayload,
  ) async {
    _gameChannel = _client.channel('public:raid_rooms:id=eq.$roomId');

    _gameChannel!
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'raid_rooms',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: roomId,
          ),
          callback: (payload) {
            onPayload({'type': 'room_update', 'data': payload.newRecord});
          },
        )
        .onBroadcast(
          event: 'player_action',
          callback: (payload) {
            onPayload({'type': 'player_action', 'data': payload});
          },
        )
        .subscribe();

    debugPrint("Joined Raid Room: $roomId");
  }

  /// Broadcasts an attack (CLIENT-SIDE PREDICTION preferred, but we broadcast for others)
  Future<void> broadcastAttack(
    String roomId,
    String playerId,
    int damage,
  ) async {
    // We use broadcast for high-frequency low-criticality (visuals)
    // But for actual HP, we might want to update the DB periodically or use an Edge Function.
    // For this prototype, we'll trust the client with the "Host" authority or shared authority.
    // Let's use Broadcast for "I hit the boss" so everyone sees numbers.

    await _gameChannel?.sendBroadcastMessage(
      event: 'player_action',
      payload: {'action': 'attack', 'playerId': playerId, 'damage': damage},
    );
  }

  /// Syncs vital stats to DB (Heartbeat style, every few seconds)
  Future<void> updatePlayerStats(
    String roomId,
    String playerId,
    Map<String, dynamic> stats,
  ) async {
    await _client.from('raid_players').upsert({
      'room_id': roomId,
      'player_id': playerId,
      'stats': stats,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Checks if a player profile exists
  Future<Map<String, dynamic>?> getPlayerProfile(String playerId) async {
    try {
      final response = await _client
          .from('raid_players')
          .select()
          .eq('player_id', playerId)
          .eq('room_id', 'global_raid_room') // Persistent room
          .maybeSingle();
      return response;
    } catch (e) {
      debugPrint("Error fetching profile: $e");
      return null;
    }
  }

  /// Creates a new player profile
  Future<void> createPlayerProfile(
    String playerId,
    String name,
    String job,
  ) async {
    // Initial Stats based on Job (Simplified, controller will handle full logic usually,
    // but here we just init the record)
    await _client.from('raid_players').upsert({
      'player_id': playerId,
      'room_id': 'global_raid_room',
      'stats': {
        'name': name,
        'job': job,
        'level': 1,
        'gold': 0,
        'attack_bonus': 0, // Manual upgrades
        'party': [
          {
            'name': name,
            'job': job,
            'level': 1,
            'slot': 0,
          },
        ],
        // Base stats are calculated in code based on level/job to avoid desync
      },
      'updated_at': DateTime.now().toIso8601String(),
    });
  }

  /// Adds or replaces a hero in the player's party (by slot index)
  Future<void> addPartyMember({
    required String playerId,
    required Map<String, dynamic> hero,
  }) async {
    final profile = await getPlayerProfile(playerId);
    if (profile == null) return;

    final stats =
        (profile['stats'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v)) ??
            <String, dynamic>{};

    final List<dynamic> party =
        (stats['party'] as List<dynamic>?)?.toList() ?? <dynamic>[];

    final int slot = (hero['slot'] as int?) ?? party.length;
    final heroWithSlot = Map<String, dynamic>.from(hero)..['slot'] = slot;

    bool replaced = false;

    for (var i = 0; i < party.length; i++) {
      final item = party[i];
      if (item is Map<String, dynamic>) {
        final existingSlot = item['slot'] as int?;
        if (existingSlot == slot) {
          party[i] = heroWithSlot;
          replaced = true;
          break;
        }
      }
    }

    if (!replaced) {
      party.add(heroWithSlot);
    }

    stats['party'] = party;

    await _client
        .from('raid_players')
        .update({'stats': stats}).eq('player_id', playerId).eq('room_id', 'global_raid_room');
  }

  Future<void> swapPartySlots({
    required String playerId,
    required int fromSlot,
    required int toSlot,
  }) async {
    if (fromSlot == toSlot) return;

    final profile = await getPlayerProfile(playerId);
    if (profile == null) return;

    final stats =
        (profile['stats'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v)) ??
            <String, dynamic>{};

    final List<dynamic> party =
        (stats['party'] as List<dynamic>?)?.toList() ?? <dynamic>[];

    int fromIndex = -1;
    int toIndex = -1;

    for (var i = 0; i < party.length; i++) {
      final item = party[i];
      if (item is Map<String, dynamic>) {
        final slot = item['slot'] as int?;
        if (slot == fromSlot) {
          fromIndex = i;
        } else if (slot == toSlot) {
          toIndex = i;
        }
      }
    }

    if (fromIndex == -1) return;

    final fromHero = Map<String, dynamic>.from(
      party[fromIndex] as Map<String, dynamic>,
    );

    if (toIndex == -1) {
      fromHero['slot'] = toSlot;
      party[fromIndex] = fromHero;
    } else {
      final toHero = Map<String, dynamic>.from(
        party[toIndex] as Map<String, dynamic>,
      );
      fromHero['slot'] = toSlot;
      toHero['slot'] = fromSlot;
      party[fromIndex] = toHero;
      party[toIndex] = fromHero;
    }

    stats['party'] = party;

    await _client
        .from('raid_players')
        .update({'stats': stats}).eq('player_id', playerId).eq('room_id', 'global_raid_room');
  }

  Future<void> updatePlayerProfileCustomization(
    String playerId, {
    required String avatarId,
    required String frameId,
    Map<String, dynamic>? settings,
  }) async {
    final profile = await getPlayerProfile(playerId);
    if (profile == null) {
      return;
    }

    final stats =
        (profile['stats'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k.toString(), v)) ??
            <String, dynamic>{};

    stats['avatar_id'] = avatarId;
    stats['frame_id'] = frameId;
    if (settings != null) {
      stats['settings'] = settings;
    }

    await _client
        .from('raid_players')
        .update({'stats': stats}).eq('player_id', playerId).eq('room_id', 'global_raid_room');
  }

  Future<void> sendChatMessage({
    required String channel,
    required String senderId,
    String? targetId,
    required String content,
  }) async {
    await _client.from('chat_messages').insert({
      'channel': channel,
      'sender_id': senderId,
      'target_id': targetId,
      'content': content,
    });
  }

  Stream<List<Map<String, dynamic>>> worldChatStream() {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel', 'world')
        .order('created_at');
  }

  Stream<List<Map<String, dynamic>>> privateChatStream(String playerId) {
    return _client
        .from('chat_messages')
        .stream(primaryKey: ['id'])
        .eq('channel', 'private')
        .order('created_at');
  }

  /// The "Host" (Player 1) updates the Boss HP in DB
  Future<void> updateBossState(String roomId, int wave, double hp) async {
    await _client
        .from('raid_rooms')
        .update({'wave': wave, 'boss_hp': hp})
        .eq('id', roomId);
  }

  /// Reset or Create Room
  Future<void> createOrResetRoom(String roomId) async {
    // Check if exists
    final exists = await _client
        .from('raid_rooms')
        .select()
        .eq('id', roomId)
        .maybeSingle();

    if (exists == null) {
      await _client.from('raid_rooms').insert({
        'id': roomId,
        'wave': 1,
        'boss_hp': 1000,
      });
    }
  }

  /// Updates the Last Active timestamp for Offline Calculation
  Future<void> updateLastActive(String playerId) async {
    await _client
        .from('raid_players')
        .update({'updated_at': DateTime.now().toIso8601String()})
        .eq('player_id', playerId);
  }

  void leaveRoom() {
    _client.removeAllChannels();
  }
}
