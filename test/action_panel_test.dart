import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/widgets/action_panel.dart';

/// Unit tests for ActionPanel
/// TDD: Verify button states and gatekeeper-aware behavior
void main() {
  group('ActionPanel Tests', () {
    testWidgets('should display all action buttons', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: true,
              canBuyProperty: false,
              canUpgradeProperty: false,
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      // DiceGauge shows 'HOLD TO ROLL' when active
      expect(find.text('HOLD TO ROLL'), findsOneWidget);
      expect(find.text('BUY'), findsOneWidget);
      expect(find.text('UPGRADE'), findsOneWidget);
      expect(find.text('SAVE'), findsOneWidget);
      expect(find.text('LOAD'), findsOneWidget);
    });

    testWidgets('should show disabled Roll button when not player turn', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: false, // Not player's turn
              isAgentActive: true,
              canBuyProperty: false,
              canUpgradeProperty: false,
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      // Checks for the DISABLED button version
      final rollButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_roll_disabled')),
      );
      expect(rollButton.onPressed, isNull);
    });

    testWidgets('should disable all actions when agent offline', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: false, // Agent offline
              canBuyProperty: true,
              canUpgradeProperty: true,
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      final rollButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_roll_disabled')),
      );
      final buyButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_buy')),
      );
      final upgradeButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_upgrade')),
      );

      expect(rollButton.onPressed, isNull);
      expect(buyButton.onPressed, isNull);
      expect(upgradeButton.onPressed, isNull);
    });

    testWidgets('should enable buy button when on unowned property', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: true,
              canBuyProperty: true, // Can buy
              canUpgradeProperty: false,
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      final buyFinder = find.byKey(const Key('btn_buy'));
      expect(buyFinder, findsOneWidget);

      final buyButton = tester.widget<ElevatedButton>(buyFinder);
      expect(buyButton.onPressed, isNotNull);
    });

    testWidgets('should enable upgrade button when on owned property', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: true,
              canBuyProperty: false,
              canUpgradeProperty: true, // Can upgrade
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      // Verify upgrade button exists and is enabled
      final upgradeButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_upgrade')),
      );
      expect(upgradeButton.onPressed, isNotNull);
    });

    testWidgets('should show takeover button when enabled', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: true,
              canBuyProperty: false,
              canUpgradeProperty: false,
              canTakeoverProperty: true, // Enable Takeover
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      final takeoverFinder = find.byKey(const Key('btn_takeover'));
      expect(takeoverFinder, findsOneWidget);

      final takeoverButton = tester.widget<ElevatedButton>(takeoverFinder);
      expect(takeoverButton.onPressed, isNotNull);
    });

    testWidgets('should show loading state', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: true,
              canBuyProperty: false,
              canUpgradeProperty: false,
              isLoading: true, // Loading state
              onRollDice: (val) {},
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () {},
              onLoadGame: () {},
            ),
          ),
        ),
      );

      // When loading, disabled roll button should be shown instead of gauge
      final rollButton = tester.widget<ElevatedButton>(
        find.byKey(const Key('btn_roll_disabled')),
      );
      expect(rollButton.onPressed, isNull);
    });

    testWidgets('should trigger callbacks when buttons pressed', (
      WidgetTester tester,
    ) async {
      bool rollDiceCalled = false;
      bool saveGameCalled = false;
      bool loadGameCalled = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ActionPanel(
              isMyTurn: true,
              isAgentActive: true,
              canBuyProperty: false,
              canUpgradeProperty: false,
              onRollDice: (val) => rollDiceCalled = true,
              onBuyProperty: () {},
              onUpgradeProperty: () {},
              onTakeoverProperty: () {},
              onSaveGame: () => saveGameCalled = true,
              onLoadGame: () => loadGameCalled = true,
            ),
          ),
        ),
      );

      // Tap DiceGauge
      final gaugeFinder = find.byKey(const Key('gauge_roll'));
      if (gaugeFinder.evaluate().isNotEmpty) {
        // Simulate tap (down/up)
        await tester.tap(gaugeFinder);
        // DiceGauge calls onRelease on tapUp
        await tester.pumpAndSettle();
        expect(rollDiceCalled, isTrue);
      }

      // Tap save button
      await tester.tap(find.byKey(const Key('btn_save')));
      expect(saveGameCalled, isTrue);

      // Tap load button
      await tester.tap(find.byKey(const Key('btn_load')));
      expect(loadGameCalled, isTrue);
    });
  });
}
