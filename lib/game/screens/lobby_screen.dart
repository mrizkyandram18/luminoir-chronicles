import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../gatekeeper/gatekeeper_service.dart';
import '../services/multiplayer_service.dart';
import 'waiting_room_screen.dart';

/// Lobby screen for creating or joining multiplayer rooms
class LobbyScreen extends StatefulWidget {
  final String parentId;
  final String childId;
  final MultiplayerService? multiplayerService;

  const LobbyScreen({
    super.key,
    required this.parentId,
    required this.childId,
    this.multiplayerService,
  });

  @override
  State<LobbyScreen> createState() => _LobbyScreenState();
}

class _LobbyScreenState extends State<LobbyScreen> {
  final _roomCodeController = TextEditingController();
  late final MultiplayerService _multiplayerService;
  bool _isLoading = false;
  int _selectedMaxPlayers = 2;

  @override
  void initState() {
    super.initState();
    _multiplayerService = widget.multiplayerService ?? MultiplayerService();
  }

  @override
  void dispose() {
    _roomCodeController.dispose();
    super.dispose();
  }

  Future<void> _createRoom() async {
    setState(() => _isLoading = true);

    try {
      final gatekeeper = context.read<GatekeeperService>();
      final displayName = gatekeeper.displayName ?? 'Player 1';

      final roomCode = await _multiplayerService.createRoom(
        hostChildId: widget.childId,
        maxPlayers: _selectedMaxPlayers,
      );

      // Join room as host
      await _multiplayerService.joinRoom(
        roomCode: roomCode,
        childId: widget.childId,
        playerName: displayName,
        playerColor: Colors.blue,
      );

      if (!mounted) return;

      // Get room ID
      final room = await _multiplayerService.getRoomByCode(roomCode);
      if (room == null) throw Exception('Room not found');

      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            roomId: room.id,
            roomCode: roomCode,
            childId: widget.childId,
            isHost: true,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error creating room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _joinRoom() async {
    final code = _roomCodeController.text.trim().toUpperCase();
    if (code.isEmpty || code.length != 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-character room code')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gatekeeper = context.read<GatekeeperService>();
      final displayName = gatekeeper.displayName ?? 'Player';

      // Check if room exists
      final room = await _multiplayerService.getRoomByCode(code);
      if (room == null) {
        throw Exception('Room not found');
      }

      if (!room.isWaiting) {
        throw Exception('Game already started');
      }

      // Join room
      await _multiplayerService.joinRoom(
        roomCode: code,
        childId: widget.childId,
        playerName: displayName,
        playerColor: Colors.red,
      );

      if (!mounted) return;

      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => WaitingRoomScreen(
            roomId: room.id,
            roomCode: code,
            childId: widget.childId,
            isHost: false,
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error joining room: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Multiplayer Lobby'),
        backgroundColor: const Color(0xFF1A1A2E),
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
                // Title
                const Text(
                  'MULTIPLAYER',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF00D9FF),
                  ),
                ),
                const SizedBox(height: 48),

                // Create Room Section
                _buildCreateRoomCard(),
                const SizedBox(height: 32),

                // OR Divider
                const Row(
                  children: [
                    Expanded(child: Divider(color: Colors.white24)),
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'OR',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    Expanded(child: Divider(color: Colors.white24)),
                  ],
                ),
                const SizedBox(height: 32),

                // Join Room Section
                _buildJoinRoomCard(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCreateRoomCard() {
    return Card(
      color: const Color(0xFF16213E).withValues(alpha: 0.8),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Create New Room',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Max Players Selector
            const Text('Max Players', style: TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            SegmentedButton<int>(
              segments: const [
                ButtonSegment(value: 2, label: Text('2')),
                ButtonSegment(value: 3, label: Text('3')),
                ButtonSegment(value: 4, label: Text('4')),
              ],
              selected: {_selectedMaxPlayers},
              onSelectionChanged: (Set<int> newSelection) {
                setState(() => _selectedMaxPlayers = newSelection.first);
              },
            ),
            const SizedBox(height: 24),

            // Create Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _createRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF00D9FF),
                  foregroundColor: Colors.black,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.black)
                    : const Text(
                        'CREATE ROOM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJoinRoomCard() {
    return Card(
      color: const Color(0xFF16213E).withValues(alpha: 0.8),
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const Text(
              'Join Existing Room',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Room Code Input
            TextField(
              controller: _roomCodeController,
              maxLength: 6,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                letterSpacing: 8,
                color: Colors.white,
              ),
              decoration: InputDecoration(
                hintText: 'ABC123',
                hintStyle: const TextStyle(color: Colors.white24),
                filled: true,
                fillColor: Colors.black26,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF00D9FF)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(
                    color: Color(0xFF00D9FF),
                    width: 2,
                  ),
                ),
                counterText: '',
              ),
              textCapitalization: TextCapitalization.characters,
            ),
            const SizedBox(height: 24),

            // Join Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _joinRoom,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFF6B6B),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : const Text(
                        'JOIN ROOM',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
