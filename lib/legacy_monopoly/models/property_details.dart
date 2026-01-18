class PropertyDetails {
  final String nodeId;
  final String? ownerId;
  final int buildingLevel; // 0=Land, 1=Building, 2=Hotel, 3=Skyscraper
  final bool hasLandmark; // Lv4 equivalent (Unstealable)
  final int colorGroupId; // For set completion logic (x2/x4/x8 rent)
  final int baseValue;
  final int baseRent;

  const PropertyDetails({
    required this.nodeId,
    required this.baseValue,
    required this.baseRent,
    this.ownerId,
    this.buildingLevel = 0,
    this.hasLandmark = false,
    this.colorGroupId = 0,
  });

  /// Human-readable label for the current level
  String get levelName {
    if (hasLandmark || buildingLevel >= 4) return 'Landmark';
    switch (buildingLevel) {
      case 1:
        return 'Building α';
      case 2:
        return 'Building β';
      case 3:
        return 'Building γ';
      default:
        return 'Empty Lot';
    }
  }

  /// Create a copy with modified fields
  PropertyDetails copyWith({
    String? ownerId,
    int? buildingLevel,
    bool? hasLandmark,
  }) {
    return PropertyDetails(
      nodeId: nodeId,
      baseValue: baseValue,
      baseRent: baseRent,
      colorGroupId: colorGroupId,
      ownerId: ownerId ?? this.ownerId,
      buildingLevel: buildingLevel ?? this.buildingLevel,
      hasLandmark: hasLandmark ?? this.hasLandmark,
    );
  }

  // --- Game Logic ---

  static const double kUpgradeCostMultiplier = 0.5;

  /// Dynamic Rent Calculation
  int get currentRent {
    if (ownerId == null) return 0;

    // Rent Formula: Base * Multiplier
    int multiplier;

    if (hasLandmark) {
      multiplier = 8; // Level 4 (Landmark) -> 8x
    } else {
      switch (buildingLevel) {
        case 0:
          multiplier = 1; // Level 0 -> 1x
          break;
        case 1:
          multiplier = 2; // Level 1 -> 2x
          break;
        case 2:
          multiplier = 3; // Level 2 -> 3x
          break;
        case 3:
          multiplier = 4; // Level 3 -> 4x
          break;
        default:
          multiplier = 8; // Should correspond to Landmark/Max
      }
    }

    return baseRent * multiplier;
  }

  /// Cost to construct the next upgrade
  int get upgradeCost {
    // Simplified: Upgrade cost is 50% of base land value
    // Landmark (Level 4) might be more expensive
    if (buildingLevel >= 3) {
      return baseValue; // Level 3 -> 4 cost is full base value
    }
    return (baseValue * kUpgradeCostMultiplier).round();
  }

  /// Cost to takeover this property from an opponent
  /// Formula: (baseValue + upgradeCost * currentLevel) * 2
  int get takeoverCost {
    if (hasLandmark || buildingLevel >= 4) {
      return 9999999; // Effectively unstealable
    }

    // Note: This assumes 'upgradeCost' is constant for calculation simplicity
    // or refers to the *current* upgrade cost.
    // Based on requirement: "(baseValue + upgradeCost * currentLevel) * 2"
    // We'll use the current level's upgrade cost logic for consistency,
    // or better, a fixed base upgrade cost to avoid fluctuation if upgradeCost changes per level.
    // For now, using the standard upgrade cost derivative:

    int standardUpgradeCost = (baseValue * kUpgradeCostMultiplier).round();

    int totalValue = baseValue + (standardUpgradeCost * buildingLevel);
    return totalValue * 2;
  }
}
