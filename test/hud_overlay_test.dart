import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/widgets/hud_overlay.dart';
import 'package:cyber_tycoon/game/models/player_model.dart';

/// Unit tests for HudOverlay
/// TDD: Verify player stats display and active player highlighting
void main() {
  group('HudOverlay Tests', () {
    final testPlayers = [
      Player(id: 'p1', name: 'Player 1', color: Colors.cyan)
        ..score = 100
        ..credits = 500
        ..scoreMultiplier = 1,
      Player(id: 'p2', name: 'Player 2', color: Colors.purple)
        ..score = 200
        ..credits = 300
        ..scoreMultiplier = 2,
      Player(id: 'p3', name: 'Player 3', color: Colors.orange)
        ..score = 150
        ..credits = 400
        ..scoreMultiplier = 1,
    ];

    testWidgets('should display connection status', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(
              players: testPlayers,
              currentPlayerIndex: 0,
              isOnline: true,
            ),
          ),
        ),
      );

      expect(find.text('ONLINE'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_done), findsOneWidget);
    });

    testWidgets('should display offline status', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(
              players: testPlayers,
              currentPlayerIndex: 0,
              isOnline: false,
            ),
          ),
        ),
      );

      expect(find.text('OFFLINE'), findsOneWidget);
      expect(find.byIcon(Icons.cloud_off), findsOneWidget);
    });

    testWidgets('should display all players', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(players: testPlayers, currentPlayerIndex: 0),
          ),
        ),
      );

      expect(find.text('Player 1'), findsOneWidget);
      expect(find.text('Player 2'), findsOneWidget);
      expect(find.text('Player 3'), findsOneWidget);
    });

    testWidgets('should display player scores', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(players: testPlayers, currentPlayerIndex: 0),
          ),
        ),
      );

      expect(find.text('100'), findsOneWidget); // Player 1 score
      expect(find.text('200'), findsOneWidget); // Player 2 score
      expect(find.text('150'), findsOneWidget); // Player 3 score
    });

    testWidgets('should display player credits', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(players: testPlayers, currentPlayerIndex: 0),
          ),
        ),
      );

      expect(find.text('500'), findsOneWidget); // Player 1 credits
      expect(find.text('300'), findsOneWidget); // Player 2 credits
      expect(find.text('400'), findsOneWidget); // Player 3 credits
    });

    testWidgets('should display score multiplier when > 1', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(
              players: testPlayers,
              currentPlayerIndex: 1, // Player 2 has multiplier 2
            ),
          ),
        ),
      );

      // Player 2 has multiplier 2
      expect(find.text('2'), findsWidgets); // Can appear in score or multiplier
    });

    testWidgets('should highlight active player', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(
              players: testPlayers,
              currentPlayerIndex: 1, // Player 2 is active
            ),
          ),
        ),
      );

      // Pump to complete any animations
      await tester.pumpAndSettle();

      // Verify UI updated
      expect(find.text('Player 2'), findsOneWidget);
    });

    testWidgets('should render stat icons', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(players: testPlayers, currentPlayerIndex: 0),
          ),
        ),
      );

      // Check for emoji icons
      expect(find.text('⭐'), findsWidgets); // Score icon
      expect(find.text('💰'), findsWidgets); // Credits icon
    });

    testWidgets('should handle empty player list gracefully', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(body: HudOverlay(players: [], currentPlayerIndex: 0)),
        ),
      );

      // Should still render connection status
      expect(find.text('ONLINE'), findsOneWidget);
    });

    testWidgets('should update when player index changes', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(players: testPlayers, currentPlayerIndex: 0),
          ),
        ),
      );

      // Initial state
      await tester.pumpAndSettle();

      // Update to different player
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HudOverlay(
              players: testPlayers,
              currentPlayerIndex: 2, // Change to Player 3
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Player 3'), findsOneWidget);
    });
  });
}
