import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'gatekeeper/gatekeeper_service.dart';
import 'gatekeeper/screens/access_denied_screen.dart';
import 'gatekeeper/screens/splash_screen.dart';
import 'game/screens/main_menu.dart';
import 'game/game_controller.dart';
import 'game/screens/game_board_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://PLACEHOLDER_URL.supabase.co',
    anonKey: 'PLACEHOLDER_ANON_KEY',
  );

  // TODO: Initialize Firebase here (uncomment when ready)
  // await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GatekeeperService()),
        ChangeNotifierProxyProvider<GatekeeperService, GameController>(
          create: (context) =>
              GameController(context.read<GatekeeperService>()),
          update: (context, gatekeeper, previous) =>
              previous ?? GameController(gatekeeper),
        ),
      ],
      child: const CyberTycoonApp(),
    ),
  );
}

class CyberTycoonApp extends StatelessWidget {
  const CyberTycoonApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Cyber Tycoon',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(
        scaffoldBackgroundColor: Colors.black,
        textTheme: GoogleFonts.robotoTextTheme(
          Theme.of(context).textTheme,
        ).apply(bodyColor: Colors.white, displayColor: Colors.white),
      ),
      routerConfig: _router,
    );
  }
}

final _router = GoRouter(
  initialLocation: '/',
  routes: [
    GoRoute(path: '/', builder: (context, state) => const SplashScreen()),
    GoRoute(path: '/menu', builder: (context, state) => const MainMenuScreen()),
    GoRoute(
      path: '/access-denied',
      builder: (context, state) => const AccessDeniedScreen(),
    ),
    GoRoute(
      path: '/game',
      builder: (context, state) => const GameBoardScreen(),
    ),
  ],
);
