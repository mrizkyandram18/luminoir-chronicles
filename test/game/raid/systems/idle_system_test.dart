import 'package:flutter_test/flutter_test.dart';
import 'package:luminoir_chronicles/game/raid/systems/idle_system.dart';

void main() {
  group('IdleRewardSystem Tests', () {
    late IdleRewardSystem system;

    setUp(() {
      system = IdleRewardSystem();
    });

    test('Should return 0 gold for idle time <= 60 seconds', () {
      final now = DateTime.now();
      final lastLogin = now.subtract(const Duration(seconds: 59));
      
      final gold = system.calculateIdleGold(
        lastLogin: lastLogin,
        maxStage: 1,
        now: now,
      );

      expect(gold, 0);
    });

    test('Should calculate correct gold for 1 hour at stage 1', () {
      final now = DateTime.now();
      final lastLogin = now.subtract(const Duration(hours: 1));
      // Stage 1 Formula: 1 + (1^1.2 * 0.5) = 1.5 gold/sec
      // 3600 sec * 1.5 = 5400 gold
      
      final gold = system.calculateIdleGold(
        lastLogin: lastLogin,
        maxStage: 1,
        now: now,
      );

      expect(gold, 5400);
    });

    test('Should cap reward at 24 hours', () {
      final now = DateTime.now();
      final lastLogin = now.subtract(const Duration(hours: 25));
      // Should calculate for 24 hours (86400 seconds)
      // Stage 1: 86400 * 1.5 = 129600
      
      final gold = system.calculateIdleGold(
        lastLogin: lastLogin,
        maxStage: 1,
        now: now,
      );

      expect(gold, 129600);
    });

    test('Should scale with higher stages', () {
      final now = DateTime.now();
      final lastLogin = now.subtract(const Duration(hours: 1));
      // Stage 10 Formula: 1 + (10^1.2 * 0.5)
      // 10^1.2 approx 15.8489
      // 1 + 7.924 = 8.924 gold/sec
      // 3600 * 8.924 approx 32127.8
      
      final gold = system.calculateIdleGold(
        lastLogin: lastLogin,
        maxStage: 10,
        now: now,
      );

      expect(gold, closeTo(32128, 5)); 
    });
  });
}
