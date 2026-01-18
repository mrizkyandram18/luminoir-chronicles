import 'package:flutter/material.dart';
import '../models/raid_equipment.dart';
import '../models/raid_player.dart';

class InventoryWidget extends StatefulWidget {
  final RaidPlayer player;
  final Function(RaidEquipment) onEquip;
  final Function(RaidEquipment, RaidEquipment) onMerge;

  const InventoryWidget({
    super.key,
    required this.player,
    required this.onEquip,
    required this.onMerge,
  });

  @override
  State<InventoryWidget> createState() => _InventoryWidgetState();
}

class _InventoryWidgetState extends State<InventoryWidget> {
  RaidEquipment? _selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border.all(color: Colors.cyanAccent),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "ARMORY",
            style: TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            "Tap 2 identical items to MERGE",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 5,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              itemCount: widget.player.equipment.length,
              itemBuilder: (context, index) {
                final item = widget.player.equipment[index];
                final isSelected = identical(_selected, item);
                return GestureDetector(
                  onTap: () {
                    if (_selected == null) {
                      setState(() {
                        _selected = item;
                      });
                      return;
                    }
                    if (identical(_selected, item)) {
                      setState(() {
                        _selected = null;
                      });
                      return;
                    }
                    final first = _selected!;
                    _selected = null;
                    widget.onMerge(first, item);
                    setState(() {});
                  },
                  child: _buildItemSlot(item, isSelected),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildItemSlot(RaidEquipment item, bool selected) {
    Color rarityColor = Colors.grey;
    if (item.rarity == Rarity.rare) rarityColor = Colors.blueAccent;
    if (item.rarity == Rarity.legendary) rarityColor = Colors.orangeAccent;

    return Container(
      decoration: BoxDecoration(
        color: selected ? Colors.cyanAccent.withValues(alpha: 0.1) : Colors.black,
        border: Border.all(
          color: selected ? Colors.cyanAccent : rarityColor,
          width: selected ? 3 : 2,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            item.type == EquipmentType.weapon ? Icons.security : Icons.shield,
            color: rarityColor,
            size: 20,
          ),
          Text(
            "${item.attackBonus}",
            style: const TextStyle(color: Colors.white, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
