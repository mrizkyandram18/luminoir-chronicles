import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import '../../../services/supabase_service.dart';

class SummonScreen extends StatefulWidget {
  final String childId;

  const SummonScreen({super.key, required this.childId});

  @override
  State<SummonScreen> createState() => _SummonScreenState();
}

class _SummonScreenState extends State<SummonScreen> {
  bool _loading = true;
  bool _summoning = false;
  int _gold = 0;
  bool _freeAvailable = false;
  Map<String, dynamic>? _lastResult;

  SupabaseClient get _client => Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final todayKey = _todayKey;
    final storedDay = prefs.getString(_freeKey);

    final player = await _client
        .from('players')
        .select()
        .eq('id', widget.childId)
        .maybeSingle();

    int gold = 0;
    if (player == null) {
      await _client.from('players').insert({
        'id': widget.childId,
        'gold': 0,
        'last_login': DateTime.now().toUtc().toIso8601String(),
        'max_campaign_stage': 1,
      });
    } else {
      gold = (player['gold'] as int?) ?? 0;
    }

    if (!mounted) return;
    setState(() {
      _gold = gold;
      _freeAvailable = storedDay != todayKey;
      _loading = false;
    });
  }

  String get _freeKey => 'daily_free_summon_${widget.childId}';

  String get _todayKey {
    final now = DateTime.now().toUtc();
    return '${now.year}-${now.month}-${now.day}';
  }

  Future<void> _performSummon({required bool free}) async {
    if (_summoning || _loading) return;
    const cost = 1000;
    if (!free && _gold < cost) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gold tidak cukup untuk summon')),
      );
      return;
    }

    setState(() {
      _summoning = true;
    });

    try {
      int newGold = _gold;
      if (!free) {
        newGold -= cost;
        await _client
            .from('players')
            .update({'gold': newGold}).eq('id', widget.childId);
      }

      final result = await _client.rpc(
        'perform_gacha',
        params: {'pool_code': 'hero_core', 'count': 1},
      );

      Map<String, dynamic>? first;
      if (result is List && result.isNotEmpty) {
        first = Map<String, dynamic>.from(
          result.first as Map<dynamic, dynamic>,
        );
      }

      if (free && first != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_freeKey, _todayKey);
        _freeAvailable = false;
      }

      if (!mounted) return;
      setState(() {
        _gold = newGold;
        _lastResult = first;
      });

      if (first != null && mounted) {
        final supabase = context.read<SupabaseService>();
        final profile = await supabase.getPlayerProfile(widget.childId);

        String job = 'warrior';
        int level = 1;
        if (profile != null) {
          final stats = (profile['stats'] as Map<String, dynamic>?) ??
              <String, dynamic>{};
          final rawJob = profile['job'] ?? stats['job'];
          job = (rawJob as String?) ?? 'warrior';
          level = (stats['level'] as int?) ?? 1;
        }

        final itemCode = first['item_code']?.toString() ?? 'Summoned Hero';
        final rarity = first['rarity']?.toString() ?? 'common';

        int baseAttack;
        int baseHp;
        switch (rarity) {
          case 'legendary':
            baseAttack = 50;
            baseHp = 300;
            break;
          case 'epic':
            baseAttack = 30;
            baseHp = 220;
            break;
          case 'rare':
            baseAttack = 15;
            baseHp = 180;
            break;
          default:
            baseAttack = 5;
            baseHp = 150;
            break;
        }
        final attack = baseAttack + level * 2;
        final hp = baseHp + level * 10;

        await supabase.addPartyMember(
          playerId: widget.childId,
          hero: {
            'name': itemCode,
            'job': job,
            'level': level,
            'rarity': rarity,
            'attack': attack,
            'hp': hp,
          },
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Summon gagal: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _summoning = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(
          'Summon',
          style: GoogleFonts.orbitron(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.black,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: Colors.cyanAccent),
            )
          : Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Gold: $_gold',
                    style: GoogleFonts.orbitron(
                      fontSize: 20,
                      color: Colors.amberAccent,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed:
                        _freeAvailable && !_summoning ? () => _performSummon(free: true) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: Text(
                      _freeAvailable ? 'Free Summon (1x/hari)' : 'Free Summon sudah dipakai',
                      style: const TextStyle(color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: !_summoning ? () => _performSummon(free: false) : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.purpleAccent,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 12,
                      ),
                    ),
                    child: const Text('Summon 1x (1000 gold)'),
                  ),
                  const SizedBox(height: 32),
                  if (_lastResult != null)
                    _SummonResultCard(result: _lastResult!),
                ],
              ),
            ),
    );
  }
}

class _SummonResultCard extends StatelessWidget {
  final Map<String, dynamic> result;

  const _SummonResultCard({required this.result});

  @override
  Widget build(BuildContext context) {
    final itemCode = result['item_code']?.toString() ?? 'Unknown';
    final rarity = result['rarity']?.toString() ?? 'common';
    final rarityColor = _rarityColor(rarity);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: rarityColor, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Hasil Summon',
            style: GoogleFonts.orbitron(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            itemCode,
            style: GoogleFonts.orbitron(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: rarityColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            rarity.toUpperCase(),
            style: GoogleFonts.robotoMono(
              fontSize: 12,
              color: rarityColor,
            ),
          ),
        ],
      ),
    );
  }

  Color _rarityColor(String rarity) {
    switch (rarity) {
      case 'rare':
        return Colors.blueAccent;
      case 'epic':
        return Colors.purpleAccent;
      case 'legendary':
        return Colors.orangeAccent;
      default:
        return Colors.grey;
    }
  }
}
