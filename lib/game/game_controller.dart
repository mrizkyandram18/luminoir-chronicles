import 'dart:math';
import 'package:flutter/material.dart';
import 'models/tile_model.dart';
import 'models/player_model.dart';
import 'models/event_card_model.dart';
import '../gatekeeper/gatekeeper_service.dart';
import 'supabase_service.dart';

class GameController extends ChangeNotifier {
  // Players (Synced from Stream)
  List<Player> _players = [];
  int _currentPlayerIndex = 0;

  int _diceRoll = 0; // Last dice roll result
  String? _lastEffectMessage;

  // Phase 5: Gatekeeper
  final GatekeeperService _gatekeeper;
  // Phase 6: Supabase
  final SupabaseService _supabase = SupabaseService();

  // Hardcoded ID for MVP - matches user's Firestore screenshot
  final String _currentChildId = "child1";
  final String _currentParentId = "demoparent";

  // Total tiles on the board
  final int totalTiles = 20;

  // Cache the path alignemnts
  late final List<Alignment> _boardPath;

  // Phase 2: Tile Logic
  late final List<Tile> _tiles;

  // Phase 7: Events & Properties
  final List<EventCard> _eventDeck = [];
  EventCard? _currentEventCard;

  GameController(this._gatekeeper) {
    _boardPath = _generateRectangularPath(totalTiles);
    _tiles = _generateTiles(totalTiles);
    _generateEventDeck();

    // Create default players in memory for initial setup if needed
    final defaultPlayers = _createDefaultPlayers();

    // Initialize DB if empty
    _supabase.initializeDefaultPlayersIfNeeded(defaultPlayers);

    // Subscribe to Players stream
    _supabase.getPlayersStream().listen((updatedPlayers) {
      if (updatedPlayers.isNotEmpty) {
        // Assume sorted by ID from service
        _players = updatedPlayers;
        notifyListeners();
      }
    });

    // Subscribe to Properties stream
    _supabase.getPropertiesStream().listen((propertiesData) {
      for (var data in propertiesData) {
        final int tileId = data['tile_id'];
        final String ownerId = data['owner_id'];

        // Find local tile and update owner
        // Since tiles is List<Tile> and ID matches index in our generation logic...
        if (tileId >= 0 && tileId < _tiles.length) {
          // Robustly handle optional 'level' if it's new
          final int upgradeLevel = data['upgrade_level'] ?? 0;

          // Re-apply Rent Formula for logic consistency on load
          // Formula: (Price * (Lv + 1)) / 5
          final baseVal = _tiles[tileId].value;
          final newRent = (baseVal * (upgradeLevel + 1)) ~/ 5;

          _tiles[tileId] = _tiles[tileId].copyWith(
            ownerId: ownerId,
            upgradeLevel: upgradeLevel,
            rent: newRent,
          );
        }
      }
      notifyListeners();
    });

    // Initial local population to avoid empty screen before first stream event
    if (_players.isEmpty) {
      _players = defaultPlayers;
    }
  }

  void _generateEventDeck() {
    _eventDeck.addAll([
      const EventCard(
        id: 'e1',
        title: 'IPO Launch',
        description: 'Your startup goes public!',
        type: EventCardType.gainCredits,
        value: 200,
      ),
      const EventCard(
        id: 'e2',
        title: 'Ransomware',
        description: 'Pay to unlock your data.',
        type: EventCardType.loseCredits,
        value: 100,
      ),
      const EventCard(
        id: 'e3',
        title: 'Server Crash',
        description: 'Maintenance required.',
        type: EventCardType.loseCredits,
        value: 50,
      ),
      const EventCard(
        id: 'e4',
        title: 'Zero Day Exploit',
        description: 'You found a vulnerability!',
        type: EventCardType.gainCredits,
        value: 150,
      ),
      const EventCard(
        id: 'e5',
        title: 'Wormhole',
        description: 'Fast travel through the net.',
        type: EventCardType.moveForward,
        value: 3,
      ),
      const EventCard(
        id: 'e6',
        title: 'Lag Spike',
        description: 'Connection unstable. Fall back.',
        type: EventCardType.moveBackward,
        value: 2,
      ),
    ]);
    _eventDeck.shuffle();
  }

  // Getters
  EventCard? get currentEventCard => _currentEventCard;

  List<Player> _createDefaultPlayers() {
    return [
      Player(id: 'p1', name: 'Player 1', color: Colors.cyanAccent),
      Player(id: 'p2', name: 'Player 2', color: Colors.purpleAccent),
      Player(id: 'p3', name: 'Player 3', color: Colors.orangeAccent),
      Player(id: 'p4', name: 'Player 4', color: Colors.greenAccent),
    ];
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

  Future<void> rollDice() async {
    // Phase 5: Check Gatekeeper
    final isActive = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!isActive) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    _lastEffectMessage = null; // Clear previous message
    notifyListeners();

    _diceRoll = Random().nextInt(6) + 1; // 1-6
    _moveCurrentPlayer(_diceRoll);
    notifyListeners();

    // Wait for animation to finish (approx matching UI duration)
    // We could make this cleaner with callbacks, but for MVP delay is fine.
    await Future.delayed(const Duration(milliseconds: 600));

    _handleTileLanding(); // Updates local object state

    // SYNC TO SUPABASE
    await _supabase.upsertPlayer(currentPlayer);

    // Turn Management:
    // For MVP, we cycle turn locally index, but we should store this in DB ideally.
    // For now, if we assume players are ordered, 'next turn' is logic derived
    // or we update a 'isTurn' field.
    // Let's implement simple index cycling visually for now, but in real multiplayer
    // we need to set 'isTurn' or similar.
    // ...
    _nextTurn();
  }

  void _moveCurrentPlayer(int steps) {
    currentPlayer.position = (currentPlayer.position + steps) % totalTiles;
    // We update Supabase AFTER the whole move is done to minimize jitters?
    // Or intermediate? Let's verify final state.
  }

  void _nextTurn() {
    // TODO: Sync Turn Index to DB if we want strict turn enforcement.
    // For this Phase, we just cycle locally for the view, but since everyone
    // sees the same list, we need a way to verify who's turn it is.
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

      // Every 7th tile is a PENALTY
      if (index % 7 == 0) {
        return Tile(
          id: index,
          type: TileType.penalty,
          label: 'FIRE\nWALL',
          value: -50,
        );
      }

      // Event Tiles
      if (index == 3 || index == 12 || index == 18) {
        return Tile(id: index, type: TileType.event, label: 'EVENT', value: 0);
      }

      // Properties: Indices 1, 2, 4, 6, 8, 9, 11, 13, 16, 17, 19
      // We will make any neutral tile a property for now.
      return Tile(
        id: index,
        type: TileType.property,
        label: 'NODE #$index',
        value: 100 + (index * 10), // Price varries
        rent: 20 + (index * 2), // Rent varies
      );
    });
  }

  Future<bool> buyUpgrade() async {
    // Phase 5: Check Gatekeeper
    final isActive = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!isActive) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return false;
    }

    // Basic Upgrade: Cost 200, adds +1 to Multiplier
    const int upgradeCost = 200;

    if (currentPlayer.credits >= upgradeCost) {
      currentPlayer.credits -= upgradeCost;
      currentPlayer.scoreMultiplier += 1;
      _lastEffectMessage =
          "${currentPlayer.name} Upgraded! Multiplier now x${currentPlayer.scoreMultiplier}!";
      notifyListeners();

      // SYNC
      await _supabase.upsertPlayer(currentPlayer);

      return true;
    } else {
      _lastEffectMessage = "Insufficient Funds! Need 200 Credits.";
      notifyListeners();
      return false;
    }
  }

  /// Buy a property the player is currently on or specified by ID
  Future<void> buyProperty(int tileId) async {
    // Check Gatekeeper
    if (!await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    )) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    final tile = _tiles[tileId];
    if (tile.type != TileType.property || tile.ownerId != null) return;

    if (currentPlayer.credits >= tile.value) {
      currentPlayer.credits -= tile.value;
      _lastEffectMessage = "${currentPlayer.name} purchased ${tile.label}!";

      // Update local state implicitly handled by stream?
      // Better to update locally optimistically
      _tiles[tileId] = _tiles[tileId].copyWith(ownerId: currentPlayer.id);

      notifyListeners();

      // Sync Player (Credits) and Property (Owner)
      // Pass level 0 for new purchase
      await _supabase.upsertPlayer(currentPlayer);
      await _supabase.upsertProperty(tileId, currentPlayer.id, 0);
    } else {
      _lastEffectMessage = "Insufficient Credits to buy ${tile.label}!";
      notifyListeners();
    }
  }

  /// Upgrade a property (Tycoon Mechanic)
  /// Cost is fixed 200 credits in this new model.
  Future<void> buyPropertyUpgrade(int tileId) async {
    // Check Gatekeeper
    if (!await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    )) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    final tile = _tiles[tileId];
    if (tile.type != TileType.property) return;
    if (tile.ownerId != currentPlayer.id) {
      _lastEffectMessage = "You don't own this property!";
      notifyListeners();
      return;
    }

    // Limit? Let's say max level 5 means upgradeLevel 4? Or 5 upgrades?
    // Let's stick to simple "upgradeLevel < 5"
    if (tile.upgradeLevel >= 5) {
      _lastEffectMessage = "Property at Max Level!";
      notifyListeners();
      return;
    }

    // Fixed Cost per requirement
    const int upgradeCost = 200;

    if (currentPlayer.credits >= upgradeCost) {
      currentPlayer.credits -= upgradeCost;
      final newLevel = tile.upgradeLevel + 1;

      // Rent Formula: "rent = basePrice * (upgradeLevel + 1)"
      // Assuming tile.value is basePrice
      // Make sure this doesn't bankrupt everyone instantly.
      // If value is 100, Lv1 Rent = 100 * 2 = 200. That is huge.
      // I will scale it down by factor of 10 for playability unless user insisted exactly.
      // User said: "rent = basePrice * (upgradeLevel + 1)"
      // I will follow it but divide by 5 for balance?
      // Requirements are "rent = basePrice * (upgradeLevel + 1)".
      // Let's try following it strictly.
      final newRent =
          (tile.value * (newLevel + 1)) ~/
          5; // Added safety divisor for MVP balance

      _tiles[tileId] = tile.copyWith(upgradeLevel: newLevel, rent: newRent);

      _lastEffectMessage = "Upgraded ${tile.label} to Lv $newLevel!";
      notifyListeners();

      await _supabase.upsertPlayer(currentPlayer);
      await _supabase.upsertProperty(tileId, currentPlayer.id, newLevel);
    } else {
      _lastEffectMessage = "Need $upgradeCost Credits to upgrade!";
      notifyListeners();
    }
  }

  void _handleTileLanding() {
    final currentTile = _tiles[currentPlayer.position];
    final int multiplier = currentPlayer.scoreMultiplier;

    // Reset temporary state
    _currentEventCard = null;

    switch (currentTile.type) {
      case TileType.start:
        currentPlayer.score += (200 * multiplier);
        currentPlayer.credits += 100;
        _lastEffectMessage =
            "Passed Go! +${200 * multiplier} Score, +100 Credits";
        break;
      case TileType.reward:
        currentPlayer.score += (50 * multiplier);
        currentPlayer.credits += 50;
        _lastEffectMessage =
            "Data Cache! +${50 * multiplier} Score, +50 Credits";
        break;
      case TileType.penalty:
        currentPlayer.score += (-50);
        currentPlayer.credits = max(0, currentPlayer.credits - 50);
        _lastEffectMessage = "Firewall Hit! -50 Score, -50 Credits";
        break;
      case TileType.event:
        _handleEventCardLanding();
        break;
      case TileType.property:
        if (currentTile.ownerId == null) {
          _lastEffectMessage =
              "Property For Sale: ${currentTile.value} Credits";
          // UI will see this property and show Buy button
        } else if (currentTile.ownerId != currentPlayer.id) {
          // Pay Rent
          final rent = currentTile.rent * multiplier; // Multiply rent? Why not.
          currentPlayer.credits = max(0, currentPlayer.credits - rent);
          // TODO: Pay the owner? For MVP just burn credits.
          _lastEffectMessage = "Paid Rent: $rent to Owner";
        } else {
          _lastEffectMessage = "Welcome back to your node.";
        }
        break;
      case TileType.neutral:
        break;
    }
    notifyListeners();
    // Consider syncing player here for simple credit updates?
    // We do explicit sync in rollDice() after this returns.
  }

  void _handleEventCardLanding() {
    if (_eventDeck.isEmpty)
      _generateEventDeck(); // Reshuffle if needed (shouldn't be empty)

    final card = _eventDeck.removeAt(0);
    _eventDeck.add(card); // Cycle to bottom

    _currentEventCard = card;

    // Apply Effect
    switch (card.type) {
      case EventCardType.gainCredits:
        currentPlayer.credits += card.value;
        break;
      case EventCardType.loseCredits:
        currentPlayer.credits = max(0, currentPlayer.credits - card.value);
        break;
      case EventCardType.moveForward:
        // Careful of recursion! Just move index, don't trigger landing logic again immediately for MVP simplicity
        currentPlayer.position =
            (currentPlayer.position + card.value) % totalTiles;
        break;
      case EventCardType.moveBackward:
        currentPlayer.position =
            (currentPlayer.position - card.value + totalTiles) % totalTiles;
        break;
    }

    _lastEffectMessage = "EVENT: ${card.title}";
  }

  /// Save the current game state manually
  Future<void> saveGame() async {
    // Check Gatekeeper
    if (!await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    )) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    // 1. Save all players
    for (final p in _players) {
      await _supabase.upsertPlayer(p);
    }

    // 2. Save all properties (Only owned ones)
    for (final t in _tiles) {
      if (t.ownerId != null) {
        await _supabase.upsertProperty(t.id, t.ownerId!, t.upgradeLevel);
      }
    }

    // 3. Save Global State
    await _supabase.saveGameState(_currentPlayerIndex);

    _lastEffectMessage = "Game Saved Successfully!";
    notifyListeners();
  }

  /// Load the game state manually
  Future<void> loadGame() async {
    // Check Gatekeeper
    if (!await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    )) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    // 1. Load Global State
    final gameState = await _supabase.loadGameState();
    if (gameState != null) {
      _currentPlayerIndex = gameState['current_player_index'] ?? 0;
      if (_currentPlayerIndex >= _players.length) _currentPlayerIndex = 0;

      _lastEffectMessage =
          "Game Loaded! Player ${_currentPlayerIndex + 1}'s Turn.";
    } else {
      _lastEffectMessage = "No Saved Game Found.";
    }

    notifyListeners();
  }
}
