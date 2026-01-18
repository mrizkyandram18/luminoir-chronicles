import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import '../cyber_raid_game.dart';
import '../models/raid_player.dart';

import '../widgets/raid_hud.dart';
import '../widgets/inventory_widget.dart';

class RaidScreen extends StatefulWidget {
  final String myPlayerId;
  final PlayerJob myJob;
  final bool openInventoryOnStart;

  const RaidScreen({
    super.key,
    required this.myPlayerId,
    required this.myJob,
    this.openInventoryOnStart = false,
  });

  @override
  State<RaidScreen> createState() => _RaidScreenState();
}

class _RaidScreenState extends State<RaidScreen> {
  late CyberRaidGame _game;

  @override
  void initState() {
    super.initState();
    _game = CyberRaidGame(
      myPlayerId: widget.myPlayerId,
      myJob: widget.myJob,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: GameWidget(
        game: _game,
        overlayBuilderMap: {
          'HUD': (BuildContext context, CyberRaidGame game) {
            return RaidHud(game: game);
          },
          'Inventory': (BuildContext context, CyberRaidGame game) {
            return Center(
              child: SizedBox(
                height: 400,
                width: 600,
                child: InventoryWidget(
                  player: game.myPlayer,
                  onEquip: (item) {},
                  onMerge: (a, b) => game.merge(a, b),
                ),
              ),
            );
          },
        },
        initialActiveOverlays: widget.openInventoryOnStart
            ? const ['HUD', 'Inventory']
            : const ['HUD'],
      ),
    );
  }
}
