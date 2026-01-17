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

  /// Dynamic Rent Calculation
  int get currentRent {
    if (ownerId == null) return 0;

    // Rent Formula: Base + (Base * BuildingMultiplier * Level)
    double multiplier = 1.0;

    if (hasLandmark || buildingLevel >= 4) {
      multiplier = 8.0; // Massive rent for Landmarks
    } else {
      // Land(0): 1x, B1(1): 2x, B2(2): 3x, B3(3): 4x
      multiplier = 1.0 + buildingLevel;
    }

    return (baseRent * multiplier).round();
  }

  /// Cost to construct the next upgrade
  int get upgradeCost {
    // Simplified: Upgrade cost is 50% of base land value
    // Landmark (Level 4) might be more expensive
    if (buildingLevel >= 3) return baseValue;
    return (baseValue * 0.5).round();
  }

  /// Cost to takeover this property from an opponent
  /// Usually 2x the total current value
  int get takeoverCost {
    if (hasLandmark || buildingLevel >= 4) {
      return 9999999; // Effectively unstealable
    }
    int totalValue = baseValue + (upgradeCost * buildingLevel);
    return totalValue * 2;
  }
}
