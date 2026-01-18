import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/raid_player.dart';

import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';
import '../widgets/pixel_button.dart';

class LobbyScreen extends StatefulWidget {
  final String parentId;
  final String childId;

  const LobbyScreen({super.key, required this.parentId, required this.childId});

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  PlayerJob _selectedJob = PlayerJob.warrior;
  final TextEditingController _ignController = TextEditingController();
  bool _isCreating = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Background Grid (Procedural)
          Positioned.fill(
            child: Opacity(
              opacity: 0.1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.blue, Colors.purple],
                  ),
                ),
              ),
            ),
          ),

          Center(
            child: Row(
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

                // CENTER: Character Preview
                Expanded(
                  flex: 2,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Preview Box
                      Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.cyanAccent,
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.cyanAccent.withValues(alpha: 0.3),
                              blurRadius: 20,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _getIconForJob(_selectedJob),
                            size: 100,
                            color: _getColorForJob(_selectedJob),
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        _selectedJob.name.toUpperCase(),
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 4,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _buildStatsPreview(_selectedJob),
                    ],
                  ),
                ),

                // RIGHT: Actions
                Expanded(
                  flex: 1,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // User Info
                      Text(
                        "USER: ${widget.childId}",
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 20),

                      // IGN Input
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
                              borderSide: BorderSide(
                                color: Colors.white,
                                width: 2,
                              ),
                            ),
                          ),
                          onChanged: (v) => setState(() {}),
                        ),
                      ),

                      const SizedBox(height: 40),

                      PixelButton(
                        label: _isCreating
                            ? "INITIALIZING..."
                            : "READY TO RAID",
                        onPressed: (_ignController.text.isEmpty || _isCreating)
                            ? null
                            : () => _handleReady(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleReady() async {
    setState(() => _isCreating = true);
    try {
      final supabase = context.read<SupabaseService>();
      await supabase.createPlayerProfile(
        widget.childId,
        _ignController.text.trim(),
        _selectedJob.name,
      );

      if (!mounted) return;

      context.go(
        '/raid',
        extra: {
          'job': _selectedJob,
          'childId': widget.childId,
          'ign': _ignController.text,
        },
      );
    } catch (e) {
      debugPrint("Creation Error: $e");
      setState(() => _isCreating = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text("Error: $e")));
      }
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

  Widget _buildStatsPreview(PlayerJob job) {
    // Create temp dummy to get stats
    final p = RaidPlayer.create("preview", "preview", job);
    return Column(
      children: [
        Text(
          "ATK: ${p.attack}   SPD: ${p.attackSpeed}   CRIT: ${(p.critChance * 100).toInt()}%",
        ),
      ],
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
}
