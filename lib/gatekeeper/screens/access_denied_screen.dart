import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:google_fonts/google_fonts.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String reasonCode;

  const AccessDeniedScreen({
    super.key,
    required this.reasonCode,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.red, width: 4),
            borderRadius: BorderRadius.circular(16),
            color: Colors.red.withValues(alpha: 0.1),
            boxShadow: [
              BoxShadow(
                color: Colors.red.withValues(alpha: 0.5),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.lock_outline, size: 80, color: Colors.red),
              const Gap(20),
              Text(
                'ACCESS DENIED',
                style: GoogleFonts.orbitron(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                  letterSpacing: 2,
                ),
              ),
              const Gap(10),
              Text(
                reasonCode,
                style: GoogleFonts.robotoMono(
                  fontSize: 16,
                  color: Colors.redAccent,
                ),
              ),
              const Gap(30),
              Text(
                'Nyalakan System Service Child Agent\nuntuk mengakses Luminoir: Chronicles.',
                textAlign: TextAlign.center,
                style: GoogleFonts.roboto(color: Colors.white70, fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
