import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../models/raid_player.dart';
import '../models/raid_equipment.dart';
import '../widgets/inventory_widget.dart';
import '../systems/equipment_system.dart';
import '../systems/save_system.dart';
import '../systems/idle_system.dart';
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
  final TextEditingController _chatController = TextEditingController();
  late SaveSystem _saveSystem;

  @override
  void initState() {
    super.initState();
    final idleSystem = IdleRewardSystem();
    _saveSystem = SaveSystem(idleRewardSystem: idleSystem);
    _loadProfile();
  }

  @override
  void dispose() {
    _chatController.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    final supabase = context.read<SupabaseService>();

    // Process Idle Rewards before loading profile
    final snapshot = await _saveSystem.loadOrCreatePlayer(widget.childId);

    final data = await supabase.getPlayerProfile(widget.childId);
    if (!mounted) return;

    setState(() {
      _profile = data;
      _loading = false;
    });

    // Show Idle Reward Dialog if applicable
    if (snapshot.idleGoldGained > 0) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          _showIdleRewardDialog(snapshot.idleGoldGained);
        }
      });
    }
  }

  void _showIdleRewardDialog(int amount) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF2D241E), // Dark Wood/Leather color
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFFC5A059), // Muted Gold
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF000000).withValues(alpha: 0.5),
                blurRadius: 15,
                spreadRadius: 2,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Decorative header element (text-based for now)
              Text(
                '⚜️ WELCOME BACK ⚜️',
                style: GoogleFonts.cinzel(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFC5A059), // Gold
                  letterSpacing: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Divider(color: const Color(0xFFC5A059).withValues(alpha: 0.3), thickness: 1),
              const SizedBox(height: 16),
              Text(
                'While you were resting, your party gathered spoils:',
                textAlign: TextAlign.center,
                style: GoogleFonts.crimsonText(
                  fontSize: 16,
                  color: const Color(0xFFE0D8C8), // Parchment White
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1512), // Darker inset
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: const Color(0xFF5D4037),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.monetization_on, color: Color(0xFFFFD700), size: 36),
                    const SizedBox(width: 16),
                    Text(
                      '+$amount Gold',
                      style: GoogleFonts.cinzel(
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFFD700),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B0000), // Deep Red
                    foregroundColor: const Color(0xFFFFD700), // Gold text
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    side: const BorderSide(color: Color(0xFFC5A059), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'CLAIM SPOILS',
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1,
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

  void _showUpgradeDialog() {
    final snapshot = _saveSystem.currentPlayer;
    if (snapshot == null) return;

    final cost = _saveSystem.getNextUpgradeCost();
    final currentLevel = snapshot.accountPowerMultiplier;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          return Dialog(
            backgroundColor: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF2D241E), // Dark Wood
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFC5A059), width: 2),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'POWER UPGRADE',
                    style: GoogleFonts.cinzel(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFC5A059),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Current Power Level: $currentLevel',
                    style: GoogleFonts.crimsonText(
                      fontSize: 18,
                      color: const Color(0xFFE0D8C8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Effect: All Stats x${1.0 + ((currentLevel - 1) * 0.1)}',
                    style: GoogleFonts.crimsonText(
                      fontSize: 14,
                      color: Colors.white70,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.monetization_on, color: Color(0xFFFFD700)),
                      const SizedBox(width: 8),
                      Text(
                        '$cost Gold',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: snapshot.gold >= cost ? const Color(0xFFFFD700) : Colors.red,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: snapshot.gold >= cost
                          ? () async {
                              final success = await _saveSystem.upgradeAccountPower();
                              if (success) {
                                if (mounted) {
                                  // Refresh main UI
                                  setState(() {});
                                  // Refresh dialog UI
                                  setDialogState(() {});
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF8B0000),
                        disabledBackgroundColor: Colors.grey.shade800,
                        foregroundColor: const Color(0xFFFFD700),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Color(0xFFC5A059)),
                      ),
                      child: Text(
                        'UPGRADE',
                        style: GoogleFonts.cinzel(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
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
      // Prefer SaveSystem gold if available (single source of truth for idle/upgrades)
      if (_saveSystem.currentPlayer != null) {
        gold = _saveSystem.currentPlayer!.gold;
      } else {
        gold = (stats?['gold'] as int?) ?? 0;
      }
      gems = (stats?['gems'] as int?) ?? 0;
    }

    final partySlots = _buildPartySlots(
      stats: stats,
      baseJob: job,
      baseName: name,
      baseLevel: level,
    );
    final activeJob =
        partySlots.isNotEmpty && partySlots[0].unlocked ? partySlots[0].job : job;

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
                          GestureDetector(
                            onTap: _openProfileDialog,
                            child: Container(
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
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
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: _showUpgradeDialog,
                            child: Container(
                              padding: EdgeInsets.all(isCompact ? 4 : 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B0000).withValues(alpha: 0.8),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: const Color(0xFFC5A059),
                                ),
                              ),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.arrow_upward,
                                    color: Color(0xFFFFD700),
                                    size: 20,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'UPGRADE',
                                    style: GoogleFonts.cinzel(
                                      fontSize: isCompact ? 10 : 12,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFFFFD700),
                                    ),
                                  ),
                                  const SizedBox(width: 4),
                                ],
                              ),
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
                          horizontal: isCompact ? 8 : 16,
                          vertical: isCompact ? 4 : 8,
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            _buildLeftSidebar(isCompact, context),
                            Expanded(
                              child: Center(
                                child: _buildPartyGrid(
                                  partySlots,
                                  compact: isCompact,
                                ),
                              ),
                            ),
                            _buildRightSidebar(isCompact, context),
                          ],
                        ),
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: isCompact ? 12 : 16,
                        vertical: isCompact ? 6 : 8,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
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
                          SizedBox(width: isCompact ? 10 : 14),
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
                          SizedBox(width: isCompact ? 10 : 14),
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
                          SizedBox(width: isCompact ? 10 : 14),
                          _bottomMenuItem(
                            icon: Icons.inventory_2,
                            label: 'Bag',
                            onTap: _openBag,
                          ),
                          SizedBox(width: isCompact ? 10 : 14),
                          _bottomMenuItem(
                            icon: Icons.flag,
                            label: 'Campaign',
                            onTap: () {
                              context.go(
                                '/raid',
                                extra: {
                                  'childId': widget.childId,
                                  'job': activeJob,
                                },
                              );
                            },
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

  Future<void> _setActiveSlot(int slotIndex) async {
    final supabase = context.read<SupabaseService>();
    await supabase.swapPartySlots(
      playerId: widget.childId,
      fromSlot: slotIndex,
      toSlot: 0,
    );
    await _loadProfile();
  }

  Widget _buildPartyGrid(
    List<_HeroSlotData> slots, {
    required bool compact,
  }) {
    const columns = 3;
    const rows = 2;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(rows, (row) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: row == rows - 1 ? 0 : (compact ? 4 : 8),
          ),
          child: Row(
            children: List.generate(columns, (col) {
              final index = row * columns + col;
              final slot = slots[index];
              final isActive = index == 0 && slot.unlocked;
              return Expanded(
                child: GestureDetector(
                  onTap: slot.unlocked ? () => _setActiveSlot(index) : null,
                  child: _heroSlot(
                    slot,
                    compact,
                    isActive: isActive,
                  ),
                ),
              );
            }),
          ),
        );
      }),
    );
  }

  Widget _heroSlot(
    _HeroSlotData slot,
    bool compact, {
    required bool isActive,
  }) {
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

    IconData jobIcon;
    switch (slot.job) {
      case PlayerJob.warrior:
        jobIcon = Icons.security;
        break;
      case PlayerJob.mage:
        jobIcon = Icons.bolt;
        break;
      case PlayerJob.archer:
        jobIcon = Icons.gps_fixed;
        break;
      case PlayerJob.assassin:
        jobIcon = Icons.casino;
        break;
    }

    if (compact) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: locked
                      ? Colors.grey
                      : (isActive ? Colors.cyanAccent : color),
                  width: 2,
                ),
              ),
              child: locked
                  ? Icon(
                      Icons.add,
                      color: Colors.grey,
                      size: 24,
                    )
                  : ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/${_spritePathForJob(slot.job)}',
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            jobIcon,
                            color: color,
                            size: 24,
                          );
                        },
                      ),
                    ),
            ),
            const SizedBox(height: 2),
            Text(
              locked ? 'Empty' : slot.name,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.robotoMono(
                fontSize: 8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      );
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
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: locked ? Colors.grey : color.withValues(alpha: 0.2),
                    border: Border.all(
                      color: locked ? Colors.grey : color,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    locked ? Icons.lock : jobIcon,
                    color: locked ? Colors.black54 : color,
                    size: 12,
                  ),
                ),
                const SizedBox(width: 6),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      locked ? 'Locked' : 'Lv.${slot.level}',
                      style: GoogleFonts.robotoMono(
                        fontSize: 10,
                        color: Colors.white,
                      ),
                    ),
                    if (!locked)
                      Text(
                        slot.rarity.toUpperCase(),
                        style: GoogleFonts.robotoMono(
                          fontSize: 9,
                          color: rarityColor,
                        ),
                      ),
                  ],
                ),
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
                color: locked
                    ? Colors.grey
                    : (isActive ? Colors.cyanAccent : color),
                width: 2,
              ),
            ),
            child: locked
                ? Icon(
                    Icons.add,
                    color: Colors.grey,
                    size: compact ? 26 : 32,
                  )
                : ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: Image.asset(
                      'assets/images/${_spritePathForJob(slot.job)}',
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(
                          Icons.person,
                          color: color,
                          size: compact ? 26 : 32,
                        );
                      },
                    ),
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

  String _spritePathForJob(PlayerJob job) {
    switch (job) {
      case PlayerJob.warrior:
        return 'raid_sprites/warrior.png';
      case PlayerJob.mage:
        return 'raid_sprites/mage.png';
      case PlayerJob.archer:
        return 'raid_sprites/archer.png';
      case PlayerJob.assassin:
        return 'raid_sprites/assassin.png';
    }
  }

  Widget _buildLeftSidebar(bool compact, BuildContext context) {
    final width = compact ? 64.0 : 72.0;
    return Container(
      width: width,
      margin: EdgeInsets.only(left: compact ? 4 : 8),
      child: _buildLeftSocialButtons(compact, context),
    );
  }

  Widget _buildLeftSocialButtons(bool compact, BuildContext context) {
    final size = compact ? 32.0 : 38.0;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _leftCircleButton(
          icon: Icons.leaderboard,
          size: size,
          onTap: () {
            context.push(
              '/feature',
              extra: {
                'title': 'Leaderboard',
                'description':
                    'Leaderboard akan menampilkan peringkat pemain di Luminoir: Chronicles.',
              },
            );
          },
        ),
        SizedBox(height: compact ? 6 : 8),
        _leftCircleButton(
          icon: Icons.group,
          size: size,
          onTap: () {
            context.push(
              '/feature',
              extra: {
                'title': 'Friends',
                'description':
                    'Friends akan menampilkan daftar teman untuk bermain bersama.',
              },
            );
          },
        ),
        SizedBox(height: compact ? 6 : 8),
        _leftCircleButton(
          icon: Icons.mail,
          size: size,
          onTap: () {
            context.push(
              '/feature',
              extra: {
                'title': 'Mailbox',
                'description':
                    'Mailbox akan menampilkan pesan dan hadiah dari sistem.',
              },
            );
          },
        ),
        SizedBox(height: compact ? 6 : 8),
        _leftCircleButton(
          icon: Icons.chat_bubble,
          size: size,
          onTap: _openChat,
        ),
      ],
    );
  }

  Widget _leftCircleButton({
    required IconData icon,
    required double size,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.6),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: size * 0.55,
        ),
      ),
    );
  }

  Widget _buildRightSidebar(bool compact, BuildContext context) {
    return Container(
      margin: EdgeInsets.only(right: compact ? 4 : 8),
      padding: EdgeInsets.symmetric(
        vertical: compact ? 6 : 10,
        horizontal: compact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(26),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
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
            SizedBox(height: compact ? 6 : 8),
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
            SizedBox(height: compact ? 6 : 8),
            _sideMenuButton(
              icon: Icons.public,
              label: 'World',
              onTap: () {
                context.push(
                  '/feature',
                  extra: {
                    'title': 'World',
                    'description':
                        'World akan menampilkan peta dan stage-stage Luminoir: Chronicles.',
                  },
                );
              },
            ),
          ],
        ),
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
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(20),
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
        final screenHeight = MediaQuery.of(context).size.height;
        final sheetHeight = (screenHeight * 0.7).clamp(280.0, 420.0);

        if (bagPlayer.equipment.isEmpty) {
          return Center(
            child: Container(
              height: sheetHeight,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.95),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.cyanAccent),
              ),
              child: SafeArea(
                top: false,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                'Bag',
                                style: GoogleFonts.orbitron(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text(
                        'Belum ada equipment di Bag kamu.\nCoba lengkapi ninja kamu dulu.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return Center(
          child: Container(
            height: sheetHeight,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.95),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.cyanAccent),
            ),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(
                          Icons.arrow_back,
                          color: Colors.white70,
                        ),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                        },
                      ),
                      Expanded(
                        child: Center(
                          child: Text(
                            'Bag',
                            style: GoogleFonts.orbitron(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: InventoryWidget(
                    player: bagPlayer,
                    onEquip: (_) {},
                    onMerge: (a, b) {
                      equipmentSystem.merge(bagPlayer, a, b);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openChat() {
    final supabase = context.read<SupabaseService>();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      isScrollControlled: true,
      builder: (ctx) {
        String selectedChannel = 'world';

        Stream<List<Map<String, dynamic>>> streamForChannel(String channel) {
          switch (channel) {
            case 'private':
              return supabase.privateChatStream(widget.childId);
            case 'system':
              return supabase.systemChatStream();
            default:
              return supabase.worldChatStream();
          }
        }

        String labelForChannel(String channel) {
          switch (channel) {
            case 'private':
              return 'Private';
            case 'system':
              return 'System';
            default:
              return 'World';
          }
        }

        return StatefulBuilder(
          builder: (ctx, setState) {
            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 12,
                  right: 12,
                  top: 8,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 12,
                ),
                child: SizedBox(
                  height: MediaQuery.of(ctx).size.height * 0.6,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white70,
                            ),
                            onPressed: () {
                              Navigator.of(ctx).pop();
                            },
                          ),
                          Expanded(
                            child: Center(
                              child: Text(
                                '${labelForChannel(selectedChannel)} Chat',
                                style: GoogleFonts.orbitron(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          ChoiceChip(
                            label: const Text('World'),
                            selected: selectedChannel == 'world',
                            onSelected: (v) {
                              if (v) {
                                setState(() {
                                  selectedChannel = 'world';
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('Private'),
                            selected: selectedChannel == 'private',
                            onSelected: (v) {
                              if (v) {
                                setState(() {
                                  selectedChannel = 'private';
                                });
                              }
                            },
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: const Text('System'),
                            selected: selectedChannel == 'system',
                            onSelected: (v) {
                              if (v) {
                                setState(() {
                                  selectedChannel = 'system';
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Expanded(
                        child: StreamBuilder<List<Map<String, dynamic>>>(
                          stream: streamForChannel(selectedChannel),
                          builder: (context, snapshot) {
                            if (!snapshot.hasData) {
                              return const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.cyanAccent,
                                ),
                              );
                            }
                            var messages = snapshot.data!;
                            if (selectedChannel == 'private') {
                              final playerId = widget.childId;
                              messages = messages
                                  .where((msg) {
                                    final senderId =
                                        msg['sender_id']?.toString() ?? '';
                                    final targetId =
                                        msg['target_id']?.toString() ?? '';
                                    return senderId == playerId ||
                                        targetId == playerId;
                                  })
                                  .toList();
                            }
                            if (messages.isEmpty) {
                              return Center(
                                child: Text(
                                  'Belum ada pesan.\nMulai ngobrol duluan yuk.',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.robotoMono(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              );
                            }
                            return ListView.builder(
                              itemCount: messages.length,
                              itemBuilder: (context, index) {
                                final msg = messages[index];
                                final senderId =
                                    msg['sender_id']?.toString() ?? 'Player';
                                final content =
                                    msg['content']?.toString() ?? '';
                                return Padding(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 4,
                                    horizontal: 4,
                                  ),
                                  child: Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        radius: 10,
                                        backgroundColor: Colors.cyanAccent,
                                        child: Text(
                                          senderId.isNotEmpty
                                              ? senderId[0].toUpperCase()
                                              : '?',
                                          style: const TextStyle(
                                            fontSize: 10,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              senderId,
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 11,
                                                color: Colors.cyanAccent,
                                              ),
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              content,
                                              style: GoogleFonts.robotoMono(
                                                fontSize: 11,
                                                color: Colors.white,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _chatController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                hintText: 'Ketik pesan...',
                                hintStyle:
                                    const TextStyle(color: Colors.white54),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide:
                                      const BorderSide(color: Colors.white24),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(20),
                                  borderSide: const BorderSide(
                                    color: Colors.cyanAccent,
                                  ),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                              ),
                              onSubmitted: (_) =>
                                  _sendChatMessage(selectedChannel),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(
                              Icons.send,
                              color: Colors.cyanAccent,
                            ),
                            onPressed: () => _sendChatMessage(selectedChannel),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _sendChatMessage(String channel) async {
    final text = _chatController.text.trim();
    if (text.isEmpty) {
      return;
    }
    final supabase = context.read<SupabaseService>();
    await supabase.sendChatMessage(
      channel: channel,
      senderId: widget.childId,
      content: text,
    );
    _chatController.clear();
  }

  void _openProfileDialog() {
    if (_profile == null) {
      return;
    }
    final stats = _profile!['stats'] as Map<String, dynamic>?;
    final rawJob = _profile!['job'] ?? stats?['job'];
    final jobStr = (rawJob as String?) ?? 'warrior';
    final job = PlayerJob.values.firstWhere(
      (e) => e.name == jobStr,
      orElse: () => PlayerJob.warrior,
    );
    final name =
        (_profile!['name'] ?? stats?['name'] ?? 'Agent') as String;
    final level =
        (_profile!['level'] ?? stats?['level'] ?? 1) as int;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black.withValues(alpha: 0.95),
      isScrollControlled: true,
      builder: (ctx) {
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(
                        Icons.arrow_back,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        Navigator.of(ctx).pop();
                      },
                    ),
                    Expanded(
                      child: Center(
                        child: Text(
                          'Profile',
                          style: GoogleFonts.orbitron(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 48),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      height: 56,
                      width: 56,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.cyanAccent),
                        color: Colors.black.withValues(alpha: 0.8),
                      ),
                      child: const Icon(
                        Icons.person,
                        color: Colors.cyanAccent,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name,
                          style: GoogleFonts.orbitron(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Lv.$level • ${job.name}',
                          style: GoogleFonts.robotoMono(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.cyanAccent,
                          foregroundColor: Colors.black,
                        ),
                        child: const Text('Avatar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {},
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepPurpleAccent,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text('Frame'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white70,
                      side: const BorderSide(color: Colors.white24),
                    ),
                    child: const Text('Settings'),
                  ),
                ),
              ],
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
