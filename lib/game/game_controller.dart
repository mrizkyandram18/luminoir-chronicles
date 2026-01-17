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
  static const int kSalary = 200;
  static const int kStartBonus = 100;
  static const int kMinigameReward = 200;
  static const int kMinigameScore = 100;
  static const int kPrisonPenalty = 150;
  static const int kPrisonScorePenalty = 50;

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
  bool _passedStartThisMove = false; // Track START crossing per move

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

  /// Set players manually (mainly for testing or custom matches)
  void setPlayers(List<Player> newPlayers) {
    _players = newPlayers;
    _currentPlayerIndex = 0;
    _safeNotifyListeners();
  }

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
    if (!_canRoll) return;
    if (_isDisposed || _matchEnded || _isMoving) return;

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

    await _handleTileLanding();

    // After resolution, check if player went bankrupt during landing (e.g. paid rent)
    await _checkGameOverCondition();
    if (_matchEnded) return;

    // SYNC TO SUPABASE (Only if not practice)
    if (gameMode != GameMode.practice) {
      await _supabase.upsertPlayer(currentPlayer);
    }

    _isMoving = false;
    _canEndTurn = true;
    _safeNotifyListeners();

    await _checkGameOverCondition();
  }

  Future<void> _moveCurrentPlayer(int steps, {bool backward = false}) async {
    // Graph Traversal Logic
    String currentId = currentPlayer.nodeId;

    // Reset START passing flag at the start of each move
    _passedStartThisMove = false;

    if (backward) {
      // Phase 1: Simple teleport for backward movement
      // Calculate new index in the 20-node loop
      int currentIdx;
      try {
        currentIdx = int.parse(currentId.split('_').last);
      } catch (e) {
        currentIdx = 0;
      }

      int newIdx = (currentIdx - steps) % 20;
      if (newIdx < 0) newIdx += 20;

      currentId = 'node_$newIdx';
      currentPlayer.nodeId = currentId;
      currentPlayer.position = newIdx;

      _safeNotifyListeners();
      return;
    }

    // Track previous position to detect START crossing
    int previousPosition = currentPlayer.position;

    for (int i = 0; i < steps; i++) {
      BoardNode? node = _boardGraph.getNode(currentId);
      if (node != null && node.nextNodeIds.isNotEmpty) {
        // Logic for forks would go here. For now, take first.
        currentId = node.nextNodeIds.first;

        // UPDATE STATE STEP-BY-STEP
        currentPlayer.nodeId = currentId;

        // Sync legacy integer position for backward compatibility
        int newPosition;
        try {
          newPosition = int.parse(currentId.split('_').last);
        } catch (e) {
          newPosition = 0;
        }

        // Check for Passing Start (Salary) - only once per move
        // Detect crossing from position 19 to position 0 (wrapping around)
        if (!_passedStartThisMove &&
            previousPosition == 19 &&
            newPosition == 0) {
          // RULE: Passing START grants basic Salary
          // Total if landing exactly: Salary (200) + Bonus (100) = 300
          currentPlayer.credits += kSalary;
          _lastEffectMessage = "Passed Start! +$kSalary Credits";
          _passedStartThisMove = true; // Prevent duplicate grants
        }

        currentPlayer.position = newPosition;
        previousPosition = newPosition;

        _safeNotifyListeners(); // Trigger UI Animation
        await Future.delayed(
          const Duration(milliseconds: 100),
        ); // Wait for animation
      }
    }
  }

  /// Transition to the next turn (Requires roll completion)
  void endTurn() {
    if (_isMoving) return;
    if (!canEndTurn) return;
    if (!_matchEnded && gameMode != GameMode.practice) {
      autosave();
    }
    _nextTurn();
  }

  /// Force the next turn (Forced skip / administrative / test)
  void forceNextTurn() {
    _nextTurn();
  }

  @visibleForTesting
  Future<void> testMovePlayer(int steps, {bool backward = false}) async {
    await _moveCurrentPlayer(steps, backward: backward);
    await _handleTileLanding();
    await _checkGameOverCondition();
  }

  int _transferCredits({
    required Player from,
    Player? to,
    required int amount,
  }) {
    if (amount <= 0) return 0;
    final int actualPaid = min(from.credits, amount);
    if (actualPaid == 0) return 0;

    from.credits -= actualPaid;
    if (to != null && to != from) {
      to.credits += actualPaid;
    }

    return actualPaid;
  }

  Future<void> _checkBankruptcy({
    required Player player,
    required int requiredAmount,
    required int actualPaid,
  }) async {
    if (_matchEnded || requiredAmount <= 0) return;
    final bool unableToPay = actualPaid < requiredAmount;
    if (player.credits == 0 && unableToPay) {
      if (gameMode == GameMode.practice) {
        // Practice: No bankruptcy, just 0 credits
        return;
      }

      _lastEffectMessage = "BANKRUPT! ${player.name} has lost.";
      // NOTE: Actual game end is now handled in _checkGameOverCondition
    }
  }

  void _nextTurn() {
    _canEndTurn = false;
    _actionTakenThisTurn = false;
    _canRoll = true;
    _isMoving = false;

    _currentPlayerIndex = (_currentPlayerIndex + 1) % _players.length;
    _safeNotifyListeners();

    // AI Turn Logic
    if (!_players[_currentPlayerIndex].isHuman) {
      _processAiTurn();
    }
  }

  Future<void> _processAiTurn() async {
    if (_isDisposed || _matchEnded) return;

    await Future.delayed(const Duration(seconds: 1));

    if (!canRoll) return;

    double randomGauge = Random().nextDouble();
    await rollDice(gaugeValue: randomGauge);

    if (_matchEnded) return;

    await _attemptAiAction();

    if (canEndTurn) {
      endTurn();
    }
  }

  Future<void> _attemptAiAction() async {
    if (_isDisposed || _matchEnded) return;
    if (_isMoving) return;
    if (_actionTakenThisTurn) return;

    final String nodeId = currentPlayer.nodeId;
    final BoardNode? node = _boardGraph.getNode(nodeId);
    if (node == null || node.type != NodeType.property) return;

    int tileId;
    try {
      tileId = int.parse(nodeId.split('_').last);
    } catch (_) {
      return;
    }

    final PropertyDetails? prop = _properties[nodeId];
    if (prop == null) return;

    if (prop.ownerId == null) {
      await buyProperty(tileId);
      return;
    }

    if (prop.ownerId == currentPlayer.id) {
      await buyPropertyUpgrade(tileId);
      return;
    }

    await buyPropertyTakeover(tileId);
  }

  /// Buy a property the player is currently on or specified by ID
  Future<void> buyProperty(int tileId) async {
    if (_isMoving || _actionTakenThisTurn) return;

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
      final paid = _transferCredits(
        from: currentPlayer,
        amount: prop.baseValue,
      );
      await _checkBankruptcy(
        player: currentPlayer,
        requiredAmount: prop.baseValue,
        actualPaid: paid,
      );
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
    if (_isMoving || _actionTakenThisTurn) return;
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
      final paid = _transferCredits(from: currentPlayer, amount: cost);
      await _checkBankruptcy(
        player: currentPlayer,
        requiredAmount: cost,
        actualPaid: paid,
      );
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
    if (_isMoving || _actionTakenThisTurn) return;
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
      final paid = _transferCredits(
        from: currentPlayer,
        to: previousOwner,
        amount: cost,
      );
      await _checkBankruptcy(
        player: currentPlayer,
        requiredAmount: cost,
        actualPaid: paid,
      );

      if (previousOwner != null && gameMode != GameMode.practice) {
        await _supabase.upsertPlayer(previousOwner);
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

  bool _isResolvingEvent = false;

  Future<void> _handleTileLanding() async {
    String currentId = currentPlayer.nodeId;
    BoardNode? node = _boardGraph.getNode(currentId);
    if (node == null) return;

    final int multiplier = currentPlayer.scoreMultiplier;
    _currentEventCard = null;

    switch (node.type) {
      case NodeType.start:
        // RULE: Landing bonus is separate from Passing Salary
        // Passing (200) + Landing (100) = 300 Total
        currentPlayer.score += (200 * multiplier);
        currentPlayer.credits += kStartBonus;
        _lastEffectMessage =
            "Exact Landing Bonus! +${200 * multiplier} Score, +$kStartBonus Credits";
        break;
      case NodeType.minigame:
        int reward = kMinigameReward * multiplier;
        currentPlayer.credits += reward;
        currentPlayer.score += kMinigameScore * multiplier;
        _lastEffectMessage = "Dark Web Loot! +$reward Credits";
        break;
      case NodeType.prison:
        int penalty = kPrisonPenalty * multiplier;
        final paid = _transferCredits(from: currentPlayer, amount: penalty);
        currentPlayer.score = max(0, currentPlayer.score - kPrisonScorePenalty);
        await _checkBankruptcy(
          player: currentPlayer,
          requiredAmount: penalty,
          actualPaid: paid,
        );
        if (_matchEnded) return;
        _lastEffectMessage = "System Error! -$paid Credits";
        break;
      case NodeType.event:
        await _handleEventCardLanding();
        break;
      case NodeType.property:
        PropertyDetails? prop = _properties[currentId];
        if (prop != null) {
          if (prop.ownerId == null) {
            _lastEffectMessage =
                "AVAILABLE: ${node.label} (${prop.baseValue} CR)";
          } else if (prop.ownerId != currentPlayer.id) {
            // RULE: Rent is multiplied by the OWNER's stats
            final owner = _players.firstWhere((p) => p.id == prop.ownerId);
            final rent = prop.currentRent * owner.scoreMultiplier;

            // Immediate Payment Rule with Bankruptcy check
            final actualPayment = _transferCredits(
              from: currentPlayer,
              to: owner,
              amount: rent,
            );
            await _checkBankruptcy(
              player: currentPlayer,
              requiredAmount: rent,
              actualPaid: actualPayment,
            );
            if (_matchEnded) return;

            if (actualPayment < rent) {
              _lastEffectMessage =
                  "BANKRUPT! Paid $actualPayment CR to ${owner.name}";
            } else {
              _lastEffectMessage =
                  "Paid Toll: $actualPayment CR to ${owner.name}";
            }
          } else {
            _lastEffectMessage = "Secured Node: ${prop.levelName}";
          }
        }
        break;
      default:
        break;
    }
    _safeNotifyListeners();
  }

  Future<void> _handleEventCardLanding() async {
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
        final paid = _transferCredits(from: currentPlayer, amount: card.value);
        await _checkBankruptcy(
          player: currentPlayer,
          requiredAmount: card.value,
          actualPaid: paid,
        );
        break;
      case EventCardType.moveForward:
        await _moveCurrentPlayer(card.value);
        if (!_isResolvingEvent) {
          _isResolvingEvent = true;
          await _handleTileLanding();
          _isResolvingEvent = false;
        }
        break;
      case EventCardType.moveBackward:
        await _moveCurrentPlayer(card.value, backward: true);
        if (!_isResolvingEvent) {
          _isResolvingEvent = true;
          await _handleTileLanding();
          _isResolvingEvent = false;
        }
        break;
    }

    if (_matchEnded) return;
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
      await _supabase.upsertPlayer(p);
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

    // 1. PRACTICE MODE: Score Threshold Only
    if (gameMode == GameMode.practice) {
      // Continue until someone hits 5000 score
      // Bankruptcy does NOT end the game in Practice (they can recover via salary)
      if (_players.any((p) => p.score >= 5000)) {
        gameOver = true;
        winnerId = _players.reduce((a, b) => a.score > b.score ? a : b).id;
      }
    }
    // 2. RANKED / ONLINE: Bankruptcy OR Score Threshold
    else {
      // A) Last Standing Rule (Bankruptcy)
      // Count active players (credits > 0 OR owns properties)
      // Simpler rule: Players with 0 credits who couldn't pay are "out" logic-wise,
      // but for simplicity, we check if they are "Bankrupt" (0 credits + invalid state).
      // Here we assume if you have > 0 credits you are alive.

      final activePlayers = _players.where((p) => p.credits > 0).toList();

      // If 1 or 0 remain, game over
      if (activePlayers.length <= 1) {
        gameOver = true;
        winnerId = activePlayers.isNotEmpty ? activePlayers.first.id : null;
      }

      // B) Score Threshold (10,000)
      if (!gameOver && _players.any((p) => p.score >= 10000)) {
        gameOver = true;
        winnerId = _players.reduce((a, b) => a.score > b.score ? a : b).id;
      }
    }

    if (gameOver) {
      await endGame(winnerId: winnerId);
    }
  }
}
