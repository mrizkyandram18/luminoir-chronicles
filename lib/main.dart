import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

import 'gatekeeper/gatekeeper_service.dart';
import 'gatekeeper/screens/access_denied_screen.dart';
import 'gatekeeper/screens/splash_screen.dart';
import 'game/screens/main_menu.dart';
// import 'game/game_controller.dart'; // No longer needed here
// import 'game/screens/game_board_screen.dart'; // Managed by SetupScreen
import 'game/screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Supabase
  // TODO: Replace with your actual Supabase URL and Anon Key
  await Supabase.initialize(
    url: 'https://hmrkssfhcxlvjzyigufd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtcmtzc2ZoY3hsdmp6eWlndWZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTE3NzcsImV4cCI6MjA4NDEyNzc3N30.svgZlN95pJEzRvh4RtOhL_1J99o4a21LrUiT72B8p-w',
  );

  // ...

  // Initialize Firebase
  if (kIsWeb) {
    // WEB: Requires manual configuration
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: "AIzaSyAfZYncZK7p1BK_250h_Sh1nsbqfvE9uZM",
        authDomain: "parentalcontrol-5abd8.firebaseapp.com",
        projectId: "parentalcontrol-5abd8",
        storageBucket: "parentalcontrol-5abd8.firebasestorage.app",
        messagingSenderId: "769889944258",
        appId: "1:769889944258:web:5cad45c1c16904715af15b",
        measurementId: "G-2EFN2GXX0F",
      ),
    );
  } else {
    // ANDROID/iOS: Uses google-services.json / GoogleService-Info.plist
    await Firebase.initializeApp();
  }

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GatekeeperService()),
        // GameController is now provided dynamically by SetupScreen
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
    // Replaced direct game route with SetupScreen flow for now
    GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
  ],
);
