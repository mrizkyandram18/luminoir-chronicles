import '../models/raid_equipment.dart';
import '../models/raid_player.dart';

class EquipmentSystem {
  // Stateless Logic for Equipment Management

  bool merge(RaidPlayer player, RaidEquipment itemA, RaidEquipment itemB) {
    if (!player.equipment.contains(itemA) ||
        !player.equipment.contains(itemB)) {
      return false;
    }
    if (itemA == itemB) return false;

    // Strict Match: Name and Rarity
    if (itemA.name != itemB.name || itemA.rarity != itemB.rarity) return false;

    player.equipment.remove(itemA);
    player.equipment.remove(itemB);

    final newItem = itemA.upgrade();
    player.equip(newItem); // Adds to list and updates stats/bonus if applicable

    return true;
  }
}
