import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/game_controller.dart';
import 'package:cyber_tycoon/game/services/leaderboard_service.dart';
import 'package:cyber_tycoon/game/services/multiplayer_service.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_result.dart';
import 'package:cyber_tycoon/game/supabase_service.dart';
import 'package:cyber_tycoon/game/models/player_model.dart';
import 'package:cyber_tycoon/game/models/room_model.dart';

// Manual Mocks
class MockGatekeeper extends Fake implements GatekeeperService {
  @override
  Future<GatekeeperResult> isChildAgentActive(
    String parentId,
    String childId,
  ) async {
    return const GatekeeperResult(GatekeeperResultCode.success);
  }
}

class BetterMockSupabase extends Fake implements SupabaseService {
  final _playerStreamController = StreamController<List<Player>>.broadcast();
  final _propStreamController =
      StreamController<List<Map<String, dynamic>>>.broadcast();
  int upsertPlayerCallCount = 0;
  int recordMatchResultCallCount = 0;

  @override
  Stream<List<Player>> getPlayersStream() => _playerStreamController.stream;

  @override
  Stream<List<Map<String, dynamic>>> getPropertiesStream() =>
      _propStreamController.stream;

  @override
  Future<void> initializeDefaultPlayersIfNeeded(List<Player> defaults) async {}

  @override
  Future<void> saveGameState(int currentPlayerIndex) async {}

  @override
  Future<void> upsertPlayer(Player p) async {
    upsertPlayerCallCount++;
  }

  @override
  Future<void> recordMatchResult(Map<String, dynamic> data) async {
    recordMatchResultCallCount++;
  }

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
}

class MockLeaderboardService extends Fake implements LeaderboardService {
  int updateCallCount = 0;
  int updateRankCallCount = 0;
  String? lastPlayerId;
  bool? lastWon;
  bool? lastIsRanked;

  @override
  Future<void> updatePlayerStats(Player player) async {
    updateCallCount++;
  }

  @override
  Future<void> updateRankAfterMatch({
    required String playerId,
    required bool won,
    required bool isRankedMode,
  }) async {
    updateRankCallCount++;
    lastPlayerId = playerId;
    lastWon = won;
    lastIsRanked = isRankedMode;
  }
}

class MockMultiplayerService extends Fake implements MultiplayerService {
  @override
  Stream<GameRoom> getRoomStream(String roomId) => Stream.empty();

  @override
  Stream<List<RoomPlayer>> getPlayersStream(String roomId) => Stream.value([]);
}

void main() {
  late GameController controller;
  late MockGatekeeper gatekeeper;
  late BetterMockSupabase supabase;
  late MockLeaderboardService leaderboard;
  late MockMultiplayerService multiplayer;

  setUp(() {
    gatekeeper = MockGatekeeper();
    supabase = BetterMockSupabase();
    leaderboard = MockLeaderboardService();
    multiplayer = MockMultiplayerService();
  });

  tearDown(() {
    controller.dispose();
  });

  test('GameMode defaults to Practice and does NOT sync stats', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    expect(controller.gameMode, GameMode.practice);

    // Trigger Save
    await controller.saveGame();

    // check leaderboard update count
    expect(leaderboard.updateCallCount, 0);
  });

  test('Ranked Mode syncs stats on Autosave', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      gameMode: GameMode.ranked,
    );

    expect(controller.gameMode, GameMode.ranked);

    // Trigger Autosave
    await controller.autosave();

    // In Ranked mode, autosaves should sync stats for human players
    expect(leaderboard.updateCallCount, greaterThan(0));
  });

  test('Autosave does not sync stats in Practice mode on end turn', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    await controller.rollDice(gaugeValue: 0.5);
    expect(controller.canEndTurn, isTrue);

    controller.endTurn();

    expect(leaderboard.updateCallCount, 0);
  });

  test('End turn autosaves only in Ranked mode', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      gameMode: GameMode.ranked,
    );

    await controller.rollDice(gaugeValue: 0.5);
    expect(controller.canEndTurn, isTrue);

    final initialCalls = leaderboard.updateCallCount;

    controller.endTurn();

    expect(leaderboard.updateCallCount, greaterThan(initialCalls));
  });

  test('Practice mode does NOT update rank on game end', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    expect(controller.gameMode, GameMode.practice);
    expect(controller.matchEnded, false);

    await controller.endGame(winnerId: 'child');

    expect(controller.matchEnded, true);
    expect(leaderboard.updateRankCallCount, 0);
  });

  test('Ranked mode updates rank on game end', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      gameMode: GameMode.ranked,
    );

    expect(controller.gameMode, GameMode.ranked);

    await controller.endGame(winnerId: 'child');

    expect(controller.matchEnded, true);
    expect(leaderboard.updateRankCallCount, 1);
    expect(leaderboard.lastPlayerId, 'child');
    expect(leaderboard.lastWon, true);
    expect(leaderboard.lastIsRanked, true);
  });

  test('Cannot save after match ended', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    await controller.endGame(winnerId: 'child');
    expect(controller.matchEnded, true);

    await controller.saveGame();
    expect(controller.lastEffectMessage, contains('Match already ended'));
  });

  test('Practice mode never persists to Supabase', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    await controller.rollDice(gaugeValue: 0.5);
    await controller.saveGame();
    await controller.endGame(winnerId: 'child');

    expect(supabase.upsertPlayerCallCount, 0);
    expect(supabase.recordMatchResultCallCount, 0);
  });

  test('Ranked mode persists match results to Supabase', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      gameMode: GameMode.ranked,
    );

    await controller.endGame(winnerId: 'child');

    expect(supabase.recordMatchResultCallCount, 1);
  });

  test('Cannot load after match ended', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    await controller.endGame(winnerId: 'child');
    expect(controller.matchEnded, true);

    await controller.loadGame();
    expect(controller.lastEffectMessage, contains('Match already ended'));
  });

  test('Autosave does not run after match ended', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: false,
    );

    await controller.endGame(winnerId: 'child');
    final initialCallCount = supabase.upsertPlayerCallCount;

    await controller.autosave();

    expect(supabase.upsertPlayerCallCount, initialCallCount);
  });
}
