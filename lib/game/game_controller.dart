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
import 'services/leaderboard_service.dart';
import 'models/match_result.dart';

enum GameMode { practice, ranked, online }

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
  MultiplayerService? _multiplayerService;
  StreamSubscription<GameRoom>? _roomSubscription;
  StreamSubscription<List<RoomPlayer>>? _roomPlayersSubscription;
  bool _isMyTurn = true; // Default true for single player
  List<RoomPlayer> _roomPlayers = [];

  // Phase 17: Leaderboard & Game Modes
  late final LeaderboardService _leaderboardService;
  LeaderboardService get leaderboardService => _leaderboardService;

  GameMode gameMode = GameMode.practice;
  DateTime? _dicePressStart; // For charging mechanics

  // Match tracking
  String? _currentMatchId;
  bool _matchEnded = false;

  // Getters for multiplayer state
  bool get isMyTurn => _isMyTurn;
  List<RoomPlayer> get roomPlayers => _roomPlayers;
  bool get matchEnded => _matchEnded;

  // Game Rule State Flags
  bool _canRoll = true;
  bool _canEndTurn = false;
  bool _actionTakenThisTurn = false;
  bool _isMoving = false;

  // Getters for Rule Enforcement
  bool get canRoll => _canRoll && !matchEnded && !_isMoving;
  bool get canEndTurn => _canEndTurn && !matchEnded && !_isMoving;
  bool get actionTakenThisTurn => _actionTakenThisTurn;
  bool get isMoving => _isMoving;

  GameController(
    this._gatekeeper, {
    required String parentId,
    required String childId,
    GameMode? gameMode,
    SupabaseService? supabaseService, // Optional injection for testing
    MultiplayerService? multiplayerService, // Optional injection for testing
    LeaderboardService? leaderboardService, // Optional injection for testing
    this.isMultiplayer = false,
    this.roomId,
    this.myChildId,
  }) : _currentParentId = parentId,
       _currentChildId = childId,
       gameMode =
           gameMode ?? (isMultiplayer ? GameMode.online : GameMode.practice),
       _supabase = supabaseService ?? SupabaseService() {
    _leaderboardService = leaderboardService ?? LeaderboardService(_supabase);

    // Initialize properties from graph
    _initializeProperties();

    // Initialize default players
    if (isMultiplayer) {
      _multiplayerService = multiplayerService ?? MultiplayerService();
      // gameMode is already set in initializer, but ensure online for multiplayer
      gameMode = GameMode.online;
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
      _currentMatchId = roomId;
    } else {
      _currentMatchId = 'practice_${DateTime.now().millisecondsSinceEpoch}';
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
    if (roomId == null || _multiplayerService == null) return;

    // Listen to room state changes (turn, game status)
    _roomSubscription = _multiplayerService!.getRoomStream(roomId!).listen((
      room,
    ) {
      // Check if it's my turn
      _isMyTurn = room.currentTurnChildId == myChildId;

      if (room.isFinished && room.winnerChildId != null && !_matchEnded) {
        endGame(winnerId: room.winnerChildId);
      }

      if (!_matchEnded) {
        notifyListeners();
      }
    }, onError: (e) => debugPrint("Room stream error: $e"));

    // Listen to room players changes (for disconnect detection)
    _roomPlayersSubscription = _multiplayerService!
        .getPlayersStream(roomId!)
        .listen((players) {
          _roomPlayers = players;

          // Check for disconnects - if only me connected, I win
          if (!_matchEnded) {
            final connectedPlayers = players
                .where((p) => p.isConnected)
                .toList();
            if (connectedPlayers.length == 1 &&
                connectedPlayers.first.childId == myChildId) {
              // Everyone else disconnected - I win!
              _multiplayerService!.endGame(
                roomId: roomId!,
                winnerChildId: myChildId!,
              );
            }

            notifyListeners();
          }
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
    bool isPractice = gameMode == GameMode.practice;
    return [
      Player(
        id: 'p1',
        name: 'Player 1',
        color: Colors.cyanAccent,
        isHuman: true,
      ),
      Player(
        id: 'p2',
        name: 'Bot 2',
        color: Colors.purpleAccent,
        isHuman: !isPractice,
      ),
      Player(
        id: 'p3',
        name: 'Bot 3',
        color: Colors.orangeAccent,
        isHuman: !isPractice,
      ),
      Player(
        id: 'p4',
        name: 'Bot 4',
        color: Colors.greenAccent,
        isHuman: !isPractice,
      ),
    ];
  }

  // Getters
  List<Player> get players => _players;
  Player get currentPlayer => _players[_currentPlayerIndex];

  // This is now purely for the "Last Rolled" display, logic uses currentPlayer position
  int get diceRoll => _diceRoll;
  int get currentPlayerIndex => _currentPlayerIndex; // For UI highlighting

  String? get lastEffectMessage => _lastEffectMessage;

  // Exposed for Isometric Board
  BoardGraph get boardGraph => _boardGraph;
  Map<String, PropertyDetails> get properties => _properties;

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

  bool _isDisposed = false;

  @override
  void dispose() {
    _isDisposed = true;
    _roomSubscription?.cancel();
    _roomPlayersSubscription?.cancel();
    super.dispose();
  }

  void _safeNotifyListeners() {
    if (!_isDisposed && !_matchEnded) {
      notifyListeners();
    }
  }

  // Phase 17: Interactive Dice Charge
  void startDiceCharge() {
    if (isMultiplayer && !_isMyTurn) return;
    if (!canRoll) return; // Use the new getter
    _dicePressStart = DateTime.now();
  }

  Future<void> releaseDiceCharge() async {
    if (_dicePressStart == null) {
      await rollDice();
      return;
    }

    final pressDuration = DateTime.now()
        .difference(_dicePressStart!)
        .inMilliseconds;
    _dicePressStart = null;

    // Calculate gauge value (0.0 to 1.0) based on duration
    // Max charge is 2 seconds (2000ms)
    double gauge = (pressDuration / 2000).clamp(0.0, 1.0);

    // Pass gauge to rollDice
    await rollDice(gaugeValue: gauge);
  }

  Future<void> rollDice({double gaugeValue = 0.5}) async {
    if (_isDisposed || _matchEnded || !canRoll) return; // Use the new getter

    // Phase 16: Check if it's my turn in multiplayer mode
    if (isMultiplayer && !_isMyTurn) {
      _lastEffectMessage = "Wait for your turn!";
      _safeNotifyListeners();
      return;
    }

    _canRoll = false; // Lock rolling
    _isMoving = true;
    _actionTakenThisTurn = false; // Reset for new turn

    // Phase 5: Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (_isDisposed || _matchEnded) {
      _isMoving = false;
      return;
    }
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      _canRoll = true; // Allow retry if offline
      _isMoving = false;
      _safeNotifyListeners();
      return;
    }

    _lastEffectMessage = null; // Clear previous message
    _diceRoll = 0; // Reset logic for Animation Detection
    _safeNotifyListeners();

    await Future.delayed(const Duration(milliseconds: 100));
    if (_isDisposed || _matchEnded) {
      _isMoving = false;
      return;
    }

    // Interactive Roll Logic
    int roll;
    if (gaugeValue < 0.4) {
      bool hit = Random().nextDouble() < 0.7;
      roll = hit ? (Random().nextInt(3) + 1) : (Random().nextInt(3) + 4);
    } else if (gaugeValue > 0.6) {
      bool hit = Random().nextDouble() < 0.7;
      roll = hit ? (Random().nextInt(3) + 4) : (Random().nextInt(3) + 1);
    } else {
      roll = Random().nextInt(6) + 1;
    }

    _diceRoll = roll;
    _safeNotifyListeners();

    await Future.delayed(const Duration(milliseconds: 1500));

    // Move Step-by-Step
    await _moveCurrentPlayer(_diceRoll);

    await Future.delayed(const Duration(milliseconds: 200));
    if (_isDisposed || _matchEnded) {
      _isMoving = false;
      return;
    }

    _handleTileLanding();

    // SYNC TO SUPABASE (Only if not practice)
    if (gameMode != GameMode.practice) {
      await _supabase.upsertPlayer(currentPlayer);
    }

    _isMoving = false;
    _canEndTurn = true; // Allow ending turn after landing
    _safeNotifyListeners();

    // Autosave (non-match progress only)
    await autosave();

    // Check game over
    await _checkGameOverCondition();
  }

  Future<void> _moveCurrentPlayer(int steps) async {
    // Graph Traversal Logic
    String currentId = currentPlayer.nodeId;

    for (int i = 0; i < steps; i++) {
      BoardNode? node = _boardGraph.getNode(currentId);
      if (node != null && node.nextNodeIds.isNotEmpty) {
        // Logic for forks would go here. For now, take first.
        currentId = node.nextNodeIds.first;

        // UPDATE STATE STEP-BY-STEP
        currentPlayer.nodeId = currentId;

        // Sync legacy integer position for backward compatibility
        try {
          currentPlayer.position = int.parse(currentId.split('_').last);
        } catch (e) {
          currentPlayer.position = 0;
        }

        // Check for Passing Start (Salary)
        if (currentPlayer.position == 0) {
          // Assuming node_0 is start
          currentPlayer.credits += 200; // Salary
          _lastEffectMessage = "Passed Start! +200 Credits";
        }

        notifyListeners(); // Trigger UI Animation
        await Future.delayed(
          const Duration(milliseconds: 300),
        ); // Wait for animation (Snappier)
      }
    }
  }

  void endTurn() {
    if (!canEndTurn) return; // Use the new getter
    _nextTurn();
  }

  void _nextTurn() {
    _canEndTurn = false;
    _actionTakenThisTurn = false;
    _canRoll = true;

    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    _safeNotifyListeners();

    // AI Turn Logic
    if (!_players[_currentPlayerIndex].isHuman) {
      _processAiTurn();
    }
  }

  Future<void> _processAiTurn() async {
    // Simulate thinking time
    await Future.delayed(const Duration(seconds: 2));

    // AI Decision: Always roll for now (Strategy can be added later)
    // Random gauge value for variety
    double randomGauge = Random().nextDouble();
    await rollDice(gaugeValue: randomGauge);

    // AI Buying Logic could go here (e.g. call buyProperty if credits allow)
    // For now, simple movement.
    _attemptAiAction();
  }

  Future<void> _attemptAiAction() async {
    // Simple AI: Buy if can afford
    // Needs access to current tile after move.
    // Since rollDice calls _handleTileLanding then _nextTurn,
    // we need to inject action logic BEFORE _nextTurn in rollDice or
    // handle it here if modify rollDice to NOT call _nextTurn automatically?
    // Current rollDice calls _nextTurn.
    // So AI buying must happen inside rollDice or _tileLanding?
    // Or we modify rollDice to wait for AI action?

    // KISS: For now, AI just moves. Smart AI can be Phase 18.
  }

  Future<bool> buyUpgrade() async {
    // Helper for legacy button triggering this
    // Assuming it upgrades current tile
    return false; // Deprecated use buyPropertyUpgrade
  }

  /// Buy a property the player is currently on or specified by ID
  Future<void> buyProperty(int tileId) async {
    if (_actionTakenThisTurn) return;

    // Convert tileId to nodeId
    String nodeId = 'node_$tileId';

    // Must be on the tile
    if (currentPlayer.nodeId != nodeId) return;

    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      _safeNotifyListeners();
      return;
    }

    PropertyDetails? prop = _properties[nodeId];
    if (prop == null || prop.ownerId != null) return;

    if (currentPlayer.credits >= prop.baseValue) {
      currentPlayer.credits -= prop.baseValue;
      _actionTakenThisTurn = true;
      _lastEffectMessage = "Purchased ${prop.nodeId}!";

      // Update local state
      _properties[nodeId] = prop.copyWith(ownerId: currentPlayer.id);

      _safeNotifyListeners();

      // Sync Player (Credits) and Property (Owner)
      if (gameMode != GameMode.practice) {
        await _supabase.upsertPlayer(currentPlayer);
        await _supabase.upsertProperty(tileId, currentPlayer.id, 0);
      }
    } else {
      _lastEffectMessage = "Insufficient Credits!";
      _safeNotifyListeners();
    }
  }

  /// Upgrade a property (Tycoon Mechanic)
  Future<void> buyPropertyUpgrade(int tileId) async {
    if (_actionTakenThisTurn) return;
    String nodeId = 'node_$tileId';

    // Must be on the tile
    if (currentPlayer.nodeId != nodeId) return;

    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      _safeNotifyListeners();
      return;
    }

    PropertyDetails? prop = _properties[nodeId];
    if (prop == null) return;

    if (prop.ownerId != currentPlayer.id) {
      _lastEffectMessage = "You don't own this!";
      _safeNotifyListeners();
      return;
    }

    // Limit building level (Max 4 for Landmark)
    if (prop.buildingLevel >= 4 || prop.hasLandmark) {
      _lastEffectMessage = "Landmark Reached!";
      _safeNotifyListeners();
      return;
    }

    int cost = prop.upgradeCost;

    if (currentPlayer.credits >= cost) {
      currentPlayer.credits -= cost;
      _actionTakenThisTurn = true;
      final newLevel = prop.buildingLevel + 1;
      final isLandmark = newLevel >= 4;

      // Update local
      _properties[nodeId] = prop.copyWith(
        buildingLevel: newLevel,
        hasLandmark: isLandmark,
      );

      _lastEffectMessage = isLandmark
          ? "LANDMARK BUILT!"
          : "Upgraded to Lv $newLevel!";
      _safeNotifyListeners();

      if (gameMode != GameMode.practice) {
        await _supabase.upsertPlayer(currentPlayer);
        await _supabase.upsertProperty(tileId, currentPlayer.id, newLevel);
      }
    } else {
      _lastEffectMessage = "Need $cost Credits!";
      _safeNotifyListeners();
    }
  }

  /// Takeover a property from another player (Hostile Takeover)
  Future<void> buyPropertyTakeover(int tileId) async {
    if (_actionTakenThisTurn) return;
    String nodeId = 'node_$tileId';

    // Must be on the tile
    if (currentPlayer.nodeId != nodeId) return;

    // Check Gatekeeper
    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      _safeNotifyListeners();
      return;
    }

    PropertyDetails? prop = _properties[nodeId];
    if (prop == null || prop.ownerId == null) return;

    if (prop.ownerId == currentPlayer.id) {
      _lastEffectMessage = "You already own this!";
      _safeNotifyListeners();
      return;
    }

    if (prop.hasLandmark || prop.buildingLevel >= 4) {
      _lastEffectMessage = "Landmark Locked!";
      _safeNotifyListeners();
      return;
    }

    int cost = prop.takeoverCost;

    if (currentPlayer.credits >= cost) {
      _actionTakenThisTurn = true;
      Player? previousOwner = _players.cast<Player?>().firstWhere(
        (p) => p?.id == prop.ownerId,
        orElse: () => null,
      );

      currentPlayer.credits -= cost;
      if (previousOwner != null) {
        previousOwner.credits += cost;
        if (gameMode != GameMode.practice) {
          await _supabase.upsertPlayer(previousOwner);
        }
      }

      _lastEffectMessage = "Takeover Successful!";

      // 2. Transfer Ownership
      _properties[nodeId] = prop.copyWith(ownerId: currentPlayer.id);

      _safeNotifyListeners();

      // 3. Sync
      if (gameMode != GameMode.practice) {
        await _supabase.upsertPlayer(currentPlayer);
        await _supabase.upsertProperty(
          tileId,
          currentPlayer.id,
          prop.buildingLevel,
        );
      }
    } else {
      _lastEffectMessage = "Need $cost Credits!";
      _safeNotifyListeners();
    }
  }

  void _handleTileLanding() {
    String currentId = currentPlayer.nodeId;
    BoardNode? node = _boardGraph.getNode(currentId);
    if (node == null) return;

    final int multiplier = currentPlayer.scoreMultiplier;
    _currentEventCard = null;

    switch (node.type) {
      case NodeType.start:
        currentPlayer.score += (200 * multiplier);
        currentPlayer.credits += 100;
        _lastEffectMessage =
            "Recouped! +${200 * multiplier} Score, +100 Credits";
        break;
      case NodeType.minigame:
        int reward = 200 * multiplier;
        currentPlayer.credits += reward;
        currentPlayer.score += 100 * multiplier;
        _lastEffectMessage = "Dark Web Loot! +$reward Credits";
        break;
      case NodeType.prison:
        int penalty = 150 * multiplier;
        currentPlayer.credits = max(0, currentPlayer.credits - penalty);
        currentPlayer.score = max(0, currentPlayer.score - 50);
        _lastEffectMessage = "System Error! -$penalty Credits";
        break;
      case NodeType.event:
        _handleEventCardLanding();
        break;
      case NodeType.property:
        PropertyDetails? prop = _properties[currentId];
        if (prop != null) {
          if (prop.ownerId == null) {
            _lastEffectMessage = "Node For Sale: ${prop.baseValue} Credits";
          } else if (prop.ownerId != currentPlayer.id) {
            final rent = prop.currentRent * multiplier;
            // Immediate Payment Rule
            currentPlayer.credits = max(0, currentPlayer.credits - rent);

            // Give credits to owner
            final owner = _players.firstWhere((p) => p.id == prop.ownerId);
            owner.credits += rent;

            _lastEffectMessage = "Paid Toll: $rent Credits";
          } else {
            _lastEffectMessage = "Welcome back to your Node.";
          }
        }
        break;
      default:
        break;
    }
    _safeNotifyListeners();
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

  /// Autosave: Only saves non-match progress (rank, stats)
  /// Does NOT save match state to prevent save/load exploits
  Future<void> autosave() async {
    if (_matchEnded || gameMode == GameMode.practice) return;

    try {
      for (final p in _players) {
        if (p.isHuman) {
          if (gameMode == GameMode.ranked || gameMode == GameMode.online) {
            await _leaderboardService.updatePlayerStats(p);
          } else {
            await _supabase.upsertPlayer(p);
          }
        }
      }
    } catch (e) {
      debugPrint('Autosave error: $e');
    }
  }

  /// Save the current game state manually (only for in-progress matches)
  Future<void> saveGame() async {
    if (gameMode != GameMode.practice) {
      _lastEffectMessage = "Manual save only allowed in Practice mode";
      notifyListeners();
      return;
    }

    if (_matchEnded) {
      _lastEffectMessage = "Cannot save: Match already ended";
      notifyListeners();
      return;
    }

    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

    for (final p in _players) {
      if (gameMode == GameMode.ranked && p.isHuman) {
        await _leaderboardService.updatePlayerStats(p);
      } else {
        await _supabase.upsertPlayer(p);
      }
    }

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

    await _supabase.saveGameState(_currentPlayerIndex);

    _lastEffectMessage = "Game Saved Successfully!";
    notifyListeners();
  }

  /// Load the game state manually (only for in-progress matches)
  Future<void> loadGame() async {
    if (gameMode != GameMode.practice) {
      _lastEffectMessage = "Manual load only allowed in Practice mode";
      notifyListeners();
      return;
    }

    if (_matchEnded) {
      _lastEffectMessage = "Cannot load: Match already ended";
      notifyListeners();
      return;
    }

    final result = await _gatekeeper.isChildAgentActive(
      _currentParentId,
      _currentChildId,
    );
    if (!result.isSuccess) {
      _lastEffectMessage = "ACCESS DENIED: Child Agent Offline";
      notifyListeners();
      return;
    }

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

  /// Handle game end: Update ranks and record match result
  Future<void> endGame({String? winnerId}) async {
    if (_matchEnded) return;

    _matchEnded = true;

    final humanPlayer = _players.firstWhere(
      (p) => p.isHuman && p.id == _currentChildId,
      orElse: () => _players.first,
    );

    final won =
        winnerId == _currentChildId ||
        (winnerId == null && humanPlayer.score >= 0);

    final matchResult = MatchResult(
      matchId: _currentMatchId ?? 'unknown',
      playerId: _currentChildId,
      won: won,
      isRanked: gameMode == GameMode.ranked,
      completedAt: DateTime.now(),
      finalScore: humanPlayer.score,
      finalCredits: humanPlayer.credits,
    );

    try {
      await _supabase.recordMatchResult(matchResult.toMap());
    } catch (e) {
      debugPrint('Error saving match result: $e');
    }

    if (gameMode == GameMode.ranked && humanPlayer.isHuman) {
      await _leaderboardService.updateRankAfterMatch(
        playerId: _currentChildId,
        won: won,
        isRankedMode: true,
      );
    }

    await autosave();

    _lastEffectMessage = won
        ? "Victory! ${gameMode == GameMode.ranked ? 'Rank updated.' : ''}"
        : "Defeat. ${gameMode == GameMode.ranked ? 'Rank updated.' : ''}";
    if (!_isDisposed) {
      notifyListeners();
    }
  }

  /// Check game over condition after each turn
  Future<void> _checkGameOverCondition() async {
    if (_matchEnded) return;

    bool gameOver = false;
    String? winnerId;

    // Condition 1: Bankruptcy (Credit <= 0)
    if (gameMode == GameMode.practice) {
      // Practice: Continue or End on target score
      if (_players.any((p) => p.score >= 5000)) {
        gameOver = true;
        winnerId = _players.reduce((a, b) => a.score > b.score ? a : b).id;
      }
    } else {
      // Ranked/Online: End if only one player with credits remains
      final activePlayers = _players.where((p) => p.credits > 0).toList();
      if (activePlayers.length <= 1) {
        gameOver = true;
        winnerId = activePlayers.isNotEmpty ? activePlayers.first.id : null;
      }

      // OR reach max score
      if (_players.any((p) => p.score >= 10000)) {
        gameOver = true;
        winnerId = _players.reduce((a, b) => a.score > b.score ? a : b).id;
      }
    }

    if (gameOver) {
      await endGame(winnerId: winnerId);
    }
  }
}
