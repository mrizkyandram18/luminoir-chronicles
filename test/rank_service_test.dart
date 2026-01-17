import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/services/rank_service.dart';
import 'package:cyber_tycoon/game/models/rank_tier.dart';

void main() {
  group('RankService', () {
    test('calculateTier returns Bronze for low points', () {
      expect(RankService.calculateTier(0), RankTier.bronze);
      expect(RankService.calculateTier(499), RankTier.bronze);
    });

    test('calculateTier returns Silver for medium points', () {
      expect(RankService.calculateTier(500), RankTier.silver);
      expect(RankService.calculateTier(1499), RankTier.silver);
    });

    test('calculateTier returns Gold for high points', () {
      expect(RankService.calculateTier(1500), RankTier.gold);
      expect(RankService.calculateTier(2999), RankTier.gold);
    });

    test('calculateTier returns CyberElite for very high points', () {
      expect(RankService.calculateTier(3000), RankTier.cyberElite);
      expect(RankService.calculateTier(10000), RankTier.cyberElite);
    });

    test('calculateNewRankPoints increases on win', () {
      final newPoints = RankService.calculateNewRankPoints(100, true);
      expect(newPoints, 150);
    });

    test('calculateNewRankPoints decreases on loss', () {
      final newPoints = RankService.calculateNewRankPoints(100, false);
      expect(newPoints, 75);
    });

    test('calculateNewRankPoints never goes below zero', () {
      final newPoints = RankService.calculateNewRankPoints(0, false);
      expect(newPoints, 0);
    });

    test('shouldUpdateRank returns true only for ranked human players', () {
      expect(RankService.shouldUpdateRank(true, true), true);
      expect(RankService.shouldUpdateRank(true, false), false);
      expect(RankService.shouldUpdateRank(false, true), false);
      expect(RankService.shouldUpdateRank(false, false), false);
    });
  });
}
