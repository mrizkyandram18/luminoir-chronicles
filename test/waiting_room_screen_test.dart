import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_raid/game/screens/waiting_room_screen.dart';
import 'package:cyber_raid/game/services/multiplayer_service.dart';
import 'package:cyber_raid/game/models/room_model.dart';
import 'package:mockito/mockito.dart';

class MockMultiplayerService extends Mock implements MultiplayerService {
  @override
  Stream<GameRoom> getRoomStream(String roomId) {
    return super.noSuchMethod(
      Invocation.method(#getRoomStream, [roomId]),
      returnValue: Stream<GameRoom>.empty(),
      returnValueForMissingStub: Stream<GameRoom>.empty(),
    );
  }

  @override
  Stream<List<RoomPlayer>> getPlayersStream(String roomId) {
    return super.noSuchMethod(
      Invocation.method(#getPlayersStream, [roomId]),
      returnValue: Stream<List<RoomPlayer>>.empty(),
      returnValueForMissingStub: Stream<List<RoomPlayer>>.empty(),
    );
  }
}

void main() {
  testWidgets('WaitingRoomScreen displays generic labels', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    final mockMultiplayer = MockMultiplayerService();

    // Stub streams to return empty streams with correct types to avoid TypeError
    when(
      mockMultiplayer.getRoomStream('room-123'),
    ).thenAnswer((_) => Stream<GameRoom>.empty());
    when(
      mockMultiplayer.getPlayersStream('room-123'),
    ).thenAnswer((_) => Stream<List<RoomPlayer>>.empty());

    await tester.pumpWidget(
      MaterialApp(
        home: WaitingRoomScreen(
          roomId: 'room-123',
          roomCode: 'ABC123',
          childId: 'user-456',
          isHost: true,
          multiplayerService: mockMultiplayer,
        ),
      ),
    );

    // ASSERT
    // Verify no Child Agent mentions
    expect(find.textContaining('Child'), findsNothing);
    expect(find.textContaining('Agent'), findsNothing);

    // Verify general info
    expect(find.text('ROOM CODE'), findsOneWidget);
    expect(find.text('ABC123'), findsOneWidget);
    expect(find.text('PLAYERS'), findsOneWidget);
  });
}
