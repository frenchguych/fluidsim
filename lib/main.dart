import 'package:flame/game.dart';
import 'package:fluidsim/game.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  final game = MyGame();
  runApp(ProviderScope(child: GameWidget(game: game)));
}
