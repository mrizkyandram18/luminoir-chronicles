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
  Future<void> upsertPlayer(Player p) async {}

  @override
  Future<void> upsertProperty(int t, String o, int l) async {}
}

class MockLeaderboardService extends Fake implements LeaderboardService {
  int updateCallCount = 0;

  @override
  Future<void> updatePlayerStats(Player player) async {
    updateCallCount++;
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

  test('Ranked Mode syncs stats on Save', () async {
    controller = GameController(
      gatekeeper,
      parentId: 'parent',
      childId: 'child',
      supabaseService: supabase,
      leaderboardService: leaderboard,
      multiplayerService: multiplayer,
      isMultiplayer: true,
    );

    expect(controller.gameMode, GameMode.ranked);

    // Trigger Save
    await controller.saveGame();

    // In Ranked mode, saves should sync stats for human players
    expect(leaderboard.updateCallCount, greaterThan(0));
  });
}
