import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:luminoir_chronicles/main.dart';
import 'package:luminoir_chronicles/gatekeeper/gatekeeper_service.dart';
import 'package:mockito/mockito.dart';

// Internal Mock
class MockGatekeeperService extends Mock implements GatekeeperService {
  @override
  bool get isSystemOnline => true;

  @override
  bool get hasActiveAuthSession => true;

  @override
  Future<void> checkStatus() async {
    // No-op for test
    notifyListeners();
  }
}

void main() {
  testWidgets('Splash screen loads', (WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<GatekeeperService>(
            create: (_) => MockGatekeeperService(),
          ),
        ],
        child: const LuminoirChroniclesApp(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump();

    expect(find.byType(LuminoirChroniclesApp), findsOneWidget);
  });
}
