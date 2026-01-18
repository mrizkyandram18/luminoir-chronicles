import 'package:flutter/material.dart';
import 'dart:async';
import 'package:google_fonts/google_fonts.dart';
import 'package:gap/gap.dart';
import '../services/multiplayer_service.dart';
import '../models/room_model.dart';
import 'game_board_screen.dart';

/// Waiting room screen in Classic Monopoly Style
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

  // Classic Monopoly Colors
  static const Color boardBeige = Color(0xFFE2E2E2);
  static const Color boardBlack = Colors.black;

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
    _roomSubscription = _multiplayerService.getRoomStream(widget.roomId).listen(
      (room) {
        setState(() => _currentRoom = room);
        if (room.isPlaying && !_isStarting) {
          _navigateToGame();
        }
      },
      onError: (error) => debugPrint("Error listening to room: $error"),
    );
  }

  void _subscribeToPlayers() {
    _playersSubscription = _multiplayerService
        .getPlayersStream(widget.roomId)
        .listen(
          (players) {
            setState(() => _players = players);
          },
          onError: (error) => debugPrint("Error listening to players: $error"),
        );
  }

  Future<void> _startGame() async {
    if (_players.length < 2) {
      _showClassicSnackBar('Need at least 2 players to start');
      return;
    }

    setState(() => _isStarting = true);
    try {
      await _multiplayerService.startGame(widget.roomId);
    } catch (e) {
      if (!mounted) return;
      _showClassicSnackBar('Error starting game: $e');
      setState(() => _isStarting = false);
    }
  }

  void _navigateToGame() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameBoardScreen()),
    );
  }

  Future<void> _leaveRoom() async {
    await _multiplayerService.leaveRoom(
      roomId: widget.roomId,
      childId: widget.childId,
    );
    if (mounted) Navigator.of(context).pop();
  }

  void _showClassicSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: GoogleFonts.philosopher(color: Colors.white),
        ),
        backgroundColor: boardBlack,
      ),
    );
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
        backgroundColor: boardBeige,
        appBar: AppBar(
          title: Text(
            'WAITING FOR PLAYERS',
            style: GoogleFonts.philosopher(fontWeight: FontWeight.bold),
          ),
          backgroundColor: Colors.white,
          foregroundColor: boardBlack,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _leaveRoom,
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(2),
            child: Container(color: boardBlack, height: 2),
          ),
        ),
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                children: [
                  _buildRoomCodeCard(),
                  const Gap(32),
                  _buildPlayersCard(),
                  const Gap(32),
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
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        children: [
          Text(
            'OFFICIAL ROOM CODE',
            style: GoogleFonts.philosopher(
              fontSize: 12,
              color: Colors.grey[700],
              fontWeight: FontWeight.bold,
              letterSpacing: 1,
            ),
          ),
          const Gap(10),
          Text(
            widget.roomCode,
            style: GoogleFonts.robotoMono(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: boardBlack,
              letterSpacing: 10,
            ),
          ),
          const Gap(10),
          Text(
            'Share this with invited tycoons',
            style: GoogleFonts.philosopher(
              fontSize: 11,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlayersCard() {
    final maxPlayers = _currentRoom?.maxPlayers ?? 4;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 3),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(4, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'ENROLLED PLAYERS',
                style: GoogleFonts.philosopher(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
              Text(
                '${_players.where((p) => p.isConnected).length}/$maxPlayers',
                style: GoogleFonts.philosopher(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const Gap(8),
          const Divider(color: boardBlack, thickness: 1.5),
          const Gap(16),
          ..._players.asMap().entries.map(
            (entry) => _buildPlayerTile(entry.value, entry.key + 1),
          ),
          for (int i = _players.length; i < maxPlayers; i++)
            _buildEmptySlot(i + 1),
        ],
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
        color: Colors.white,
        border: Border.all(color: boardBlack, width: isMe ? 2 : 1),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: player.playerColor,
              border: Border.all(color: boardBlack, width: 1),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      player.playerName.toUpperCase(),
                      style: GoogleFonts.philosopher(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    if (isMe) ...[
                      const Gap(8),
                      Text(
                        '(YOU)',
                        style: GoogleFonts.philosopher(
                          fontSize: 10,
                          color: Colors.blue[800],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isHost)
                  Text(
                    'HOST',
                    style: GoogleFonts.philosopher(
                      fontSize: 10,
                      color: Colors.amber[900],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ),
          Icon(
            player.isConnected
                ? Icons.check_circle_outline
                : Icons.highlight_off,
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
        color: Colors.grey[100],
        border: Border.all(
          color: Colors.grey[400]!,
          width: 1,
          style: BorderStyle.solid,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              border: Border.all(color: Colors.grey[400]!, width: 1),
            ),
            child: Center(
              child: Text(
                '$number',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          ),
          const Gap(12),
          Text(
            'WAITING FOR PLAYER...',
            style: GoogleFonts.philosopher(
              fontSize: 13,
              color: Colors.grey,
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
        ElevatedButton(
          onPressed: canStart ? _startGame : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[800],
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: const RoundedRectangleBorder(
              side: BorderSide(color: boardBlack, width: 2),
            ),
            elevation: 8,
          ),
          child: _isStarting
              ? const CircularProgressIndicator(color: Colors.white)
              : Text(
                  'START SESSION',
                  style: GoogleFonts.philosopher(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        ),
        if (connectedPlayers < 2)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Requires minimum 2 players',
              style: GoogleFonts.philosopher(
                fontSize: 12,
                color: Colors.red[900],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildGuestStatus() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: boardBlack, width: 2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(color: boardBlack, strokeWidth: 2),
          ),
          const Gap(20),
          Text(
            'WAITING FOR HOST...',
            style: GoogleFonts.philosopher(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
