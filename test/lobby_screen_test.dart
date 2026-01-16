import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/screens/lobby_screen.dart';
import 'package:cyber_tycoon/game/services/multiplayer_service.dart';
import 'package:mockito/mockito.dart';

class MockMultiplayerService extends Mock implements MultiplayerService {}

void main() {
  testWidgets('LobbyScreen displays generic text and labels', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    final mockMultiplayer = MockMultiplayerService();

    await tester.pumpWidget(
      MaterialApp(
        home: LobbyScreen(
          parentId: 'dummy-parent',
          childId: 'dummy-user',
          multiplayerService: mockMultiplayer,
        ),
      ),
    );

    // ASSERT
    // Verify it doesn't mention Child or Agent in common places
    expect(find.textContaining('Child'), findsNothing);
    expect(find.textContaining('Agent'), findsNothing);

    expect(find.text('CREATE ROOM'), findsOneWidget);
    expect(find.text('JOIN ROOM'), findsOneWidget);
  });
}
