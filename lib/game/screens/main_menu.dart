import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../gatekeeper/gatekeeper_service.dart';
import '../../game_identity/game_identity_service.dart';
import 'lobby_screen.dart';
import 'game_board_screen_enhanced.dart';
import '../game_controller.dart';
import 'package:provider/provider.dart';

class MainMenuScreen extends StatefulWidget {
  final String parentId;
  final String childId;

  const MainMenuScreen({
    super.key,
    required this.parentId,
    required this.childId,
  });

  @override
  State<MainMenuScreen> createState() => _MainMenuScreenState();
}

class _MainMenuScreenState extends State<MainMenuScreen> {
  final _nameController = TextEditingController();
  bool _isEditing = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final identity = context.read<GameIdentityService>();
    _nameController.text = identity.getName(widget.childId);
    identity.loadName(widget.childId).then((_) {
      if (!mounted) return;
      _nameController.text = identity.getName(widget.childId);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _updateName() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() => _isLoading = true);
    final identity = context.read<GameIdentityService>();
    await identity.rename(widget.childId, _nameController.text.trim());
    if (mounted) {
      setState(() {
        _isEditing = false;
        _isLoading = false;
      });
    }
  }

  void _startLocalGame(GameMode mode) {
    final gatekeeper = context.read<GatekeeperService>();
    if (!gatekeeper.isGatekeeperConnected) {
      context.go('/access-denied', extra: 'OFFLINE');
      return;
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ChangeNotifierProvider(
          create: (_) => GameController(
            context.read<GatekeeperService>(),
            parentId: widget.parentId,
            childId: widget.childId,
            gameMode: mode,
          ),
          child: const GameBoardScreenEnhanced(),
        ),
      ),
    );
  }

  void _goToMultiplayer() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            LobbyScreen(parentId: widget.parentId, childId: widget.childId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2A), // Dark Cyberpunk Blue
      body: Stack(
        children: [
          // Background Grid/Effect placeholder
          Container(
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/board/isometric_board.png'),
                fit: BoxFit.cover,
                opacity: 0.1,
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'CYBER TYCOON',
                    style: GoogleFonts.orbitron(
                      fontSize: 48,
                      fontWeight: FontWeight.bold,
                      color: Colors.cyanAccent,
                      shadows: [
                        BoxShadow(
                          color: Colors.cyan,
                          blurRadius: 20,
                          spreadRadius: 10,
                        ),
                      ],
                    ),
                  ),
                  // Profile Section
                  Container(
                    padding: const EdgeInsets.all(20),
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(15),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              "USER PROFILE",
                              style: GoogleFonts.orbitron(
                                fontSize: 14,
                                color: Colors.cyanAccent,
                                letterSpacing: 2,
                              ),
                            ),
                            if (!_isEditing)
                              IconButton(
                                icon: const Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: Colors.white54,
                                ),
                                onPressed: () =>
                                    setState(() => _isEditing = true),
                              ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (_isEditing)
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: _nameController,
                                  autofocus: true,
                                  style: GoogleFonts.sourceCodePro(
                                    color: Colors.white,
                                  ),
                                  decoration: const InputDecoration(
                                    isDense: true,
                                    enabledBorder: UnderlineInputBorder(
                                      borderSide: BorderSide(
                                        color: Colors.cyanAccent,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              if (_isLoading)
                                const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              else
                                IconButton(
                                  icon: const Icon(
                                    Icons.check,
                                    color: Colors.greenAccent,
                                  ),
                                  onPressed: _updateName,
                                ),
                            ],
                          )
                        else
                          Text(
                            _nameController.text,
                            style: GoogleFonts.sourceCodePro(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Game Modes
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.cyanAccent.withValues(alpha: 0.1),
                      foregroundColor: Colors.cyanAccent,
                      side: const BorderSide(color: Colors.cyanAccent),
                      minimumSize: const Size(250, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _startLocalGame(GameMode.practice),
                    child: Text(
                      'PRACTICE',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orangeAccent.withValues(
                        alpha: 0.1,
                      ),
                      foregroundColor: Colors.orangeAccent,
                      side: const BorderSide(color: Colors.orangeAccent),
                      minimumSize: const Size(250, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () => _startLocalGame(GameMode.ranked),
                    child: Text(
                      'RANKED',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFFF6B6B),
                      side: const BorderSide(
                        color: Color(0xFFFF6B6B),
                        width: 2,
                      ),
                      minimumSize: const Size(250, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _goToMultiplayer,
                    child: Text(
                      'ONLINE',
                      style: GoogleFonts.orbitron(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
