import 'package:flutter/material.dart';
import '../models/player_model.dart';
import '../supabase_service.dart';

class LeaderboardService {
  final SupabaseService _supabase;
  final bool _useMock;

  LeaderboardService(this._supabase, {bool useMock = false})
    : _useMock = useMock;

  // Fetch Top 10 Global Players
  Future<List<Player>> fetchGlobalLeaderboard() async {
    if (_useMock) {
      return _generateMockLeaderboard();
    }

    try {
      // Assuming Supabase logic here, but using mock fallback for safety if DB schema isn't ready
      // final response = await _supabase.client
      //     .from('players')
      //     .select()
      //     .order('rank_points', ascending: false)
      //     .limit(10);
      // return (response as List).map((data) => Player.fromMap(data)).toList();
      return _generateMockLeaderboard();
    } catch (e) {
      print('Error fetching leaderboard: $e');
      return _generateMockLeaderboard();
    }
  }

  // Fetch Leaderboard for Friends
  Future<List<Player>> fetchFriendLeaderboard(List<String> friendIds) async {
    if (_useMock || friendIds.isEmpty) {
      return _generateMockLeaderboard().take(3).toList(); // Simple mock
    }

    try {
      // final response = await _supabase.client
      //     .from('players')
      //     .select()
      //     .in_('id', friendIds)
      //     .order('rank_points', ascending: false);
      // return (response as List).map((data) => Player.fromMap(data)).toList();
      return _generateMockLeaderboard();
    } catch (e) {
      print('Error fetching friend leaderboard: $e');
      return [];
    }
  }

  Future<void> updatePlayerStats(Player player) async {
    if (_useMock) return;

    try {
      await _supabase.upsertPlayer(player);
    } catch (e) {
      print('Error updating player stats: $e');
    }
  }

  List<Player> _generateMockLeaderboard() {
    return List.generate(10, (index) {
      int rankPoints = 2000 - (index * 150);
      return Player(
        id: 'mock_$index',
        name: _getCyberpunkName(index),
        color: _getNeonColor(index),
        rankPoints: rankPoints,
        wins: (rankPoints / 100).floor(),
        losses: (index * 2),
      );
    });
  }

  String _getCyberpunkName(int index) {
    const names = [
      'NeonGhost',
      'CyberViper',
      'DataDrifter',
      'GlitchKing',
      'VoidWalker',
      'SynthWave',
      'BitBreaker',
      'CodeRonin',
      'NetPulse',
      'ZeroDay',
    ];
    return names[index % names.length];
  }

  Color _getNeonColor(int index) {
    // Cyan, Magenta, Purple, Lime
    const colors = [
      Color(0xFF00E5FF), // Cyan
      Color(0xFFE500FF), // Magenta
      Color(0xFFAA00FF), // Purple
      Color(0xFF76FF03), // Lime Green
    ];
    return colors[index % colors.length];
  }
}
