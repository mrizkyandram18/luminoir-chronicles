import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';
import '../models/raid_player.dart';

class NinjaScreen extends StatefulWidget {
  final String childId;

  const NinjaScreen({super.key, required this.childId});

  @override
  State<NinjaScreen> createState() => _NinjaScreenState();
}

class _NinjaScreenState extends State<NinjaScreen> {
  bool _loading = true;
  Map<String, dynamic>? _profile;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = context.read<SupabaseService>();
    final p = await supabase.getPlayerProfile(widget.childId);
    if (!mounted) return;
    setState(() {
      _profile = p;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> heroes = [];
    if (_profile != null) {
      final stats = _profile!['stats'] as Map<String, dynamic>?;
      final party = stats?['party'] as List<dynamic>?;
      if (party != null) {
        for (final entry in party) {
          if (entry is Map<String, dynamic>) {
            heroes.add(entry);
          }
        }
      }
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          'Ninja',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : heroes.isEmpty
              ? Center(
                  child: Text(
                    'Belum ada hero di party kamu.\nCoba summon dulu di Shop.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                  ),
                )
              : Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Koleksi Ninja',
                        style: GoogleFonts.orbitron(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Saat ini menampilkan hero yang aktif di party (max 6 slot).',
                        style: GoogleFonts.robotoMono(
                          color: Colors.white70,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: GridView.builder(
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 3 / 4,
                          ),
                          itemCount: heroes.length,
                          itemBuilder: (context, index) {
                            final hero = heroes[index];
                            final name =
                                hero['name']?.toString() ?? 'Unknown Ninja';
                            final jobStr =
                                hero['job']?.toString() ?? PlayerJob.warrior.name;
                            final rarity =
                                hero['rarity']?.toString() ?? 'common';
                            final level = (hero['level'] as int?) ?? 1;
                            final slot = (hero['slot'] as int?) ?? index;
                            final attack = (hero['attack'] as int?) ?? 0;
                            final hp = (hero['hp'] as int?) ?? 0;
                            final equipmentCode =
                                hero['equipment']?.toString() ?? 'none';

                            final job = PlayerJob.values.firstWhere(
                              (e) => e.name == jobStr,
                              orElse: () => PlayerJob.warrior,
                            );

                            Color rarityColor;
                            switch (rarity) {
                              case 'rare':
                                rarityColor = Colors.blueAccent;
                                break;
                              case 'epic':
                                rarityColor = Colors.purpleAccent;
                                break;
                              case 'legendary':
                                rarityColor = Colors.orangeAccent;
                                break;
                              default:
                                rarityColor = Colors.grey;
                            }

                            final equipmentLabel =
                                _equipmentLabel(equipmentCode);

                            return GestureDetector(
                              onTap: () {
                                _showEquipmentSheet(
                                  context: context,
                                  hero: hero,
                                  slot: slot,
                                );
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.black.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(16),
                                  border:
                                      Border.all(color: rarityColor, width: 2),
                                ),
                                padding: const EdgeInsets.all(12),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Lv.$level',
                                          style: GoogleFonts.robotoMono(
                                            color: Colors.white,
                                            fontSize: 11,
                                          ),
                                        ),
                                        Text(
                                          rarity.toUpperCase(),
                                          style: GoogleFonts.robotoMono(
                                            color: rarityColor,
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'ATK $attack  HP $hp',
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Expanded(
                                      child: Center(
                                        child: Icon(
                                          _jobIcon(job),
                                          color: rarityColor,
                                          size: 32,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.white,
                                        fontSize: 11,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Slot ${slot + 1} - ${job.name.toUpperCase()}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.white70,
                                        fontSize: 10,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Equip: $equipmentLabel',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.robotoMono(
                                        color: Colors.cyanAccent,
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  IconData _jobIcon(PlayerJob job) {
    switch (job) {
      case PlayerJob.warrior:
        return Icons.sports_martial_arts;
      case PlayerJob.mage:
        return Icons.auto_awesome;
      case PlayerJob.archer:
        return Icons.gps_fixed;
      case PlayerJob.assassin:
        return Icons.flash_on;
    }
  }

  String _equipmentLabel(String code) {
    switch (code) {
      case 'atk_10':
        return '+10 ATK Blade';
      case 'atk_25':
        return '+25 ATK Katana';
      default:
        return 'None';
    }
  }

  Future<void> _showEquipmentSheet({
    required BuildContext context,
    required Map<String, dynamic> hero,
    required int slot,
  }) async {
    final supabase = context.read<SupabaseService>();

    final Map<String, String> options = {
      'none': 'No Equipment',
      'atk_10': '+10 ATK Blade',
      'atk_25': '+25 ATK Katana',
    };

    final selected = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.black87,
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: options.entries.map((entry) {
              return ListTile(
                title: Text(
                  entry.value,
                  style: GoogleFonts.robotoMono(color: Colors.white),
                ),
                onTap: () {
                  Navigator.of(ctx).pop(entry.key);
                },
              );
            }).toList(),
          ),
        );
      },
    );

    if (selected == null) {
      return;
    }

    final updatedHero = Map<String, dynamic>.from(hero)
      ..['equipment'] = selected
      ..['slot'] = slot;

    await supabase.addPartyMember(
      playerId: widget.childId,
      hero: updatedHero,
    );

    if (!mounted) return;

    setState(() {
      if (_profile != null) {
        final stats = (_profile!['stats'] as Map<String, dynamic>?) ??
            <String, dynamic>{};
        final party =
            (stats['party'] as List<dynamic>?)?.toList() ?? <dynamic>[];
        for (var i = 0; i < party.length; i++) {
          final entry = party[i];
          if (entry is Map<String, dynamic>) {
            final entrySlot = entry['slot'] as int?;
            if (entrySlot == slot) {
              party[i] = updatedHero;
              break;
            }
          }
        }
        stats['party'] = party;
        _profile = Map<String, dynamic>.from(_profile!)
          ..['stats'] = stats;
      }
    });
  }
}
