import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../gatekeeper/gatekeeper_service.dart';
import '../../gatekeeper/screens/access_denied_screen.dart';
import '../../bootstrap/launch_flow.dart';
import 'main_menu.dart';
import 'package:provider/provider.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _childIdController = TextEditingController();
  final String _parentId = "demoparent"; // Hardcoded as per requirement
  // Removed _nameController as Display Name field is removed
  bool _isLoading = false;

  Future<void> _login() async {
    if (_childIdController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter User ID")));
      return;
    }

    setState(() => _isLoading = true);

    final gatekeeper = context.read<GatekeeperService>();
    final result = await gatekeeper.isChildAgentActive(
      _parentId,
      _childIdController.text.trim(),
    );

    if (!mounted) return;

    final decision = evaluateLaunchDecision(
      hasActiveAuthSession: true,
      heartbeat: result,
    );

    if (!decision.canEnterGame) {
      setState(() => _isLoading = false);
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => AccessDeniedScreen(
            reasonCode: decision.reasonCode ?? 'OFFLINE',
          ),
        ),
      );
      return;
    }

    gatekeeper.startRealtimeMonitoring(
      _parentId,
      _childIdController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainMenuScreen(
          parentId: _parentId,
          childId: _childIdController.text.trim(),
        ),
      ),
    );
  }

  // Removed _startGame method
  // Removed _goToMultiplayer method

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      style: GoogleFonts.sourceCodePro(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.cyanAccent),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.white24),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: Colors.cyanAccent),
        ),
        prefixIcon: Icon(icon, color: Colors.white54),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 400),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            border: Border.all(color: Colors.cyanAccent),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.cyanAccent.withValues(alpha: 0.1),
                blurRadius: 20,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                "CYBER TYCOON",
                style: GoogleFonts.orbitron(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Colors.cyanAccent,
                  shadows: [const Shadow(color: Colors.blue, blurRadius: 10)],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Login Configuration",
                style: GoogleFonts.robotoMono(color: Colors.white54),
              ),
              const SizedBox(height: 32),
              // Removed _buildTextField for _nameController and its SizedBox
              /* _buildTextField(
                controller: _parentIdController,
                label: "PARENT ID",
                icon: Icons.admin_panel_settings_outlined,
              ),
              const SizedBox(height: 16), */
              _buildTextField(
                controller: _childIdController,
                label: "USER ID",
                icon: Icons.fingerprint,
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          "LOGIN TO SYSTEM",
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
