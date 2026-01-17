class MatchResult {
  final String matchId;
  final String playerId;
  final bool won;
  final bool isRanked;
  final DateTime completedAt;
  final int finalScore;
  final int finalCredits;

  MatchResult({
    required this.matchId,
    required this.playerId,
    required this.won,
    required this.isRanked,
    required this.completedAt,
    required this.finalScore,
    required this.finalCredits,
  });

  Map<String, dynamic> toMap() {
    return {
      'match_id': matchId,
      'player_id': playerId,
      'won': won,
      'is_ranked': isRanked,
      'completed_at': completedAt.toIso8601String(),
      'final_score': finalScore,
      'final_credits': finalCredits,
    };
  }

  factory MatchResult.fromMap(Map<String, dynamic> map) {
    return MatchResult(
      matchId: map['match_id'] ?? '',
      playerId: map['player_id'] ?? '',
      won: map['won'] ?? false,
      isRanked: map['is_ranked'] ?? false,
      completedAt: DateTime.parse(map['completed_at']),
      finalScore: map['final_score'] ?? 0,
      finalCredits: map['final_credits'] ?? 0,
    );
  }
}
