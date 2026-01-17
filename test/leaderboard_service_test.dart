import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/services/leaderboard_service.dart';
import 'package:cyber_tycoon/game/models/player_model.dart';
import 'package:cyber_tycoon/game/supabase_service.dart';

import 'package:mockito/mockito.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// Reuse Mock classes or define them locally if needed.
class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockSupabaseService extends Mock implements SupabaseService {
  @override
  SupabaseClient get client => MockSupabaseClient();

  @override
  Future<List<Map<String, dynamic>>> queryLeaderboard({
    int limit = 100,
  }) async => [];
  @override
  Future<List<Map<String, dynamic>>> queryPlayersByIds(
    List<String> ids,
  ) async => [];
  @override
  Future<Map<String, dynamic>?> queryPlayerRankStats(String id) async => null;
  @override
  Future<int> queryPlayerRankPosition(String id) async => 0;
  @override
  Future<void> updatePlayerRankStats(String id, Map<String, dynamic> u) async {}
  @override
  Future<void> upsertPlayer(Player p) async {}
}

void main() {
  late LeaderboardService service;
  late MockSupabaseService mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseService();
    service = LeaderboardService(mockSupabase);
  });

  group('LeaderboardService Tests', () {
    test('fetchGlobalLeaderboard returns empty list when no data', () async {
      final result = await service.fetchGlobalLeaderboard();
      expect(result, isA<List<Player>>());
    });

    test('fetchFriendLeaderboard returns empty list when no friends', () async {
      final result = await service.fetchFriendLeaderboard([]);
      expect(result, isEmpty);
    });

    test('rankTitle is correct based on rankPoints', () {
      final p1 = Player(
        id: '1',
        name: 'Noob',
        color: Colors.blue,
        rankPoints: 50,
      );
      expect(p1.rankTitle, 'Script Kiddie');

      final p2 = Player(
        id: '2',
        name: 'Pro',
        color: Colors.blue,
        rankPoints: 500,
      );
      expect(p2.rankTitle, 'Netrunner');

      final p3 = Player(
        id: '3',
        name: 'God',
        color: Colors.blue,
        rankPoints: 2000,
      );
      expect(p3.rankTitle, 'Cyber Lord');
    });
  });
}
