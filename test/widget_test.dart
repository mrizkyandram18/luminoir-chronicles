import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:cyber_tycoon/main.dart';
import 'package:cyber_tycoon/gatekeeper/gatekeeper_service.dart';

void main() {
  testWidgets('Splash screen loads', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [ChangeNotifierProvider(create: (_) => GatekeeperService())],
        child: const CyberTycoonApp(),
      ),
    );

    // Verify that Splash Screen appears
    expect(find.text('ESTABLISHING CONNECTION...'), findsOneWidget);
  });
}
