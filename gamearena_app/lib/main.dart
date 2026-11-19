import 'package:flutter/material.dart';
import 'screens/videojuegos_screen.dart';

void main() => runApp(const GameArenaApp());

class GameArenaApp extends StatelessWidget {
  const GameArenaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GameArena',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(colorSchemeSeed: Colors.deepPurple, useMaterial3: true),
      home: const VideojuegosScreen(),
    );
  }
}
