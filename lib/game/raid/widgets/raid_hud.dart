import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flame/components.dart';
import 'package:flame/widgets.dart';
import 'package:go_router/go_router.dart';
import '../raid_game.dart';
import '../models/raid_player.dart';

class RaidHud extends StatelessWidget {
  final RaidGame game;

  const RaidHud({super.key, required this.game});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Stack(
        children: [
          Positioned(
            top: 8,
            left: 8,
            child: GestureDetector(
              onTap: () {
                context.go(
                  '/main-menu',
                  extra: {'childId': game.myPlayerId},
                );
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black87.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.white24),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(
                      Icons.arrow_back,
                      color: Colors.white,
                      size: 18,
                    ),
                    SizedBox(width: 4),
                    Text(
                      "Back",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned(
            top: 8,
            left: 80,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black87.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                children: [
                  ValueListenableBuilder<int>(
                    valueListenable: game.goldNotifier,
                    builder: (context, gold, _) {
                      return Row(
                        children: [
                          const Icon(
                            Icons.monetization_on,
                            color: Colors.amberAccent,
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            gold.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  const Spacer(),
                  ValueListenableBuilder<double>(
                    valueListenable: game.bossTimerNotifier,
                    builder: (context, timer, _) {
                      final remaining = timer.clamp(0, 9999);
                      final minutes = remaining ~/ 60;
                      final seconds = (remaining % 60).toInt();
                      final text =
                          "${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}";
                      return Row(
                        children: [
                          const Icon(
                            Icons.timer,
                            color: Colors.white70,
                            size: 18,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            text,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 56,
            left: 0,
            right: 0,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 56,
                    height: 56,
                    child: _HeroSprite(job: game.myJob),
                  ),
                  const SizedBox(height: 4),
                  ValueListenableBuilder<int>(
                    valueListenable: game.waveNotifier,
                    builder: (context, wave, _) {
                      return Text(
                        "Stage ${game.stage} - Wave $wave",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            top: 92,
            left: 32,
            right: 32,
            child: ValueListenableBuilder<bool>(
              valueListenable: game.isBossWaveNotifier,
              builder: (context, isBoss, _) {
                if (!isBoss) {
                  return const SizedBox.shrink();
                }
                return ValueListenableBuilder<double>(
                  valueListenable: game.bossHpNotifier,
                  builder: (context, hp, _) {
                    final max = game.bossMaxHp;
                    final pct = (hp / max).clamp(0.0, 1.0);
                    return Container(
                      height: 18,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.redAccent),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(9),
                        child: LinearProgressIndicator(
                          value: pct,
                          color: Colors.redAccent,
                          backgroundColor:
                              Colors.redAccent.withValues(alpha: 0.2),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 96,
            child: Center(
              child: Container(
                width: 120,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.amber.shade700,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black54,
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: _HeroSprite(job: game.myJob),
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              padding: const EdgeInsets.all(16),
              color: Colors.black87,
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => game.upgradeAttack(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.cyan,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              "UPGRADE",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () => game.gachaSummon(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.purple,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              "SUMMON",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              if (game.overlays.isActive('Inventory')) {
                                game.overlays.remove('Inventory');
                              } else {
                                game.overlays.add('Inventory');
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              padding:
                                  const EdgeInsets.symmetric(vertical: 8),
                            ),
                            child: const Text(
                              "BAG",
                              style: TextStyle(
                                color: Colors.black,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => game.manualAttack(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.greenAccent.shade400,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: const Text(
                          "ATTACK",
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}

class _HeroSprite extends StatelessWidget {
  final PlayerJob job;

  const _HeroSprite({required this.job});

  @override
  Widget build(BuildContext context) {
    final path = _spritePathForJob(job);
    final data = SpriteAnimationData.sequenced(
      amount: 6,
      stepTime: 0.12,
      textureSize: Vector2(32, 32),
    );

    return FutureBuilder<bool>(
      future: _spriteExists(path),
      builder: (context, snapshot) {
        final hasSprite = snapshot.data == true;
        if (!hasSprite) {
          return const Icon(
            Icons.person,
            color: Colors.white,
            size: 40,
          );
        }
        return SpriteAnimationWidget.asset(
          path: path,
          data: data,
          anchor: Anchor.center,
          errorBuilder: (context) {
            return const Icon(
              Icons.person,
              color: Colors.white,
              size: 40,
            );
          },
        );
      },
    );
  }
}

String _spritePathForJob(PlayerJob job) {
  if (job == PlayerJob.mage) {
    return 'raid_sprites/mage.png';
  }
  if (job == PlayerJob.archer) {
    return 'raid_sprites/archer.png';
  }
  if (job == PlayerJob.assassin) {
    return 'raid_sprites/assassin.png';
  }
  return 'raid_sprites/warrior.png';
}

Future<bool> _spriteExists(String relativePath) async {
  try {
    await rootBundle.load('assets/images/$relativePath');
    return true;
  } catch (_) {
    return false;
  }
}
