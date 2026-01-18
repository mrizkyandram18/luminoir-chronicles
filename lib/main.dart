import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;

import 'gatekeeper/gatekeeper_service.dart';
import 'gatekeeper/screens/access_denied_screen.dart';
import 'gatekeeper/screens/splash_screen.dart';
import 'gatekeeper/screens/setup_screen.dart';
import 'game_identity/game_identity_service.dart';
import 'services/supabase_service.dart';
import 'game/raid/models/raid_player.dart';
import 'game/raid/screens/character_select_screen.dart';
import 'game/raid/screens/main_menu_screen.dart';
import 'game/raid/screens/raid_screen.dart';
import 'game/raid/screens/feature_placeholder_screen.dart';
import 'game/raid/screens/summon_screen.dart';
import 'game/raid/screens/ninja_screen.dart';

import 'package:device_preview/device_preview.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  if (kDebugMode) {
    debugPaintSizeEnabled =
        false; // Disable debug paint as DevicePreview handles visual debugging
  }

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await Supabase.initialize(
    url: 'https://hmrkssfhcxlvjzyigufd.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imhtcmtzc2ZoY3hsdmp6eWlndWZkIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Njg1NTE3NzcsImV4cCI6MjA4NDEyNzc3N30.svgZlN95pJEzRvh4RtOhL_1J99o4a21LrUiT72B8p-w',
  );

  if (kIsWeb) {
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
    await Firebase.initializeApp();
  }

  runApp(
    DevicePreview(
      enabled: true, // Enabled for debugging responsive issues
      builder: (context) => MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => GatekeeperService()),
          ChangeNotifierProvider(create: (_) => GameIdentityService()),
          Provider<SupabaseService>(create: (_) => SupabaseService()),
        ],
        child: const LuminoirChroniclesApp(),
      ),
    ),
  );
}

class LuminoirChroniclesApp extends StatelessWidget {
  const LuminoirChroniclesApp({super.key});

  @override
  Widget build(BuildContext context) {
    if (kDebugMode) {
      // In DevicePreview, this MediaQuery might return the simulated device size
      // We can also check specific metrics here if needed
    }
    return MaterialApp.router(
      title: 'Luminoir: Chronicles',
      debugShowCheckedModeBanner: false,
      locale: DevicePreview.locale(context), // Required for DevicePreview
      builder: DevicePreview.appBuilder, // Required for DevicePreview
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
    GoRoute(path: '/setup', builder: (context, state) => const SetupScreen()),
    GoRoute(
      path: '/character-select',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>?;
        final childId = extra?['childId'] ?? '';
        return CharacterSelectScreen(childId: childId);
      },
    ),
    GoRoute(
      path: '/main-menu',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>?;
        final childId = extra?['childId'] as String? ?? '';
        return MainMenuScreen(childId: childId);
      },
    ),
    GoRoute(
      path: '/raid',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final childId = extra['childId'] as String? ?? '';
        final job = extra['job'] as PlayerJob? ?? PlayerJob.warrior;
        final openInventory = extra['openInventoryOnStart'] as bool? ?? false;
        return RaidScreen(
          myPlayerId: childId,
          myJob: job,
          openInventoryOnStart: openInventory,
        );
      },
    ),
    GoRoute(
      path: '/summon',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final childId = extra['childId'] as String? ?? '';
        return SummonScreen(childId: childId);
      },
    ),
    GoRoute(
      path: '/ninja',
      builder: (context, state) {
        final extra = state.extra as Map<String, dynamic>? ?? {};
        final childId = extra['childId'] as String? ?? '';
        return NinjaScreen(childId: childId);
      },
    ),
    GoRoute(
      path: '/feature',
      builder: (context, state) {
        final extra = state.extra as Map<String, String>? ?? {};
        final title = extra['title'] ?? 'Feature';
        final description =
            extra['description'] ??
            'Fitur ini akan segera hadir di Luminoir: Chronicles.';
        return FeaturePlaceholderScreen(title: title, description: description);
      },
    ),
    GoRoute(
      path: '/access-denied',
      builder: (context, state) {
        final reason = state.extra as String? ?? 'SERVICE_STOPPED';
        return AccessDeniedScreen(reasonCode: reason);
      },
    ),
  ],
);
