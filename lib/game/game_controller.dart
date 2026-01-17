import 'dart:math';
import 'dart:async';
import 'package:flutter/material.dart';
import 'models/tile_model.dart'; // Keeping for UI Compat
import 'models/player_model.dart';
import 'models/event_card_model.dart';
import 'models/room_model.dart';
import 'models/board_node.dart';
import 'models/property_details.dart';
import 'graph/board_graph.dart';
import '../gatekeeper/gatekeeper_service.dart';
import 'supabase_service.dart';
import 'services/multiplayer_service.dart';

class GameController extends ChangeNotifier {
  // Players (Synced from Stream)
  List<Player> _players = [];
  int _currentPlayerIndex = 0;

  int _diceRoll = 0; // Last dice roll result
  String? _lastEffectMessage;

  // Phase 5: Gatekeeper
  final GatekeeperService _gatekeeper;
  // Phase 6: Supabase
  final SupabaseService _supabase;

  // Phase 1 (Redesign): Graph System
  final BoardGraph _boardGraph = BoardGraph();
  final Map<String, PropertyDetails> _properties = {};

  // Dynamic IDs from Setup Screen
  final String _currentParentId;
  final String _currentChildId;

  // Total tiles on the board (Legacy support)
  final int totalTiles = 20;

  // Phase 7: Events & Properties
  final List<EventCard> _eventDeck = [];
  EventCard? _currentEventCard;

  // Phase 16: Multiplayer
  final bool isMultiplayer;
  final String? roomId;
  final String? myChildId;
  late final MultiplayerService _multiplayerService;
  StreamSubscription<GameRoom>? _roomSubscription;
  StreamSubscription<List<RoomPlayer>>? _roomPlayersSubscription;
  bool _isMyTurn = true; // Default true for single player
  List<RoomPlayer> _roomPlayers = [];

  // Getters for multiplayer state
  bool get isMyTurn => _isMyTurn;
  List<RoomPlayer> get roomPlayers => _roomPlayers;

  GameController(
    this._gatekeeper, {
    required String parentId,
    required String childId,
    SupabaseService? supabaseService, // Optional injection for testing
    MultiplayerService? multiplayerService, // Optional injection for testing
    this.isMultiplayer = false,
    this.roomId,
    this.myChildId,
  }) : _currentParentId = parentId,
       _currentChildId = childId,
       _supabase = supabaseService ?? SupabaseService() {
    // Initialize properties from graph
    _initializeProperties();

    // Initialize default players
    if (isMultiplayer) {
      _multiplayerService = multiplayerService ?? MultiplayerService();
    }

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
        final String nodeId = 'node_$tileId'; // Adapter logic
        final String ownerId = data['owner_id'];
        final int upgradeLevel = data['upgrade_level'] ?? 0;

        if (_properties.containsKey(nodeId)) {
          _properties[nodeId] = _properties[nodeId]!.copyWith(
            ownerId: ownerId,
            buildingLevel: upgradeLevel,
          );
        }
      }
      notifyListeners();
    });

    // Initial local population to avoid empty screen before first stream event
    if (_players.isEmpty) {
      _players = defaultPlayers;
    }

    // Phase 16: Multiplayer subscriptions
    if (isMultiplayer && roomId != null) {
      _initMultiplayerSubscriptions();
    }
  }

  void _initializeProperties() {
    // Iterate 0-19 to init properties (Simulating graph iteration)
    for (int i = 0; i < 20; i++) {
      final id = 'node_$i';
      final node = _boardGraph.getNode(id);
      if (node != null && node.type == NodeType.property) {
        // Init default property details
        // Calculate base price based on index (Legacy logic ported)
        int price = 100 + (i * 10);
        int rent = 20 + (i * 2);

        _properties[id] = PropertyDetails(
          nodeId: id,
          baseValue: price,
          baseRent: rent,
        );
      }
    }
  }

  /// Initialize multiplayer room subscriptions
  void _initMultiplayerSubscriptions() {
    if (roomId == null) return;

    // Listen to room state changes (turn, game status)
    _roomSubscription = _multiplayerService.getRoomStream(roomId!).listen((
      room,
    ) {
      // Check if it's my turn
      _isMyTurn = room.currentTurnChildId == myChildId;

      // If game finished, could handle winner announcement here
      if (room.isFinished && room.winnerChildId != null) {
        debugPrint("Game Over! Winner: ${room.winnerChildId}");
      }

      notifyListeners();
    }, onError: (e) => debugPrint("Room stream error: $e"));

    // Listen to room players changes (for disconnect detection)
    _roomPlayersSubscription = _multiplayerService
        .getPlayersStream(roomId!)
        .listen((players) {
          _roomPlayers = players;

          // Check for disconnects - if only me connected, I win
          final connectedPlayers = players.where((p) => p.isConnected).toList();
          if (connectedPlayers.length == 1 &&
              connectedPlayers.first.childId == myChildId) {
            // Everyone else disconnected - I win!
            _multiplayerService.endGame(
              roomId: roomId!,
              winnerChildId: myChildId!,
            );
          }

          notifyListeners();
        }, onError: (e) => debugPrint("Room players stream error: $e"));
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

  // ADAPTER: Tiles for legacy UI
  // Renders the board based on Graph + PropertyDetails
  List<Tile> get tiles {
    List<Tile> uiTiles = [];
    for (int i = 0; i < 20; i++) {
      String id = 'node_$i';
      BoardNode? node = _boardGraph.getNode(id);
      if (node == null) continue;

      // Map NodeType to TileType
      TileType type;
      if (node.type == NodeType.start) {
        type = TileType.start;
      } else if (node.type == NodeType.property) {
        type = TileType.property;
      } else if (node.type == NodeType.event) {
        type = TileType.event;
      } else if (node.type == NodeType.minigame) {
        type = TileType.reward; // Mapping minigame to Reward for now
      } else if (node.type == NodeType.prison) {
        type = TileType.penalty; // Mapping prison to Penalty
      } else {
        type = TileType.neutral;
      }

      // Get Property Data if exists
      PropertyDetails? props = _properties[id];

      uiTiles.add(
        Tile(
          id: i,
          type: type,
          label: node.label,
          value: props?.baseValue ?? 0,
          rent: props?.currentRent ?? 0,
          ownerId: props?.ownerId,
          upgradeLevel: props?.buildingLevel ?? 0,
        ),
      );
    }
    return uiTiles;
  }

  // Expose the calculated path for the UI to render tiles
  // ADAPTER: Calculate path from Nodes
  List<Alignment> get boardPath {
    List<Alignment> path = [];
    for (int i = 0; i < 20; i++) {
      var node = _boardGraph.getNode('node_$i');
      if (node != null) path.add(node.position);
    }
    return path;
  }

  Alignment getPlayerAlignment(Player p) {
    // Use p.nodeId if available, fallback to p.position for legacy
    var node = _boardGraph.getNode(p.nodeId);
    if (node != null) return node.position;

    // Fallback
    if (p.position >= 0 && p.position < boardPath.length) {
      return boardPath[p.position];
    }
    return Alignment.center;
  }

  @override
  void dispose() {
    _roomSubscription?.cancel();
    _roomPlayersSubscription?.cancel();
    super.dispose();
  }

  Future<void> rollDice({double gaugeValue = 0.5}) async {
    // Phase 16: Check if it's my turn in multiplayer mode
    if (isMultiplayer && !_isMyTurn) {
      _lastEffectMessage = "Wait for your turn!";
      notifyListeners();
      return;
    }

    // Phase 5: Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    _lastEffectMessage = null; // Clear previous message
    notifyListeners();

    // Interactive Roll Logic (KISS: Simple bias)
    int roll;
    if (gaugeValue < 0.4) {
      // Bias towards Low (1-3)
      // 70% chance of 1-3, 30% chance of 4-6
      bool hit = Random().nextDouble() < 0.7;
      roll = hit ? (Random().nextInt(3) + 1) : (Random().nextInt(3) + 4);
    } else if (gaugeValue > 0.6) {
      // Bias towards High (4-6)
      bool hit = Random().nextDouble() < 0.7;
      roll = hit ? (Random().nextInt(3) + 4) : (Random().nextInt(3) + 1);
    } else {
      // Pure Random
      roll = Random().nextInt(6) + 1;
    }

    _diceRoll = roll;
    _moveCurrentPlayer(_diceRoll);
    notifyListeners();

    // Wait for animation to finish (approx matching UI duration)
    // We could make this cleaner with callbacks, but for MVP delay is fine.
    await Future.delayed(const Duration(milliseconds: 600));

    _handleTileLanding(); // Updates local object state

    // SYNC TO SUPABASE
    await _supabase.upsertPlayer(currentPlayer);

    // Auto-save game state on move
    await saveGame();

    _nextTurn();
  }

  void _moveCurrentPlayer(int steps) {
    // Graph Traversal Logic
    String currentId = currentPlayer.nodeId;

    for (int i = 0; i < steps; i++) {
      BoardNode? node = _boardGraph.getNode(currentId);
      if (node != null && node.nextNodeIds.isNotEmpty) {
        // Logic for forks would go here. For now, take first.
        currentId = node.nextNodeIds.first;
      }
    }

    currentPlayer.nodeId = currentId;
    // Sync legacy integer position for backward compatibility
    try {
      currentPlayer.position = int.parse(currentId.split('_').last);
    } catch (e) {
      currentPlayer.position = 0;
    }
  }

  void _nextTurn() {
    // TODO: Sync Turn Index to DB if we want strict turn enforcement.
    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    notifyListeners();
  }

  Future<bool> buyUpgrade() async {
    // Helper for legacy button triggering this
    // Assuming it upgrades current tile
    return false; // Deprecated use buyPropertyUpgrade
  }

  /// Buy a property the player is currently on or specified by ID
  Future<void> buyProperty(int tileId) async {
    // Convert tileId to nodeId
    String nodeId = 'node_$tileId';

    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    PropertyDetails? prop = _properties[nodeId];
    if (prop == null || prop.ownerId != null) return;

    if (currentPlayer.credits >= prop.baseValue) {
      currentPlayer.credits -= prop.baseValue;
      _lastEffectMessage = "${currentPlayer.name} purchased Node $tileId!";

      // Update local state
      _properties[nodeId] = prop.copyWith(ownerId: currentPlayer.id);

      notifyListeners();

      // Sync Player (Credits) and Property (Owner)
      await _supabase.upsertPlayer(currentPlayer);
      await _supabase.upsertProperty(tileId, currentPlayer.id, 0);
    } else {
      _lastEffectMessage = "Insufficient Credits to buy!";
      notifyListeners();
    }
  }

  /// Upgrade a property (Tycoon Mechanic)
  Future<void> buyPropertyUpgrade(int tileId) async {
    String nodeId = 'node_$tileId';

    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    PropertyDetails? prop = _properties[nodeId];
    if (prop == null) return;

    if (prop.ownerId != currentPlayer.id) {
      _lastEffectMessage = "You don't own this property!";
      notifyListeners();
      return;
    }

    // Limit building level
    if (prop.buildingLevel >= 3) {
      _lastEffectMessage = "Property at Max Building Level!";
      // TODO: Implement Landmark Level 4 logic later
      notifyListeners();
      return;
    }

    // Logic for cost
    int cost = prop.upgradeCost;

    if (currentPlayer.credits >= cost) {
      currentPlayer.credits -= cost;
      final newLevel = prop.buildingLevel + 1;

      // Update local
      _properties[nodeId] = prop.copyWith(buildingLevel: newLevel);

      _lastEffectMessage = "Upgraded to Lv $newLevel!";
      notifyListeners();

      await _supabase.upsertPlayer(currentPlayer);
      await _supabase.upsertProperty(tileId, currentPlayer.id, newLevel);
    } else {
      _lastEffectMessage = "Need $cost Credits to upgrade!";
      notifyListeners();
    }
  }

  void _handleTileLanding() {
    String currentId = currentPlayer.nodeId;
    BoardNode? node = _boardGraph.getNode(currentId);
    if (node == null) return;

    final int multiplier = currentPlayer.scoreMultiplier;

    // Reset temporary state
    _currentEventCard = null;

    switch (node.type) {
      case NodeType.start:
        currentPlayer.score += (200 * multiplier);
        currentPlayer.credits += 100;
        _lastEffectMessage =
            "Passed Go! +${200 * multiplier} Score, +100 Credits";
        break;
      case NodeType.minigame:
        currentPlayer.score += (50 * multiplier);
        currentPlayer.credits += 50;
        _lastEffectMessage =
            "Data Cache! +${50 * multiplier} Score, +50 Credits";
        break;
      case NodeType.prison:
        currentPlayer.score += (-50);
        currentPlayer.credits = max(0, currentPlayer.credits - 50);
        _lastEffectMessage = "Firewall Hit! -50 Score, -50 Credits";
        break;
      case NodeType.event:
        _handleEventCardLanding();
        break;
      case NodeType.property:
        PropertyDetails? prop = _properties[currentId];
        if (prop != null) {
          if (prop.ownerId == null) {
            _lastEffectMessage = "Property For Sale: ${prop.baseValue} Credits";
          } else if (prop.ownerId != currentPlayer.id) {
            // Pay Rent
            final rent = prop.currentRent * multiplier;
            currentPlayer.credits = max(0, currentPlayer.credits - rent);
            _lastEffectMessage = "Paid Rent: $rent to Owner";
          } else {
            _lastEffectMessage = "Welcome back to your node.";
          }
        }
        break;
      default:
        break;
    }
    notifyListeners();
  }

  void _handleEventCardLanding() {
    if (_eventDeck.isEmpty) {
      _generateEventDeck();
    }

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
        _moveCurrentPlayer(card.value);
        break;
      case EventCardType.moveBackward:
        // Implement reverse logic? For mvp just ignore or move forward
        // Graph reverse is hard without prev links.
        // TODO: Implement reverse graph
        break;
    }

    _lastEffectMessage = "EVENT: ${card.title}";
  }

  /// Save the current game state manually
  Future<void> saveGame() async {
    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    // 1. Save all players
    for (final p in _players) {
      await _supabase.upsertPlayer(p);
    }

    // 2. Save all properties (Only owned ones)
    _properties.forEach((key, prop) async {
      if (prop.ownerId != null) {
        int tileId = int.parse(key.split('_').last);
        await _supabase.upsertProperty(
          tileId,
          prop.ownerId!,
          prop.buildingLevel,
        );
      }
    });

    // 3. Save Global State
    await _supabase.saveGameState(_currentPlayerIndex);

    _lastEffectMessage = "Game Saved Successfully!";
    notifyListeners();
  }

  /// Load the game state manually
  Future<void> loadGame() async {
    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
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
