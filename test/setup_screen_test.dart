import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/screens/setup_screen.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';
import 'package:provider/provider.dart';
import 'package:mockito/mockito.dart';

class MockGatekeeperService extends Mock implements GatekeeperService {
  @override
  bool get isSystemOnline => true;
}

void main() {
  testWidgets('SetupScreen displays generic User ID labels', (
    WidgetTester tester,
  ) async {
    // ARRANGE
    final mockGatekeeper = MockGatekeeperService();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<GatekeeperService>(
          create: (_) => mockGatekeeper,
          child: const SetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify "Child Agent ID" is GONE
    expect(find.text('Child Agent ID'), findsNothing);

    // Verify "Login Configuration" is PRESENT (static Text)
    expect(find.textContaining('Login Configuration'), findsOneWidget);

    // Verify no mention of Agent
    expect(find.textContaining('Agent'), findsNothing);
  });
}
