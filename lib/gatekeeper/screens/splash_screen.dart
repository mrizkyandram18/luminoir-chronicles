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
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    if (!gatekeeper.hasActiveAuthSession) {
      context.go('/setup');
      return;
    }

    context.go('/setup');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Gemini_Generated_Image_jnp4a5jnp4a5jnp4.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/Gemini_Generated_Image_p9og9tp9og9tp9og.png',
                    height: 120,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'LUMINOIR',
                    style: GoogleFonts.philosopher(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 6,
                    ),
                  ),
                  Text(
                    'CHRONICLES',
                    style: GoogleFonts.philosopher(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 0.9,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(color: Colors.cyanAccent),
                  const SizedBox(height: 16),
                  Text(
                    'ESTABLISHING SECURE LINK...',
                    style: GoogleFonts.orbitron(
                      color: Colors.cyanAccent,
                      letterSpacing: 2,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
