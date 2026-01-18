import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';
import '../models/raid_player.dart';
import '../widgets/pixel_button.dart';

class CharacterSelectScreen extends StatefulWidget {
  final String childId;

  const CharacterSelectScreen({super.key, required this.childId});

  @override
  State<CharacterSelectScreen> createState() => _CharacterSelectScreenState();
}

class _CharacterSelectScreenState extends State<CharacterSelectScreen> {
  PlayerJob _selectedJob = PlayerJob.warrior;
  final TextEditingController _ignController = TextEditingController();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Row(
        children: [
          // LEFT: Class Selection
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  "SELECT CLASS",
                  style: TextStyle(
                    color: Colors.cyanAccent,
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 20),
                _classOption(
                  PlayerJob.warrior,
                  "WARRIOR",
                  Icons.shield,
                  Colors.redAccent,
                ),
                _classOption(
                  PlayerJob.mage,
                  "MAGE",
                  Icons.auto_awesome,
                  Colors.purpleAccent,
                ),
                _classOption(
                  PlayerJob.archer,
                  "ARCHER",
                  Icons.gps_fixed,
                  Colors.greenAccent,
                ),
                _classOption(
                  PlayerJob.assassin,
                  "ASSASSIN",
                  Icons.flash_on,
                  Colors.yellowAccent,
                ),
              ],
            ),
          ),

          // CENTER: Preview
          Expanded(
            flex: 2,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _getIconForJob(_selectedJob),
                  size: 120,
                  color: _getColorForJob(_selectedJob),
                ),
                const SizedBox(height: 20),
                Text(
                  _selectedJob.name.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                // Simple Stats
                Text(
                  _getJobDesc(_selectedJob),
                  style: const TextStyle(color: Colors.grey),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),

          // RIGHT: Actions
          Expanded(
            flex: 1,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: TextField(
                    controller: _ignController,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                    decoration: const InputDecoration(
                      labelText: "ENTER AGENT NAME",
                      labelStyle: TextStyle(color: Colors.cyanAccent),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.cyanAccent),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white, width: 2),
                      ),
                    ),
                    onChanged: (v) => setState(() {}),
                  ),
                ),

                const SizedBox(height: 40),

                PixelButton(
                  label: _isCreating ? "INITIALIZING..." : "CONFIRM",
                  onPressed: (_ignController.text.isEmpty || _isCreating)
                      ? null
                      : () => _handleCreate(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleCreate() async {
    setState(() => _isCreating = true);
    try {
      final supabase = context.read<SupabaseService>();
      await supabase.createPlayerProfile(
        widget.childId,
        _ignController.text.trim(),
        _selectedJob.name,
      );

      if (!mounted) return;

      // Navigate to Main Menu after creation
      context.go('/main-menu', extra: {'childId': widget.childId});
    } catch (e) {
      debugPrint("Creation Error: $e");
      setState(() => _isCreating = false);
    }
  }

  Widget _classOption(PlayerJob job, String label, IconData icon, Color color) {
    bool isSelected = _selectedJob == job;
    return GestureDetector(
      onTap: () => setState(() => _selectedJob = job),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          border: Border.all(color: isSelected ? color : Colors.grey.shade800),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isSelected ? color : Colors.grey),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  IconData _getIconForJob(PlayerJob job) {
    switch (job) {
      case PlayerJob.warrior:
        return Icons.shield;
      case PlayerJob.mage:
        return Icons.auto_awesome;
      case PlayerJob.archer:
        return Icons.gps_fixed;
      case PlayerJob.assassin:
        return Icons.flash_on;
    }
  }

  Color _getColorForJob(PlayerJob job) {
    switch (job) {
      case PlayerJob.warrior:
        return Colors.redAccent;
      case PlayerJob.mage:
        return Colors.purpleAccent;
      case PlayerJob.archer:
        return Colors.greenAccent;
      case PlayerJob.assassin:
        return Colors.yellowAccent;
    }
  }

  String _getJobDesc(PlayerJob job) {
    switch (job) {
      case PlayerJob.warrior:
        return "High HP, Slow Atk";
      case PlayerJob.mage:
        return "High Dmg, Slow spd";
      case PlayerJob.archer:
        return "Fast Atk, Low Dmg";
      case PlayerJob.assassin:
        return "High Crit, Balanced";
    }
  }
}
