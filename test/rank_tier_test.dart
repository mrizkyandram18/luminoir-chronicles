import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/models/rank_tier.dart';

void main() {
  group('RankTier', () {
    test('Bronze tier has correct name and points', () {
      expect(RankTier.bronze.name, 'Script Kiddie');
      expect(RankTier.bronze.minPoints, 0);
      expect(RankTier.bronze.maxPoints, 499);
    });

    test('Silver tier has correct name and points', () {
      expect(RankTier.silver.name, 'Netrunner');
      expect(RankTier.silver.minPoints, 500);
      expect(RankTier.silver.maxPoints, 1499);
    });

    test('Gold tier has correct name and points', () {
      expect(RankTier.gold.name, 'Cyber Lord');
      expect(RankTier.gold.minPoints, 1500);
      expect(RankTier.gold.maxPoints, 2999);
    });

    test('CyberElite tier has correct name and points', () {
      expect(RankTier.cyberElite.name, 'Ghost in the Machine');
      expect(RankTier.cyberElite.minPoints, 3000);
      expect(RankTier.cyberElite.maxPoints, 999999);
    });

    test('rankTierFromPoints returns correct tier', () {
      expect(rankTierFromPoints(0), RankTier.bronze);
      expect(rankTierFromPoints(250), RankTier.bronze);
      expect(rankTierFromPoints(500), RankTier.silver);
      expect(rankTierFromPoints(1000), RankTier.silver);
      expect(rankTierFromPoints(1500), RankTier.gold);
      expect(rankTierFromPoints(2500), RankTier.gold);
      expect(rankTierFromPoints(3000), RankTier.cyberElite);
      expect(rankTierFromPoints(5000), RankTier.cyberElite);
    });
  });
}
