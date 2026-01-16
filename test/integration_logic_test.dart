import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:cyber_tycoon/game/game_controller.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';
import 'package:cyber_tycoon/game/supabase_service.dart';
import 'package:cyber_tycoon/game/models/player_model.dart';

// Generate mocks - DISABLED due to build_runner timeouts
// @GenerateMocks([GatekeeperService, SupabaseService])
// import 'integration_logic_test.mocks.dart';

// Manual Mocks
class MockGatekeeperService extends Mock implements GatekeeperService {
  @override
  Future<bool> isChildAgentActive(String? parentId, String? childId) {
    return super.noSuchMethod(
      Invocation.method(#isChildAgentActive, [parentId, childId]),
      returnValue: Future.value(false),
      returnValueForMissingStub: Future.value(false),
    );
  }
}

class MockSupabaseService extends Mock implements SupabaseService {
  @override
  Stream<List<Player>> getPlayersStream() {
    return super.noSuchMethod(
      Invocation.method(#getPlayersStream, []),
      returnValue: Stream<List<Player>>.empty(),
      returnValueForMissingStub: Stream<List<Player>>.empty(),
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

  @override
  Future<void> initializeDefaultPlayersIfNeeded(List<Player>? players) {
    return super.noSuchMethod(
      Invocation.method(#initializeDefaultPlayersIfNeeded, [players]),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }

  @override
  Future<void> upsertPlayer(Player? player) {
    return super.noSuchMethod(
      Invocation.method(#upsertPlayer, [player]),
      returnValue: Future.value(),
      returnValueForMissingStub: Future.value(),
    );
  }
}

void main() {
  late MockGatekeeperService mockGatekeeper;
  late MockSupabaseService mockSupabase;
  late GameController gameController;

  setUp(() {
    mockGatekeeper = MockGatekeeperService();
    mockSupabase = MockSupabaseService();
  });

  test('VERIFY: Child Agent Login (Firebase) & Data Sync (Supabase)', () async {
    // ---------------------------------------------------
    // 1. MOCK SETUP (Simulating "Real" Connections)
    // ---------------------------------------------------

    // FIREBASE: Gatekeeper says "Active" (lastSeen < 5 mins)
    when(
      mockGatekeeper.isChildAgentActive(any, any),
    ).thenAnswer((_) async => true);

    // SUPABASE: Returns a valid player list stream
    final mockPlayers = [
      Player(id: 'p1', name: 'Tester', color: Colors.blue, credits: 1500),
    ];
    when(
      mockSupabase.getPlayersStream(),
    ).thenAnswer((_) => Stream.value(mockPlayers));

    // SUPABASE: Returns empty properties stream
    when(
      mockSupabase.getPropertiesStream(),
    ).thenAnswer((_) => Stream.value([]));

    // SUPABASE: Initialization calls
    when(
      mockSupabase.initializeDefaultPlayersIfNeeded(any),
    ).thenAnswer((_) async {});

    when(mockSupabase.upsertPlayer(any)).thenAnswer((_) async {});

    // ---------------------------------------------------
    // 2. INITIALIZATION (Login Phase)
    // ---------------------------------------------------
    gameController = GameController(
      mockGatekeeper,
      parentId: 'demoparent',
      childId: 'child1',
      supabaseService: mockSupabase, // INJECTED MOCK
    );

    // Allow stream to emit
    await Future.delayed(Duration.zero);

    // VERIFY: Players loaded from Supabase Mock
    expect(gameController.players.length, 1);
    expect(gameController.players.first.name, 'Tester');
    print("✅ Supabase Sync Verified: Player data loaded.");

    // ---------------------------------------------------
    // 3. ACTION (Gatekeeper Check Phase)
    // ---------------------------------------------------

    // ACT: Try to Roll Dice
    await gameController.rollDice();

    // VERIFY: Gatekeeper Checked
    verify(mockGatekeeper.isChildAgentActive('demoparent', 'child1')).called(1);
    print("✅ Firebase Gatekeeper Verified: Check performed on action.");

    // VERIFY: Player state updated to Supabase (upsert)
    verify(mockSupabase.upsertPlayer(any)).called(1);
    print("✅ Supabase Sync Verified: Player state saved after action.");
  });
}
