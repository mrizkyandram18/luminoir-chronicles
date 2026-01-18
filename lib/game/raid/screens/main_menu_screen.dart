import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/raid_player.dart';
import '../models/raid_equipment.dart';
import '../widgets/inventory_widget.dart';
import '../systems/equipment_system.dart';
import '../../../services/supabase_service.dart';

class MainMenuScreen extends StatefulWidget {
  final String childId;

  const MainMenuScreen({super.key, required this.childId});

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  Map<String, dynamic>? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final supabase = context.read<SupabaseService>();
    final data = await supabase.getPlayerProfile(widget.childId);
    if (!mounted) return;
    setState(() {
      _profile = data;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    PlayerJob job = PlayerJob.warrior;
    String name = 'Agent';
    int level = 1;
    int gold = 0;
    int gems = 0;
    Map<String, dynamic>? stats;

    if (_profile != null) {
      stats = _profile!['stats'] as Map<String, dynamic>?;
      final rawJob = _profile!['job'] ?? stats?['job'];
      final jobStr = (rawJob as String?) ?? 'warrior';
      job = PlayerJob.values.firstWhere(
        (e) => e.name == jobStr,
        orElse: () => PlayerJob.warrior,
      );
      name = (_profile!['name'] ?? stats?['name'] ?? 'Agent') as String;
      level = (_profile!['level'] ?? stats?['level'] ?? 1) as int;
      gold = (stats?['gold'] as int?) ?? 0;
      gems = (stats?['gems'] as int?) ?? 0;
    }

    final partySlots = _buildPartySlots(
      stats: stats,
      baseJob: job,
      baseName: name,
      baseLevel: level,
    );

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/raid/raid_world_bg.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.5),
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final isCompact = constraints.maxHeight < 420;
                if (_loading) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.cyanAccent),
                  );
                }
                return Column(
                  children: [
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: isCompact ? 4 : 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isCompact ? 4 : 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  height: isCompact ? 32 : 40,
                                  width: isCompact ? 32 : 40,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Colors.cyanAccent,
                                    ),
                                    color:
                                        Colors.black.withValues(alpha: 0.8),
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: GoogleFonts.orbitron(
                                        fontSize: isCompact ? 12 : 14,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      'Lv.$level • ${job.name}',
                                      style: GoogleFonts.robotoMono(
                                        fontSize: isCompact ? 9 : 11,
                                        color: Colors.white70,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          const Spacer(),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 8 : 10,
                              vertical: isCompact ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.diamond,
                                  color: Colors.purpleAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  gems.toString(),
                                  style: GoogleFonts.robotoMono(
                                    fontSize: isCompact ? 10 : 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isCompact ? 8 : 10,
                              vertical: isCompact ? 4 : 6,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.monetization_on,
                                  color: Colors.amberAccent,
                                  size: 16,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  gold.toString(),
                                  style: GoogleFonts.robotoMono(
                                    fontSize: isCompact ? 10 : 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: isCompact ? 12 : 24,
                          vertical: isCompact ? 4 : 8,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildPartyGrid(
                              partySlots,
                              compact: isCompact,
                            ),
                            Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceEvenly,
                                  children: [
                                    _sideMenuButton(
                                      icon: Icons.shopping_cart,
                                      label: 'Store',
                                      onTap: () {
                                        context.push(
                                          '/feature',
                                          extra: {
                                            'title': 'Store',
                                            'description':
                                                'Di Store kamu nanti bisa beli bundle dan offer spesial.',
                                          },
                                        );
                                      },
                                    ),
                                    _sideMenuButton(
                                      icon: Icons.auto_fix_high,
                                      label: 'Fusing',
                                      onTap: () {
                                        context.push(
                                          '/feature',
                                          extra: {
                                            'title': 'Fusing',
                                            'description':
                                                'Fusing akan dipakai untuk menggabungkan item menjadi lebih kuat.',
                                          },
                                        );
                                      },
                                    ),
                                    _sideMenuButton(
                                      icon: Icons.public,
                                      label: 'World',
                                      onTap: () {
                                        context.push(
                                          '/feature',
                                          extra: {
                                            'title': 'World',
                                            'description':
                                                'World akan menampilkan peta dan stage-stage Cyber Raid.',
                                          },
                                        );
                                      },
                                    ),
                                  ],
                                ),
                                SizedBox(height: isCompact ? 8 : 16),
                                _buildCampaignSection(job, isCompact),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: isCompact ? 6 : 8,
                      ),
                      color: Colors.black.withValues(alpha: 0.7),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          _bottomMenuItem(
                            icon: Icons.storefront,
                            label: 'Shop',
                            onTap: () {
                              context.push(
                                '/feature',
                                extra: {
                                  'title': 'Shop',
                                  'description':
                                      'Shop berisi item harian, coin, dan resource lain.',
                                },
                              );
                            },
                          ),
                          _bottomMenuItem(
                            icon: Icons.auto_awesome,
                            label: 'Summon',
                            onTap: () async {
                              await context.push(
                                '/summon',
                                extra: {
                                  'childId': widget.childId,
                                },
                              );
                              await _loadProfile();
                            },
                          ),
                          _bottomMenuItem(
                            icon: Icons.sports_martial_arts,
                            label: 'Ninja',
                            onTap: () {
                              context.push(
                                '/ninja',
                                extra: {
                                  'childId': widget.childId,
                                },
                              );
                            },
                          ),
                          _bottomMenuItem(
                            icon: Icons.inventory_2,
                            label: 'Bag',
                            onTap: _openBag,
                          ),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  List<_HeroSlotData> _buildPartySlots({
    required Map<String, dynamic>? stats,
    required PlayerJob baseJob,
    required String baseName,
    required int baseLevel,
  }) {
    final slots = List<_HeroSlotData>.generate(
      6,
      (_) => _HeroSlotData(
        name: 'Empty',
        level: 0,
        job: baseJob,
        rarity: 'common',
        unlocked: false,
      ),
    );

    final party = stats?['party'] as List<dynamic>?;
    if (party != null && party.isNotEmpty) {
      for (final entry in party) {
        if (entry is! Map<String, dynamic>) continue;
        final slotIndex = (entry['slot'] as int?) ?? 0;
        if (slotIndex < 0 || slotIndex >= slots.length) continue;
        final jobStr = (entry['job'] as String?) ?? baseJob.name;
        final eJob = PlayerJob.values.firstWhere(
          (e) => e.name == jobStr,
          orElse: () => baseJob,
        );
        final heroName = (entry['name'] as String?) ?? baseName;
        final heroLevel = (entry['level'] as int?) ?? baseLevel;
        final rarity = (entry['rarity'] as String?) ?? 'common';
        slots[slotIndex] = _HeroSlotData(
          name: heroName,
          level: heroLevel,
          job: eJob,
          rarity: rarity,
          unlocked: true,
        );
      }
    } else {
      slots[0] = _HeroSlotData(
        name: baseName,
        level: baseLevel,
        job: baseJob,
        rarity: 'common',
        unlocked: true,
      );
    }

    return slots;
  }

  Widget _buildCampaignSection(PlayerJob job, bool compact) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CAMPAIGN',
          style: GoogleFonts.orbitron(
            fontSize: compact ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: Colors.white,
            shadows: const [
              Shadow(
                color: Colors.black,
                blurRadius: 12,
              ),
            ],
          ),
        ),
        SizedBox(height: compact ? 4 : 8),
        Text(
          'Tap to start mission',
          style: GoogleFonts.robotoMono(
            fontSize: compact ? 10 : 12,
            color: Colors.white70,
          ),
        ),
        SizedBox(height: compact ? 8 : 16),
        GestureDetector(
          onTap: () {
            context.go(
              '/raid',
              extra: {
                'childId': widget.childId,
                'job': job,
              },
            );
          },
          child: Container(
            width: compact ? 180 : 220,
            height: compact ? 56 : 80,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.cyanAccent,
                width: 2,
              ),
            ),
            alignment: Alignment.center,
            child: Text(
              'START',
              style: GoogleFonts.orbitron(
                fontSize: compact ? 20 : 24,
                fontWeight: FontWeight.bold,
                color: Colors.cyanAccent,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPartyGrid(
    List<_HeroSlotData> slots, {
    required bool compact,
  }) {
    return Column(
      children: [
        Row(
          children: List.generate(3, (index) {
            final slot = slots[index];
            return Expanded(
              child: _heroSlot(slot, compact),
            );
          }),
        ),
        SizedBox(height: compact ? 4 : 12),
        Row(
          children: List.generate(3, (index) {
            final slot = slots[index + 3];
            return Expanded(
              child: _heroSlot(slot, compact),
            );
          }),
        ),
      ],
    );
  }

  Widget _heroSlot(_HeroSlotData slot, bool compact) {
    final locked = !slot.unlocked;
    Color color;
    switch (slot.job) {
      case PlayerJob.warrior:
        color = Colors.redAccent;
        break;
      case PlayerJob.mage:
        color = Colors.blueAccent;
        break;
      case PlayerJob.archer:
        color = Colors.greenAccent;
        break;
      case PlayerJob.assassin:
        color = Colors.purpleAccent;
        break;
    }

    Color rarityColor;
    switch (slot.rarity) {
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

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: 4,
        vertical: compact ? 4 : 8,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: 8,
              vertical: compact ? 1 : 2,
            ),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  locked ? Icons.lock : Icons.shield,
                  color: locked ? Colors.grey : color,
                  size: 14,
                ),
                const SizedBox(width: 4),
                Text(
                  locked ? 'Locked' : 'Lv.${slot.level}',
                  style: GoogleFonts.robotoMono(
                    fontSize: compact ? 9 : 10,
                    color: Colors.white,
                  ),
                ),
                if (!locked) ...[
                  const SizedBox(width: 4),
                  Text(
                    slot.rarity.toUpperCase(),
                    style: GoogleFonts.robotoMono(
                      fontSize: compact ? 9 : 10,
                      color: rarityColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
          SizedBox(height: compact ? 4 : 6),
          Container(
            width: compact ? 52 : 64,
            height: compact ? 52 : 64,
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.7),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: locked ? Colors.grey : color,
                width: 2,
              ),
            ),
            child: Icon(
              locked ? Icons.add : Icons.person,
              color: locked ? Colors.grey : color,
              size: compact ? 26 : 32,
            ),
          ),
          SizedBox(height: compact ? 2 : 4),
          Text(
            locked ? 'Empty' : slot.name,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.robotoMono(
              fontSize: compact ? 9 : 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sideMenuButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.robotoMono(
                fontSize: 11,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _bottomMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white),
          const SizedBox(height: 2),
          Text(
            label,
            style: GoogleFonts.robotoMono(
              fontSize: 11,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openBag() async {
    PlayerJob job = PlayerJob.warrior;
    String name = 'Agent';
    Map<String, dynamic>? stats;

    if (_profile != null) {
      stats = _profile!['stats'] as Map<String, dynamic>?;
      final rawJob = _profile!['job'] ?? stats?['job'];
      final jobStr = (rawJob as String?) ?? 'warrior';
      job = PlayerJob.values.firstWhere(
        (e) => e.name == jobStr,
        orElse: () => PlayerJob.warrior,
      );
      name = (_profile!['name'] ?? stats?['name'] ?? 'Agent') as String;
    }

    final bagPlayer = RaidPlayer.create(widget.childId, name, job);
    final equipmentSystem = EquipmentSystem();

    final party = stats?['party'] as List<dynamic>? ?? [];
    int index = 0;
    for (final entry in party) {
      if (entry is! Map<String, dynamic>) continue;
      final code = entry['equipment']?.toString() ?? 'none';
      if (code == 'none') continue;
      final item = _equipmentFromCode(code, index);
      bagPlayer.equip(item);
      index++;
    }

    await showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        if (bagPlayer.equipment.isEmpty) {
          return Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.9),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
              border: Border.all(color: Colors.cyanAccent),
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Bag',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Belum ada equipment di Bag kamu.\nCoba lengkapi ninja kamu dulu.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.robotoMono(
                      fontSize: 12,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final screenHeight = MediaQuery.of(context).size.height;
        final sheetHeight = (screenHeight * 0.7).clamp(280.0, 420.0);

        return Center(
          child: SizedBox(
            height: sheetHeight,
            child: InventoryWidget(
              player: bagPlayer,
              onEquip: (_) {},
              onMerge: (a, b) {
                equipmentSystem.merge(bagPlayer, a, b);
              },
            ),
          ),
        );
      },
    );
  }

  RaidEquipment _equipmentFromCode(String code, int index) {
    switch (code) {
      case 'atk_25':
        return RaidEquipment(
          id: 'atk_25_$index',
          name: '+25 ATK Katana',
          type: EquipmentType.weapon,
          rarity: Rarity.legendary,
          attackBonus: 25,
        );
      case 'atk_10':
      default:
        return RaidEquipment(
          id: 'atk_10_$index',
          name: '+10 ATK Blade',
          type: EquipmentType.weapon,
          rarity: Rarity.rare,
          attackBonus: 10,
        );
    }
  }
}

class _HeroSlotData {
  final String name;
  final int level;
  final PlayerJob job;
  final String rarity;
  final bool unlocked;

  _HeroSlotData({
    required this.name,
    required this.level,
    required this.job,
    required this.rarity,
    required this.unlocked,
  });
}
