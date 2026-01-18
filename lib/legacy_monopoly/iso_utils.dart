import 'package:flame/components.dart';

class IsoUtils {
  static Vector2 gridToIso(Vector2 gridPosition) {
    final x = gridPosition.x;
    final y = gridPosition.y;
    final isoX = (x - y) * 32;
    final isoY = (x + y) * 16;
    return Vector2(isoX, isoY);
  }

  static Vector2 getGridCoordinateFromIndex(int index, int totalTiles) {
    final sideLength = totalTiles ~/ 4;
    final sideIndex = index ~/ sideLength;
    final offset = index % sideLength;

    switch (sideIndex) {
      case 0:
        return Vector2(sideLength - offset.toDouble(), sideLength.toDouble());
      case 1:
        return Vector2(0, sideLength - offset.toDouble());
      case 2:
        return Vector2(offset.toDouble(), 0);
      case 3:
        return Vector2(sideLength.toDouble(), offset.toDouble());
      default:
        return Vector2.zero();
    }
  }
}

