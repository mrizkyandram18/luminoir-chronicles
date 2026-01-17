import 'package:flutter/material.dart';
import 'dart:async';
import '../services/multiplayer_service.dart';
import '../models/room_model.dart';
import 'game_board_screen_enhanced.dart';

/// Waiting room screen where players wait for host to start
class WaitingRoomScreen extends StatefulWidget {
  final String roomId;
  final String roomCode;
  final String childId;
  final bool isHost;
  final MultiplayerService? multiplayerService;

  const WaitingRoomScreen({
    super.key,
    required this.roomId,
    required this.roomCode,
    required this.childId,
    required this.isHost,
    this.multiplayerService,
  });

  @override
  State<WaitingRoomScreen> createState() => _WaitingRoomScreenState();
}

class _WaitingRoomScreenState extends State<WaitingRoomScreen> {
  late final MultiplayerService _multiplayerService;
  StreamSubscription? _roomSubscription;
  StreamSubscription? _playersSubscription;

  GameRoom? _currentRoom;
  List<RoomPlayer> _players = [];
  bool _isStarting = false;

  @override
  void initState() {
    super.initState();
    _multiplayerService = widget.multiplayerService ?? MultiplayerService();
    _subscribeToRoom();
    _subscribeToPlayers();
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _playersSubscription?.cancel();
    super.dispose();
  }

  void _subscribeToRoom() {
    _roomSubscription = _multiplayerService
        .getRoomStream(widget.roomId)
        .listen(
          (room) {
            setState(() => _currentRoom = room);

            // Auto-navigate when game starts
            if (room.isPlaying && !_isStarting) {
              _navigateToGame();
            }
          },
          onError: (error) {
            debugPrint("Error listening to room: $error");
          },
        );
  }

  void _subscribeToPlayers() {
    _playersSubscription = _multiplayerService
        .getPlayersStream(widget.roomId)
        .listen(
          (players) {
            setState(() => _players = players);
          },
          onError: (error) {
            debugPrint("Error listening to players: $error");
          },
        );
  }

  Future<void> _startGame() async {
    if (_players.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Need at least 2 players to start')),
      );
      return;
    }

    setState(() => _isStarting = true);

    try {
      await _multiplayerService.startGame(widget.roomId);
      // Navigation will happen via stream listener
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error starting game: $e'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isStarting = false);
    }
  }

  void _navigateToGame() {
    // TODO: GameBoardScreen uses Provider pattern, not direct params
    // Will be updated when GameController multiplayer integration is complete
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameBoardScreenEnhanced()),
    );
  }

  Future<void> _leaveRoom() async {
    await _multiplayerService.leaveRoom(
      roomId: widget.roomId,
      childId: widget.childId,
    );

    if (mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final connectedPlayers = _players.where((p) => p.isConnected).length;

    final navigator = Navigator.of(context);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) {
          _leaveRoom().then((_) {
            if (mounted) navigator.pop();
          });
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Waiting Room'),
          backgroundColor: const Color(0xFF1A1A2E),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveRoom,
          ),
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
            ),
          ),
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Room Code Display
                  _buildRoomCodeCard(),
                  const SizedBox(height: 32),

                  // Players List
                  _buildPlayersCard(),
                  const SizedBox(height: 32),

                  // Status / Action Button
                  if (widget.isHost)
                    _buildHostControls(connectedPlayers)
                  else
                    _buildGuestStatus(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoomCodeCard() {
    return Card(
      color: const Color(0xFF16213E).withValues(alpha: 0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'ROOM CODE',
              style: TextStyle(
                fontSize: 16,
                color: Colors.white54,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              widget.roomCode,
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00D9FF),
                letterSpacing: 12,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Share this code with other players',
              style: TextStyle(fontSize: 12, color: Colors.white38),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayersCard() {
    final maxPlayers = _currentRoom?.maxPlayers ?? 4;

    return Card(
      color: const Color(0xFF16213E).withValues(alpha: 0.9),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'PLAYERS',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  '${_players.where((p) => p.isConnected).length}/$maxPlayers',
                  style: const TextStyle(
                    fontSize: 16,
                    color: Color(0xFF00D9FF),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ..._players.asMap().entries.map((entry) {
              final index = entry.key;
              final player = entry.value;
              return _buildPlayerTile(player, index + 1);
            }),
            // Empty slots
            for (int i = _players.length; i < maxPlayers; i++)
              _buildEmptySlot(i + 1),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerTile(RoomPlayer player, int number) {
    final isMe = player.childId == widget.childId;
    final isHost = player.childId == _currentRoom?.hostChildId;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: player.isConnected
            ? Colors.black26
            : Colors.red.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMe ? const Color(0xFF00D9FF) : Colors.white12,
          width: isMe ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Player Number & Color
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: player.playerColor,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Player Name
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.playerName,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (isMe) ...[
                      const SizedBox(width: 8),
                      const Text(
                        '(You)',
                        style: TextStyle(
                          fontSize: 12,
                          color: Color(0xFF00D9FF),
                        ),
                      ),
                    ],
                  ],
                ),
                if (isHost)
                  const Text(
                    'HOST',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.amber,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          // Status Icon
          Icon(
            player.isConnected ? Icons.check_circle : Icons.cancel,
            color: player.isConnected ? Colors.green : Colors.red,
            size: 20,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptySlot(int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black12,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white12,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(fontSize: 18, color: Colors.white24),
              ),
            ),
          ),
          const SizedBox(width: 12),
          const Text(
            'Waiting for player...',
            style: TextStyle(
              fontSize: 16,
              color: Colors.white38,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHostControls(int connectedPlayers) {
    final canStart = connectedPlayers >= 2 && !_isStarting;

    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 50,
          child: ElevatedButton(
            onPressed: canStart ? _startGame : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF00D9FF),
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: _isStarting
                ? const CircularProgressIndicator(color: Colors.black)
                : const Text(
                    'START GAME',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
          ),
        ),
        if (connectedPlayers < 2)
          const Padding(
            padding: EdgeInsets.only(top: 8),
            child: Text(
              'Need at least 2 players',
              style: TextStyle(fontSize: 12, color: Colors.amber),
            ),
          ),
      ],
    );
  }

  Widget _buildGuestStatus() {
    return const Card(
      color: Color(0xFF16213E),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(color: Color(0xFF00D9FF), strokeWidth: 2),
            SizedBox(width: 16),
            Text(
              'Waiting for host to start...',
              style: TextStyle(fontSize: 16, color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
