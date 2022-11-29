import 'dart:math';

import 'package:fast_noise/fast_noise.dart';
import 'package:flame/game.dart';
import 'package:fluidsim/fluid_grid.dart';
import 'package:flutter/material.dart';

class MyGame extends Game with SingleGameInstance {
  MyGame();

  static const n = 128;

  final paint = Paint()..color = Colors.red;
  final viewport = FixedResolutionViewport(Vector2.all(n.toDouble()));
  final FluidGrid fluidGrid = FluidGrid(n, 0.0000001, 0.000001);
  final noise = PerlinNoise();

  double time = 0;
  double angle = pi / 2;

  @override
  void update(double dt) {
    time += dt;
    for (var j = -1; j <= 1; j++) {
      for (var i = -1; i <= 1; i++) {
        fluidGrid.addDensity(
          n ~/ 2 + i,
          n ~/ 2 + j,
          150,
        );
      }
    }

    while (angle < 0) {
      angle += 2 * pi;
    }
    while (angle > 2 * pi) {
      angle -= 2 * pi;
    }
    angle += Random().nextDouble() / 10;
    final v = Vector2(cos(angle), sin(angle)).normalized() * 2;
    fluidGrid
      ..addVelocity(n ~/ 2, n ~/ 2, v.x, v.y)
      ..step(dt);
  }

  @override
  void render(Canvas canvas) {
    viewport
      ..resize(size)
      ..render(canvas, (c) {
        for (var i = 0; i < fluidGrid.size; i++) {
          for (var j = 0; j < fluidGrid.size; j++) {
            var d = fluidGrid.density[fluidGrid.ix(i, j)];
            d = d.clamp(0, 255);
            paint.color = Color.fromRGBO(
              255,
              255,
              255,
              d / 255,
            );
            c.drawRect(Rect.fromLTWH(i.toDouble(), j.toDouble(), 1, 1), paint);
          }
        }
      });
  }
}
