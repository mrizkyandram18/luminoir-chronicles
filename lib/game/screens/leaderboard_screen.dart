import 'package:flutter/material.dart';
import '../services/leaderboard_service.dart';
import '../models/player_model.dart';

class LeaderboardScreen extends StatefulWidget {
  final LeaderboardService leaderboardService;
  final String currentUserId;

  const LeaderboardScreen({
    super.key,
    required this.leaderboardService,
    required this.currentUserId,
  });

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Player> _globalPlayers = [];
  List<Player> _friendPlayers = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _fetchData();
  }

  Future<void> _fetchData() async {
    setState(() => _isLoading = true);

    // Fetch Global
    final global = await widget.leaderboardService.fetchGlobalLeaderboard();

    // Fetch Friends (Mocking friend IDs for now)
    final friends = await widget.leaderboardService.fetchFriendLeaderboard([
      'p2',
      'p3',
    ]);

    if (mounted) {
      setState(() {
        _globalPlayers = global;
        _friendPlayers = friends;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(16),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.9),
          border: Border.all(color: Colors.cyanAccent, width: 2),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.5),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Header
            Text(
              "NEURO-NET RANKINGS",
              style: TextStyle(
                color: Colors.cyanAccent,
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 2,
                shadows: [Shadow(color: Colors.blue, blurRadius: 10)],
              ),
            ),
            const SizedBox(height: 16),

            // Tabs
            TabBar(
              controller: _tabController,
              indicatorColor: Colors.pinkAccent,
              labelColor: Colors.pinkAccent,
              unselectedLabelColor: Colors.white70,
              labelStyle: const TextStyle(fontWeight: FontWeight.bold),
              tabs: const [
                Tab(text: "GLOBAL GRID"),
                Tab(text: "LOCAL NODE"),
              ],
            ),
            const SizedBox(height: 16),

            // Content
            Expanded(
              child: _isLoading
                  ? const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyanAccent,
                      ),
                    )
                  : TabBarView(
                      controller: _tabController,
                      children: [
                        _buildList(_globalPlayers),
                        _buildList(_friendPlayers),
                      ],
                    ),
            ),

            // Close Button
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              style: TextButton.styleFrom(
                foregroundColor: Colors.redAccent,
                textStyle: const TextStyle(letterSpacing: 1.5),
              ),
              child: const Text("[ DISCONNECT ]"),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildList(List<Player> players) {
    if (players.isEmpty) {
      return const Center(
        child: Text("No Data Found", style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.builder(
      itemCount: players.length,
      itemBuilder: (context, index) {
        final player = players[index];
        final isMe = player.id == widget.currentUserId;

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isMe
                ? Colors.cyanAccent.withValues(alpha: 0.1)
                : Colors.white.withValues(alpha: 0.05),
            border: Border(
              left: BorderSide(color: _getRankColor(index), width: 4),
            ),
          ),
          child: Row(
            children: [
              // Rank #
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  "#${index + 1}",
                  style: TextStyle(
                    color: _getRankColor(index),
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Title
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      player.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      player.rankTitle.toUpperCase(),
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.5),
                        fontSize: 10,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Points
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    "${player.rankPoints} PTS",
                    style: const TextStyle(
                      color: Colors.amberAccent,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    "W:${player.wins} L:${player.losses}",
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getRankColor(int index) {
    switch (index) {
      case 0:
        return const Color(0xFFFFD700); // Gold
      case 1:
        return const Color(0xFFC0C0C0); // Silver
      case 2:
        return const Color(0xFFCD7F32); // Bronze
      default:
        return Colors.cyanAccent.withValues(alpha: 0.5);
    }
  }
}
