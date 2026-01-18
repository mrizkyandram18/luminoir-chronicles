// import 'package:flutter/material.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:cyber_raid/game/widgets/action_panel.dart';

// /// Unit tests for ActionPanel
// /// TDD: Verify button states and gatekeeper-aware behavior
// void main() {
//   group('ActionPanel Tests', () {
//     testWidgets('should display all action buttons', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       // DiceGauge shows 'HOLD TO ROLL' when active
//       expect(find.text('HOLD TO ROLL'), findsOneWidget);
//       expect(find.text('BUY'), findsOneWidget);
//       expect(find.text('UPGRADE'), findsOneWidget);
//     });

//     testWidgets('should show disabled Roll button when not player turn', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: false,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               rollDisabledReason: 'Not Your Turn',
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       // Checks for the DISABLED button version
//       final rollButton = tester.widget<ElevatedButton>(
//         find.byKey(const Key('btn_roll_disabled')),
//       );
//       expect(rollButton.onPressed, isNull);

//       final rollTooltip = tester.widget<Tooltip>(
//         find.ancestor(
//           of: find.byKey(const Key('btn_roll_disabled')),
//           matching: find.byType(Tooltip),
//         ),
//       );
//       expect(rollTooltip.message, 'Not Your Turn');
//     });

//     testWidgets('should disable all actions when agent offline', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: false, // Agent offline
//               canRoll: false,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               rollDisabledReason: 'Agent Offline',
//               buyDisabledReason: 'Agent Offline',
//               upgradeDisabledReason: 'Agent Offline',
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       final rollButton = tester.widget<ElevatedButton>(
//         find.byKey(const Key('btn_roll_disabled')),
//       );
//       final buyButton = tester.widget<ElevatedButton>(
//         find.byKey(const Key('btn_buy')),
//       );
//       final upgradeButton = tester.widget<ElevatedButton>(
//         find.byKey(const Key('btn_upgrade')),
//       );

//       expect(rollButton.onPressed, isNull);
//       expect(buyButton.onPressed, isNull);
//       expect(upgradeButton.onPressed, isNull);
//     });

//     testWidgets('should show tooltip reason when buy disabled', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               buyDisabledReason: 'No Sale',
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       final buyTooltip = tester.widget<Tooltip>(
//         find.ancestor(
//           of: find.byKey(const Key('btn_buy')),
//           matching: find.byType(Tooltip),
//         ),
//       );
//       expect(buyTooltip.message, 'No Sale');
//     });

//     testWidgets('should enable buy button when on unowned property', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: true, // Can buy
//               canUpgradeProperty: false,
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       final buyFinder = find.byKey(const Key('btn_buy'));
//       expect(buyFinder, findsOneWidget);

//       final buyButton = tester.widget<ElevatedButton>(buyFinder);
//       expect(buyButton.onPressed, isNotNull);
//     });

//     testWidgets('should enable upgrade button when on owned property', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: true, // Can upgrade
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       // Verify upgrade button exists and is enabled
//       final upgradeButton = tester.widget<ElevatedButton>(
//         find.byKey(const Key('btn_upgrade')),
//       );
//       expect(upgradeButton.onPressed, isNotNull);
//     });

//     testWidgets('should show takeover button when enabled', (
//       WidgetTester tester,
//     ) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               canTakeoverProperty: true, // Enable Takeover
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       final takeoverFinder = find.byKey(const Key('btn_takeover'));
//       expect(takeoverFinder, findsOneWidget);

//       final takeoverButton = tester.widget<ElevatedButton>(takeoverFinder);
//       expect(takeoverButton.onPressed, isNotNull);
//     });

//     testWidgets('should show loading state', (WidgetTester tester) async {
//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               isLoading: true, // Loading state
//               onRollDice: (val) {},
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       // When loading, disabled roll button should be shown instead of gauge
//       final rollButton = tester.widget<ElevatedButton>(
//         find.byKey(const Key('btn_roll_disabled')),
//       );
//       expect(rollButton.onPressed, isNull);
//     });

//     testWidgets('should trigger callbacks when buttons pressed', (
//       WidgetTester tester,
//     ) async {
//       bool rollDiceCalled = false;

//       await tester.pumpWidget(
//         MaterialApp(
//           home: Scaffold(
//             body: ActionPanel(
//               isAgentActive: true,
//               canRoll: true,
//               canEndTurn: false,
//               canBuyProperty: false,
//               canUpgradeProperty: false,
//               onRollDice: (val) => rollDiceCalled = true,
//               onBuyProperty: () {},
//               onUpgradeProperty: () {},
//               onTakeoverProperty: () {},
//               onEndTurn: () {},
//             ),
//           ),
//         ),
//       );

//       // Tap DiceGauge
//       final gaugeFinder = find.byKey(const Key('gauge_roll'));
//       if (gaugeFinder.evaluate().isNotEmpty) {
//         // Simulate tap (down/up)
//         await tester.tap(gaugeFinder);
//         // DiceGauge calls onRelease on tapUp
//         await tester.pumpAndSettle();
//         expect(rollDiceCalled, isTrue);
//       }
//     });
//   });
// }
