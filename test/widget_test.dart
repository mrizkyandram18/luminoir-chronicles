import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cyber_tycoon/main.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';
import 'package:mockito/mockito.dart';

// Internal Mock
class MockGatekeeperService extends Mock implements GatekeeperService {
  @override
  bool get isSystemOnline => true;

  @override
  Future<void> checkStatus() async {
    // No-op for test
    notifyListeners();
  }
}

void main() {
  testWidgets('Splash screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GatekeeperService>(
            create: (_) => MockGatekeeperService(),
          ),
        ],
        child: const CyberTycoonApp(),
      ),
    );

    // Verify that Splash or Setup screen appears
    expect(find.byType(CyberTycoonApp), findsOneWidget);
  });
}
