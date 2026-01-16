import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:gap/gap.dart';
import '../game_controller.dart';
import 'game_board_screen.dart';
import '../../gatekeeper/gatekeeper_service.dart';

class SetupScreen extends StatefulWidget {
  const SetupScreen({super.key});

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _parentIdController = TextEditingController(text: "demoparent");
  final _childIdController = TextEditingController(text: "usertesting 1");
  bool _isLoading = false;

  Future<void> _startGame() async {
    if (_parentIdController.text.isEmpty || _childIdController.text.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please enter both IDs")));
      return;
    }

    setState(() => _isLoading = true);

    // Verify Agent Status BEFORE entering the game
    final gatekeeper = context.read<GatekeeperService>();
    final result = await gatekeeper.isChildAgentActive(
      _parentIdController.text.trim(),
      _childIdController.text.trim(),
    );

    if (!mounted) return;

    if (!result.isSuccess) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Access Denied [${result.resultCode.code}]\n"
            "${result.displayMessage}",
          ),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
      return;
    }

    // ✅ Login successful - Start realtime monitoring
    gatekeeper.startRealtimeMonitoring(
      _parentIdController.text.trim(),
      _childIdController.text.trim(),
    );

    if (mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => ChangeNotifierProvider(
            create: (_) => GameController(
              context.read<GatekeeperService>(),
              parentId: _parentIdController.text,
              childId: _childIdController.text,
            ),
            child: const GameBoardScreen(),
          ),
        ),
      );
    }
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
                color: Colors.cyanAccent.withValues(alpha: 0.2),
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
              const Gap(10),
              Text(
                "Security Configuration",
                style: GoogleFonts.robotoMono(color: Colors.white54),
              ),
              const Gap(30),
              // Parent ID is now hidden/static for privacy
              // const Gap(16),
              // TextField(controller: _parentIdController...),
              const Gap(16),
              TextField(
                controller: _childIdController,
                style: GoogleFonts.sourceCodePro(color: Colors.white),
                decoration: InputDecoration(
                  labelText: "Child Agent ID",
                  labelStyle: TextStyle(color: Colors.cyanAccent),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.white24),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: Colors.cyanAccent),
                  ),
                  prefixIcon: Icon(Icons.person_pin, color: Colors.white54),
                ),
              ),
              const Gap(30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.cyanAccent,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 20),
                  ),
                  onPressed: _isLoading ? null : _startGame,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.black)
                      : Text(
                          "INITIALIZE SYSTEM",
                          style: GoogleFonts.orbitron(
                            fontWeight: FontWeight.bold,
                            letterSpacing: 2,
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
