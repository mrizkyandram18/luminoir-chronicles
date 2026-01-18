import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../gatekeeper_service.dart';
import 'access_denied_screen.dart';
import '../../bootstrap/launch_flow.dart';
import '../../services/supabase_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _childIdController = TextEditingController();
  final String _parentId = "demoparent";
  bool _isLoading = false;

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

    try {
      final supabaseService = context.read<SupabaseService>();
      final profile = await supabaseService.getPlayerProfile(childId);

      setState(() => _isLoading = false);

      if (!mounted) return;

      if (profile != null) {
        context.go('/main-menu', extra: {'childId': childId});
      } else {
        context.go('/character-select', extra: {'childId': childId});
      }
    } catch (e) {
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
    debugPrint("TextScaler: ${mq.textScaler}");

    return Scaffold(
      backgroundColor: boardBeige,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/Gemini_Generated_Image_jnp4a5jnp4a5jnp4.png',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                debugPrint("SetupScreen Body Constraints: $constraints");

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
                        color: Colors.white.withValues(alpha: 0.18),
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
                            "LUMINOIR",
                            style: GoogleFonts.philosopher(
                              fontSize: isCompact ? 22 : 26,
                              fontWeight: FontWeight.bold,
                              color: boardBlack,
                              letterSpacing: 4,
                            ),
                          ),
                          Text(
                            "CHRONICLES",
                            style: GoogleFonts.philosopher(
                              fontSize: isCompact ? 26 : 32,
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
                              child: Text(
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
          fontWeight: FontWeight.bold,
          letterSpacing: 1.5,
        ),
        prefixIcon: Icon(icon, color: boardBlack),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: boardBlack, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Colors.green, width: 2),
        ),
      ),
    );
  }
}

