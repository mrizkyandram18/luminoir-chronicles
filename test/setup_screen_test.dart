import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:cyber_tycoon/game/screens/setup_screen.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_result.dart';
import 'package:cyber_tycoon/gatekeeper/screens/access_denied_screen.dart';
import 'package:provider/provider.dart';

class FakeGatekeeperInactive extends GatekeeperService {
  @override
  Future<GatekeeperResult> isChildAgentActive(
    String parentId,
    String childId,
  ) async {
    return const GatekeeperResult(GatekeeperResultCode.userInactive);
  }

  @override
  Future<bool> isUserAllowed(String userId) async {
    return true; // Mock whitelist check
  }
}

void main() {
  testWidgets('SetupScreen displays generic User ID labels', (
    WidgetTester tester,
  ) async {
    final gatekeeper = GatekeeperService();

    await tester.pumpWidget(
      MaterialApp(
        home: ChangeNotifierProvider<GatekeeperService>(
          create: (_) => gatekeeper,
          child: const SetupScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Child Agent ID'), findsNothing);
    expect(find.textContaining('Login Configuration'), findsOneWidget);
    expect(find.textContaining('Agent'), findsNothing);
  });

  testWidgets(
    'SetupScreen routes to AccessDeniedScreen with OFFLINE when heartbeat invalid',
    (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ChangeNotifierProvider<GatekeeperService>(
            create: (_) => FakeGatekeeperInactive(),
            child: const SetupScreen(),
          ),
        ),
      );

      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'child-123');

      await tester.tap(find.text('LOGIN TO SYSTEM'));
      await tester.pumpAndSettle();

      expect(find.byType(AccessDeniedScreen), findsOneWidget);
      expect(find.text('OFFLINE'), findsOneWidget);
    },
  );
}
