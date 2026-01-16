import 'package:flutter/material.dart';

/// Represents a multiplayer game room
class GameRoom {
  final String id;
  final String roomCode;
  final String hostChildId;
  final String status; // 'waiting', 'playing', 'finished'
  final int maxPlayers;
  final String? currentTurnChildId;
  final Map<String, dynamic>? boardState;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? winnerChildId;

  const GameRoom({
    required this.id,
    required this.roomCode,
    required this.hostChildId,
    required this.status,
    required this.maxPlayers,
    this.currentTurnChildId,
    this.boardState,
    required this.createdAt,
    required this.updatedAt,
    this.winnerChildId,
  });

  bool get isWaiting => status == 'waiting';
  bool get isPlaying => status == 'playing';
  bool get isFinished => status == 'finished';

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_code': roomCode,
      'host_child_id': hostChildId,
      'status': status,
      'max_players': maxPlayers,
      'current_turn_child_id': currentTurnChildId,
      'board_state': boardState,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
      'winner_child_id': winnerChildId,
    };
  }

  factory GameRoom.fromMap(Map<String, dynamic> map) {
    return GameRoom(
      id: map['id'] ?? '',
      roomCode: map['room_code'] ?? '',
      hostChildId: map['host_child_id'] ?? '',
      status: map['status'] ?? 'waiting',
      maxPlayers: map['max_players']?.toInt() ?? 4,
      currentTurnChildId: map['current_turn_child_id'],
      boardState: map['board_state'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(
        map['created_at'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        map['updated_at'] ?? DateTime.now().toIso8601String(),
      ),
      winnerChildId: map['winner_child_id'],
    );
  }

  GameRoom copyWith({
    String? id,
    String? roomCode,
    String? hostChildId,
    String? status,
    int? maxPlayers,
    String? currentTurnChildId,
    Map<String, dynamic>? boardState,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? winnerChildId,
  }) {
    return GameRoom(
      id: id ?? this.id,
      roomCode: roomCode ?? this.roomCode,
      hostChildId: hostChildId ?? this.hostChildId,
      status: status ?? this.status,
      maxPlayers: maxPlayers ?? this.maxPlayers,
      currentTurnChildId: currentTurnChildId ?? this.currentTurnChildId,
      boardState: boardState ?? this.boardState,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      winnerChildId: winnerChildId ?? this.winnerChildId,
    );
  }
}

/// Represents a player in a multiplayer room
class RoomPlayer {
  final String id;
  final String roomId;
  final String childId;
  final String playerName;
  final Color playerColor;
  final int position;
  final int score;
  final int credits;
  final int scoreMultiplier;
  final bool isConnected;
  final DateTime joinedAt;
  final DateTime lastActionAt;

  const RoomPlayer({
    required this.id,
    required this.roomId,
    required this.childId,
    required this.playerName,
    required this.playerColor,
    this.position = 0,
    this.score = 0,
    this.credits = 500,
    this.scoreMultiplier = 1,
    this.isConnected = true,
    required this.joinedAt,
    required this.lastActionAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'room_id': roomId,
      'child_id': childId,
      'player_name': playerName,
      'player_color': playerColor.toARGB32(),
      'position': position,
      'score': score,
      'credits': credits,
      'score_multiplier': scoreMultiplier,
      'is_connected': isConnected,
      'joined_at': joinedAt.toIso8601String(),
      'last_action_at': lastActionAt.toIso8601String(),
    };
  }

  factory RoomPlayer.fromMap(Map<String, dynamic> map) {
    return RoomPlayer(
      id: map['id'] ?? '',
      roomId: map['room_id'] ?? '',
      childId: map['child_id'] ?? '',
      playerName: map['player_name'] ?? 'Unknown',
      playerColor: Color(map['player_color']?.toInt() ?? 0xFF2196F3),
      position: map['position']?.toInt() ?? 0,
      score: map['score']?.toInt() ?? 0,
      credits: map['credits']?.toInt() ?? 500,
      scoreMultiplier: map['score_multiplier']?.toInt() ?? 1,
      isConnected: map['is_connected'] ?? true,
      joinedAt: DateTime.parse(
        map['joined_at'] ?? DateTime.now().toIso8601String(),
      ),
      lastActionAt: DateTime.parse(
        map['last_action_at'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  RoomPlayer copyWith({
    String? id,
    String? roomId,
    String? childId,
    String? playerName,
    Color? playerColor,
    int? position,
    int? score,
    int? credits,
    int? scoreMultiplier,
    bool? isConnected,
    DateTime? joinedAt,
    DateTime? lastActionAt,
  }) {
    return RoomPlayer(
      id: id ?? this.id,
      roomId: roomId ?? this.roomId,
      childId: childId ?? this.childId,
      playerName: playerName ?? this.playerName,
      playerColor: playerColor ?? this.playerColor,
      position: position ?? this.position,
      score: score ?? this.score,
      credits: credits ?? this.credits,
      scoreMultiplier: scoreMultiplier ?? this.scoreMultiplier,
      isConnected: isConnected ?? this.isConnected,
      joinedAt: joinedAt ?? this.joinedAt,
      lastActionAt: lastActionAt ?? this.lastActionAt,
    );
  }
}
