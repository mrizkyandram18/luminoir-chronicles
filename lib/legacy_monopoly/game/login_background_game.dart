import 'dart:math';
import 'package:flame/components.dart';
import 'package:flame/effects.dart';
import 'package:flame/game.dart';
import 'package:flame/particles.dart';
import 'package:flutter/material.dart';

/// A simple background game that features cartoonish shapes and particles
/// matching the "Flame Engine starter assets" vibe.
class LoginBackgroundGame extends FlameGame {
  final Random _rnd = Random();

  @override
  Color backgroundColor() => const Color(0xFF87CEEB); // Cartoon Sky Blue

  @override
  Future<void> onLoad() async {
    // 1. Add some static "tiles" in the background to simulate a board
    // We'll just scatter them a bit or make a grid pattern
    _addBackgroundTiles();

    // 2. Add a spawners for floating "token" shapes
    add(TimerComponent(period: 1.5, repeat: true, onTick: _spawnFloatingShape));

    // 3. Add initial shapes so it's not empty
    for (int i = 0; i < 5; i++) {
      _spawnFloatingShape();
    }
  }

  void _addBackgroundTiles() {
    final tileSize = size.x / 8;
    for (double x = 0; x < size.x; x += tileSize) {
      for (double y = 0; y < size.y; y += tileSize) {
        if (_rnd.nextBool()) {
          add(
            RectangleComponent(
              position: Vector2(x, y),
              size: Vector2(tileSize * 0.9, tileSize * 0.9),
              paint: Paint()..color = Colors.white.withOpacity(0.1),
              anchor: Anchor.center,
            ),
          );
        }
      }
    }
  }

  void _spawnFloatingShape() {
    final isCircle = _rnd.nextBool();
    final shapeSize = Vector2.all(30 + _rnd.nextDouble() * 50);
    final startPos = Vector2(
      _rnd.nextDouble() * size.x,
      size.y + 50, // Start below screen
    );

    // Random cartoon colors
    final colors = [
      const Color(0xFFFF6B6B), // Red
      const Color(0xFF4ECDC4), // Teal
      const Color(0xFFFFD93D), // Yellow
      const Color(0xFF1A1A1D), // Dark
      const Color(0xFFFF9F1C), // Orange
    ];
    final color = colors[_rnd.nextInt(colors.length)];

    PositionComponent shape;

    if (isCircle) {
      shape = CircleComponent(
        radius: shapeSize.x / 2,
        paint: Paint()..color = color,
        position: startPos,
        anchor: Anchor.center,
      );
    } else {
      shape = RectangleComponent(
        size: shapeSize,
        paint: Paint()..color = color,
        position: startPos,
        anchor: Anchor.center,
      );
    }

    // Add movement logic (Move up and rotate)
    shape.add(
      MoveEffect.by(
        Vector2(0, -size.y - 150),
        EffectController(duration: 5 + _rnd.nextDouble() * 5),
      ),
    );

    shape.add(
      RotateEffect.by(pi * 2, EffectController(duration: 3, infinite: true)),
    );

    // Remove when out of screen
    shape.add(
      TimerComponent(
        period: 10,
        removeOnFinish: true,
        onTick: () {
          shape.removeFromParent();
        },
      ),
    );

    // Add particle trail
    _addSparkle(shape);

    add(shape);
  }

  void _addSparkle(PositionComponent parent) {
    // In a real starter asset setup, we might stick this to the shape
  }

  @override
  void update(double dt) {
    super.update(dt);
    // Occasional global particle burst
    if (_rnd.nextDouble() < 0.02) {
      _spawnParticleBurst(
        Vector2(_rnd.nextDouble() * size.x, _rnd.nextDouble() * size.y),
      );
    }
  }

  void _spawnParticleBurst(Vector2 position) {
    add(
      ParticleSystemComponent(
        particle: Particle.generate(
          count: 10,
          lifespan: 1,
          generator: (i) => AcceleratedParticle(
            acceleration: Vector2(0, 100),
            speed: Vector2(
              _rnd.nextDouble() * 200 - 100,
              _rnd.nextDouble() * 200 - 100,
            ),
            position: position,
            child: CircleParticle(
              radius: 4,
              paint: Paint()..color = Colors.white.withOpacity(0.8),
            ),
          ),
        ),
      ),
    );
  }
}
