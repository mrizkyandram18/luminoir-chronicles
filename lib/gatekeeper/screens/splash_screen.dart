import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../gatekeeper_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkStatus();
  }

  Future<void> _checkStatus() async {
    final gatekeeper = context.read<GatekeeperService>();
    await gatekeeper.checkStatus();

    if (mounted) {
      if (gatekeeper.isSystemOnline) {
        context.go('/setup');
      } else {
        context.go(
          '/access-denied',
          extra: 'SERVICE_STOPPED',
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Colors.cyanAccent),
            const SizedBox(height: 20),
            Text(
              'ESTABLISHING CONNECTION...',
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
