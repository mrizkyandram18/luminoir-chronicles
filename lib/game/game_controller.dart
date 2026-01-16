import 'dart:math';
import 'package:flutter/material.dart';
import 'models/tile_model.dart';
import 'models/player_model.dart';

class GameController extends ChangeNotifier {
  // Phase 3: Multiplayer State
  final List<Player> _players = [];
  int _currentPlayerIndex = 0;

  int _diceRoll = 0; // Last dice roll result
  String? _lastEffectMessage;

  // Total tiles on the board
  final int totalTiles = 20;

  // Cache the path alignemnts
  late final List<Alignment> _boardPath;

  // Phase 2: Tile Logic
  late final List<Tile> _tiles;

  GameController() {
    _boardPath = _generateRectangularPath(totalTiles);
    _tiles = _generateTiles(totalTiles);
    _initializePlayers();
  }

  // Getters
  List<Player> get players => _players;
  Player get currentPlayer => _players[_currentPlayerIndex];

  // This is now purely for the "Last Rolled" display, logic uses currentPlayer position
  int get diceRoll => _diceRoll;
  int get currentPlayerIndex => _currentPlayerIndex; // For UI highlighting

  String? get lastEffectMessage => _lastEffectMessage;
  List<Tile> get tiles => _tiles;

  // Expose the calculated path for the UI to render tiles
  List<Alignment> get boardPath => _boardPath;

  Alignment getPlayerAlignment(Player p) => _boardPath[p.position];

  void _initializePlayers() {
    _players.clear();
    _players.add(Player(id: 'p1', name: 'Player 1', color: Colors.cyanAccent));
    _players.add(
      Player(id: 'p2', name: 'Player 2', color: Colors.purpleAccent),
    );
    _players.add(
      Player(id: 'p3', name: 'Player 3', color: Colors.orangeAccent),
    );
    _players.add(Player(id: 'p4', name: 'Player 4', color: Colors.greenAccent));
  }

  Future<void> rollDice() async {
    _lastEffectMessage = null; // Clear previous message
    notifyListeners();

    _diceRoll = Random().nextInt(6) + 1; // 1-6
    _moveCurrentPlayer(_diceRoll);
    notifyListeners();

    // Wait for animation to finish (approx matching UI duration)
    // We could make this cleaner with callbacks, but for MVP delay is fine.
    await Future.delayed(const Duration(milliseconds: 600));

    _handleTileLanding();

    // Auto specific delay before next turn? Or just let user click?
    // User request: "nextTurn() to move to next player".
    // Let's create a separate method for nextTurn if needed, but for MVP
    // we can auto-advance or just leave the state ready for next click.
    // Let's NOT auto-advance instantly so they can see the effect.
    // But then the button needs to change to "END TURN" or we just update index.
    // Simpler: Just update index now so next click is next player.
    _nextTurn();
  }

  void _moveCurrentPlayer(int steps) {
    currentPlayer.position = (currentPlayer.position + steps) % totalTiles;
  }

  void _nextTurn() {
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    notifyListeners();
  }

  /// Generates a list of Alignments forming a rectangular loop (20 tiles).
  /// Start: Bottom-Right (Index 0).
  /// Order: Bottom-Right -> Bottom-Left -> Top-Left -> Top-Right -> Bottom-Right.
  ///
  /// Logic:
  /// - Bottom Side: Indices 0-5
  /// - Left Side: Indices 5-10
  /// - Top Side: Indices 10-15
  /// - Right Side: Indices 15-20 (Loops back to 0)
  List<Alignment> _generateRectangularPath(int count) {
    final List<Alignment> path = [];

    // We strictly want 20 tiles.
    // 5 tiles per side roughly.
    // Let's manually define the lerping to ensure exactly count items.
    // Side 1: Bottom (Right to Left). x: 1.0 -> -1.0, y: 1.0
    // Side 2: Left (Bottom to Top).   x: -1.0, y: 1.0 -> -1.0
    // Side 3: Top (Left to Right).    x: -1.0 -> 1.0, y: -1.0
    // Side 4: Right (Top to Bottom).  x: 1.0, y: -1.0 -> 1.0

    // However, distributing 20 points evenly along a perimeter of length 8 (2+2+2+2)
    // 20 points means step size = Perimeter / 20 = 8 / 20 = 0.4.
    //
    // Let's walk the perimeter:
    // Start at (1.0, 1.0) -> Bottom Right.
    // 0: (1.0, 1.0)
    // 1: (0.6, 1.0)
    // 2: (0.2, 1.0)
    // 3: (-0.2, 1.0)
    // 4: (-0.6, 1.0)
    // 5: (-1.0, 1.0) -> Bottom Left Corner
    // 6: (-1.0, 0.6)
    // ...

    // We can just execute this walk.
    // NOTE: We use 0.9 instead of 1.0 to keep it inside the screen padding slightly.
    const double limit = 0.85;
    const double step = (limit * 2) / 5; // 5 steps to cross one side?
    // Side length is 2*limit.
    // We need 5 intervals per side to get 20 tiles?
    // 4 sides * 5 tiles = 20. Correct.

    // Bottom: (limit, limit) -> (-limit, limit)
    for (int i = 0; i < 5; i++) {
      path.add(Alignment(limit - (i * step), limit));
    }

    // Left: (-limit, limit) -> (-limit, -limit)
    for (int i = 0; i < 5; i++) {
      path.add(Alignment(-limit, limit - (i * step)));
    }

    // Top: (-limit, -limit) -> (limit, -limit)
    for (int i = 0; i < 5; i++) {
      path.add(Alignment(-limit + (i * step), -limit));
    }

    // Right: (limit, -limit) -> (limit, limit)
    for (int i = 0; i < 5; i++) {
      path.add(Alignment(limit, -limit + (i * step)));
    }

    return path;
  }

  /// Generates the 20 tiles with specific rules.
  List<Tile> _generateTiles(int count) {
    return List.generate(count, (index) {
      if (index == 0) {
        return Tile(
          id: index,
          type: TileType.start,
          label: 'START',
          value: 200,
        );
      }

      // Every 5th tile is a REWARD
      if (index % 5 == 0) {
        return Tile(
          id: index,
          type: TileType.reward,
          label: 'DATA\nCACHE',
          value: 50,
        );
      }

      // Every 7th tile is a PENALTY (overrides reward if conflict? 35 is div by 5 and 7.. but we only go up to 20 so no conflict)
      // actually 7, 14.
      if (index % 7 == 0) {
        return Tile(
          id: index,
          type: TileType.penalty,
          label: 'FIRE\nWALL',
          value: -50,
        );
      }

      // Random Event
      if (index == 3 || index == 12 || index == 18) {
        return Tile(id: index, type: TileType.event, label: 'EVENT', value: 0);
      }

      return Tile(id: index, type: TileType.neutral, label: '$index');
    });
  }

  void _handleTileLanding() {
    final currentTile = _tiles[currentPlayer.position];

    switch (currentTile.type) {
      case TileType.start:
        currentPlayer.score += currentTile.value;
        _lastEffectMessage =
            "${currentPlayer.name} Passed Go! +${currentTile.value}";
        break;
      case TileType.reward:
        currentPlayer.score += currentTile.value;
        _lastEffectMessage =
            "${currentPlayer.name} found Data Cache! +${currentTile.value}";
        break;
      case TileType.penalty:
        currentPlayer.score += currentTile.value; // value is negative
        _lastEffectMessage =
            "${currentPlayer.name} hit Firewall! ${currentTile.value}";
        break;
      case TileType.event:
        _lastEffectMessage = "${currentPlayer.name} Scan... Safe.";
        break;
      case TileType.neutral:
        // No effect
        break;
    }
    notifyListeners();
  }
}
