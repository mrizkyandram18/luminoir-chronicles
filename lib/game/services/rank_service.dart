import '../models/rank_tier.dart';

class RankService {
  static const int winPoints = 50;
  static const int lossPoints = -25;
  static const int minRankPoints = 0;

  static RankTier calculateTier(int rankPoints) {
    return rankTierFromPoints(rankPoints);
  }

  static int calculateNewRankPoints(int currentPoints, bool won) {
    final newPoints = currentPoints + (won ? winPoints : lossPoints);
    return newPoints.clamp(minRankPoints, double.infinity).toInt();
  }

  static bool shouldUpdateRank(bool isRankedMode, bool isHuman) {
    return isRankedMode && isHuman;
  }
}
