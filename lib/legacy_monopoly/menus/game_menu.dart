import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class GameMenu extends StatelessWidget {
  final VoidCallback onResume;
  final VoidCallback onSave;
  final VoidCallback onLoad;
  final VoidCallback onLeaderboard;
  final VoidCallback onExit;
  final bool showSaveLoad;

  const GameMenu({
    super.key,
    required this.onResume,
    required this.onSave,
    required this.onLoad,
    required this.onLeaderboard,
    required this.onExit,
    this.showSaveLoad = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFF121212), // Dark background
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        border: Border(top: BorderSide(color: Colors.cyanAccent, width: 2)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "SYSTEM MENU",
              style: GoogleFonts.orbitron(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 32),

            if (showSaveLoad) ...[
              _buildMenuButton(
                context,
                icon: Icons.save,
                label: "SAVE GAME",
                onPressed: onSave,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 16),
              _buildMenuButton(
                context,
                icon: Icons.input, // Or generic import icon
                label: "LOAD GAME",
                onPressed: onLoad,
                color: Colors.orangeAccent,
              ),
              const SizedBox(height: 16),
            ],

            _buildMenuButton(
              context,
              icon: Icons.leaderboard,
              label: "LEADERBOARD",
              onPressed: onLeaderboard,
              color: Colors.cyanAccent,
            ),
            const SizedBox(height: 16),

            _buildMenuButton(
              context,
              icon: Icons.exit_to_app,
              label: "EXIT TO TITLE", // Or Forfeit
              onPressed: onExit,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 32),

            TextButton(
              onPressed: onResume,
              child: Text(
                "CLOSE MENU",
                style: GoogleFonts.robotoMono(color: Colors.white54),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        icon: Icon(icon, color: Colors.black),
        label: Text(
          label,
          style: GoogleFonts.orbitron(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            letterSpacing: 1,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 4,
        ),
        onPressed: () {
          // Close menu first ideally, but parent can handle
          onPressed();
        },
      ),
    );
  }
}
