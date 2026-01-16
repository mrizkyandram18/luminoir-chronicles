import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/supabase_service.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_result.dart';
import 'package:cyber_tycoon/game/game_controller.dart';
import 'package:cyber_tycoon/game/models/player_model.dart';
import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';

// Manual Mocks
class MockGatekeeperService extends Mock implements GatekeeperService {
  @override
  Future<GatekeeperResult> isChildAgentActive(String parentId, String childId) {
    return super.noSuchMethod(
      Invocation.method(#isChildAgentActive, [parentId, childId]),
      returnValue: Future.value(
        const GatekeeperResult(GatekeeperResultCode.success),
      ),
      returnValueForMissingStub: Future.value(
        const GatekeeperResult(GatekeeperResultCode.success),
      ),
    );
  }
}

class MockSupabaseService extends Mock implements SupabaseService {
  @override
  Future<List<Map<String, dynamic>>> fetchPlayers() {
    return super.noSuchMethod(
      Invocation.method(#fetchPlayers, []),
      returnValue: Future.value(<Map<String, dynamic>>[]),
      returnValueForMissingStub: Future.value(<Map<String, dynamic>>[]),
    );
  }

  @override
  Future<void> upsertPlayer(Player player) {
    return super.noSuchMethod(
      Invocation.method(#upsertPlayer, [player]),
      returnValue: Future<void>.value(),
      returnValueForMissingStub: Future<void>.value(),
    );
  }

  @override
  Stream<List<Map<String, dynamic>>> getPropertiesStream() {
    return super.noSuchMethod(
      Invocation.method(#getPropertiesStream, []),
      returnValue: Stream<List<Map<String, dynamic>>>.empty(),
      returnValueForMissingStub: Stream<List<Map<String, dynamic>>>.empty(),
    );
  }
}

void main() {
  group('GameController Integration Logic Tests', () {
    test('GameController should sync with Firebase & Supabase', () async {
      // ---------------------------------------------------
      // 1. ARRANGE (Setup Mocks)
      // ---------------------------------------------------
      final mockGatekeeper = MockGatekeeperService();
      final mockSupabase = MockSupabaseService();

      // STUB: Gatekeeper returns SUCCESS (Agent Active)
      when(
        mockGatekeeper.isChildAgentActive('demoparent', 'child1'),
      ).thenAnswer(
        (_) async => const GatekeeperResult(GatekeeperResultCode.success),
      );

      // STUB: Supabase fetchPlayers returns a test player
      when(mockSupabase.fetchPlayers()).thenAnswer(
        (_) async => [
          {
            'id': 'p1',
            'name': 'Tester',
            'color_value': Colors.blue.value,
            'position': 0,
            'score': 100,
            'credits': 500,
            'score_multiplier': 1,
            'is_human': true,
          },
        ],
      );

      // STUB: Supabase upsertPlayer (No-op, just verify call)
      when(mockSupabase.upsertPlayer(any)).thenAnswer((_) async {});

      // ---------------------------------------------------
      // 2. ACT (Initialize Controller & Load Game)
      // ---------------------------------------------------
      final gameController = GameController(
        mockGatekeeper,
        supabaseService: mockSupabase,
        parentId: 'demoparent',
        childId: 'child1',
      );

      // Wait for async initialization
      await Future.delayed(const Duration(milliseconds: 100));

      // VERIFY: Players loaded from Supabase Mock
      expect(gameController.players.length, 1);
      expect(gameController.players.first.name, 'Tester');
      // ✅ Supabase Sync Verified: Player data loaded.

      // ---------------------------------------------------
      // 3. ACTION (Gatekeeper Check Phase)
      // ---------------------------------------------------
      await gameController.rollDice();

      // VERIFY: Gatekeeper Checked
      verify(
        mockGatekeeper.isChildAgentActive('demoparent', 'child1'),
      ).called(1);
      // ✅ Firebase Gatekeeper Verified: Check performed on action.

      // VERIFY: Player state updated to Supabase (upsert)
      verify(mockSupabase.upsertPlayer(any)).called(1);
      // ✅ Supabase Sync Verified: Player state saved after action.
    });
  });
}
