import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/models/match_result.dart';

void main() {
  group('MatchResult', () {
    test('toMap includes all fields', () {
      final result = MatchResult(
        matchId: 'match_123',
        playerId: 'player_456',
        won: true,
        isRanked: true,
        completedAt: DateTime(2024, 1, 1),
        finalScore: 1000,
        finalCredits: 500,
      );

      final map = result.toMap();
      expect(map['match_id'], 'match_123');
      expect(map['player_id'], 'player_456');
      expect(map['won'], true);
      expect(map['is_ranked'], true);
      expect(map['final_score'], 1000);
      expect(map['final_credits'], 500);
    });

    test('fromMap creates correct MatchResult', () {
      final map = {
        'match_id': 'match_123',
        'player_id': 'player_456',
        'won': false,
        'is_ranked': true,
        'completed_at': '2024-01-01T00:00:00.000Z',
        'final_score': 500,
        'final_credits': 200,
      };

      final result = MatchResult.fromMap(map);
      expect(result.matchId, 'match_123');
      expect(result.playerId, 'player_456');
      expect(result.won, false);
      expect(result.isRanked, true);
      expect(result.finalScore, 500);
      expect(result.finalCredits, 200);
    });
  });
}
