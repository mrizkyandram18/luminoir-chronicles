import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import '../../gatekeeper/gatekeeper_service.dart';
import '../../gatekeeper/screens/access_denied_screen.dart';
import '../../bootstrap/launch_flow.dart';
// import 'main_menu.dart'; // No longer needed
import 'package:provider/provider.dart';

import '../../services/supabase_service.dart';
import 'package:flame/game.dart';
import '../game/login_background_game.dart';

/// Setup screen in Classic Monopoly Style
class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _childIdController = TextEditingController();
  final String _parentId = "demoparent"; // Hardcoded
  bool _isLoading = false;

  // Classic Monopoly Colors
  static const Color boardBeige = Color(0xFFE2E2E2);
  static const Color boardBlack = Colors.black;

  Future<void> _login() async {
    final childId = _childIdController.text.trim();
    if (childId.isEmpty) {
      _showClassicSnackBar("Please enter your User ID");
      return;
    }

    setState(() => _isLoading = true);

    final gatekeeper = context.read<GatekeeperService>();
    final isAllowed = await gatekeeper.isUserAllowed(childId);

    if (!isAllowed) {
      setState(() => _isLoading = false);
      if (!mounted) return;
      _showClassicSnackBar("Access Denied: User not whitelisted");
      return;
    }

    final result = await gatekeeper.isChildAgentActive(_parentId, childId);

    if (!mounted) return;

    final decision = evaluateLaunchDecision(
      hasActiveAuthSession: true,
      heartbeat: result,
    );

    if (!decision.canEnterGame) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) =>
              AccessDeniedScreen(reasonCode: decision.reasonCode ?? 'OFFLINE'),
        ),
      );
      return;
    }

    gatekeeper.startRealtimeMonitoring(_parentId, childId);

    // Check for Existing Profile (Raid Game)
    // Note: Assuming SupabaseService is available via Provider or Locator
    // Here we might need to add it to Provider or instantiate it strictly for this check.
    // However, SupabaseService is probably designed to be a singleton or provider.
    // Let's assume Provider<SupabaseService> is in main.dart.
    // BUT, wait... Main.dart provides SupabaseService. YES.

    try {
      final supabaseService = context.read<SupabaseService>();
      final profile = await supabaseService.getPlayerProfile(childId);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (profile != null) {
        // Existing Profile -> Go to Main Menu
        context.go('/main-menu', extra: {'childId': childId});
      } else {
        // New Profile -> Go to Character Select
        context.go('/character-select', extra: {'childId': childId});
      }
    } catch (e) {
      // Fallback on error (Assume New or Retry)
      debugPrint("Error checking profile: $e");
      context.go('/character-select', extra: {'childId': childId});
    }
  }

  void _showClassicSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.philosopher(color: Colors.white),
        ),
        backgroundColor: boardBlack,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    debugPrint("=== Debugging SetupScreen ===");
    final mq = MediaQuery.of(context);
    debugPrint("Screen Size: ${mq.size}");
    debugPrint("Screen Padding: ${mq.padding}");
    // ignore: deprecated_member_use
    debugPrint("TextScale: ${mq.textScaleFactor}");

    return Scaffold(
      backgroundColor: boardBeige,
      body: Stack(
        children: [
          Positioned.fill(child: GameWidget(game: LoginBackgroundGame())),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                debugPrint("SetupScreen Body Constraints: $constraints");

                // Determine if the screen is vertically constrained (e.g. landscape phone)
                final isCompact = constraints.maxHeight < 500;

                return Center(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.symmetric(
                      horizontal: 24,
                      vertical: isCompact ? 16 : 32,
                    ),
                    child: Container(
                      padding: EdgeInsets.all(isCompact ? 16 : 32),
                      constraints: const BoxConstraints(maxWidth: 400),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        border: Border.all(color: boardBlack, width: 3),
                        boxShadow: const [
                          BoxShadow(
                            color: Colors.black26,
                            blurRadius: 15,
                            offset: Offset(8, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            "CYBER",
                            style: GoogleFonts.philosopher(
                              fontSize: isCompact ? 16 : 20,
                              fontWeight: FontWeight.bold,
                              color: boardBlack,
                              letterSpacing: 4,
                            ),
                          ),
                          Text(
                            "TYCOON",
                            style: GoogleFonts.philosopher(
                              fontSize: isCompact ? 32 : 42,
                              fontWeight: FontWeight.bold,
                              color: boardBlack,
                              height: 0.9,
                            ),
                          ),
                          const Gap(8),
                          Container(height: 2, width: 100, color: boardBlack),
                          Gap(isCompact ? 16 : 32),
                          Text(
                            "OFFICIAL LOGIN",
                            style: GoogleFonts.philosopher(
                              fontSize: isCompact ? 12 : 14,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 2,
                            ),
                          ),
                          Gap(isCompact ? 12 : 24),
                          _buildClassicTextField(
                            controller: _childIdController,
                            label: "ENTER USER ID",
                            icon: Icons.fingerprint,
                            isCompact: isCompact,
                          ),
                          Gap(isCompact ? 16 : 32),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green[800],
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  vertical: isCompact ? 12 : 18,
                                ),
                                shape: const RoundedRectangleBorder(
                                  side: BorderSide(color: boardBlack, width: 2),
                                ),
                                elevation: 8,
                              ),
                              onPressed: _isLoading ? null : _login,
                              child: _isLoading
                                  ? const SizedBox(
                                      height: 20,
                                      width: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      "ESTABLISH CONNECTION",
                                      style: GoogleFonts.philosopher(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                          Gap(isCompact ? 12 : 16),
                          Text(
                            "Secured Line - Classic Edition",
                            style: GoogleFonts.philosopher(
                              fontSize: 10,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildClassicTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isCompact = false,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.robotoMono(
        fontWeight: FontWeight.bold,
        color: boardBlack,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.philosopher(
          color: boardBlack,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
        prefixIcon: Icon(icon, color: boardBlack),
        filled: true,
        fillColor: Colors.grey[100],
        contentPadding: isCompact
            ? const EdgeInsets.symmetric(horizontal: 12, vertical: 10)
            : null,
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: boardBlack, width: 2),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: boardBlack, width: 2.5),
        ),
      ),
    );
  }
}
