import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/services/leaderboard_service.dart';
import 'package:cyber_tycoon/game/models/player_model.dart';
import 'package:cyber_tycoon/game/supabase_service.dart';

// Manual Mock
class MockSupabaseService implements SupabaseService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LeaderboardService service;
  late MockSupabaseService mockSupabase;

  setUp(() {
    mockSupabase = MockSupabaseService();
    // Use mock mode to avoid needing real Supabase mocking
    service = LeaderboardService(mockSupabase, useMock: true);
  });

  group('LeaderboardService Tests', () {
    test('fetchGlobalLeaderboard returns mocked data', () async {
      final result = await service.fetchGlobalLeaderboard();
      expect(result.length, 10);
      expect(
        result.first.rankPoints,
        greaterThanOrEqualTo(result.last.rankPoints),
      );
    });

    test('fetchFriendLeaderboard returns stats', () async {
      final result = await service.fetchFriendLeaderboard(['p1']);
      expect(result, isNotEmpty);
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
