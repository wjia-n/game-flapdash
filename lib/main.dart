import 'package:flutter/material.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';
import 'game_screen.dart';

void main() => runApp(const FlapDashApp());

class FlapDashApp extends StatelessWidget {
  const FlapDashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GameShell(
      title: 'Flap Dash',
      tagline: 'One tap at a time — thread the crystal gates.',
      emoji: '🐤',
      slug: 'flapdash',
      howToPlay:
          '• TAP to flap your wings. Gravity is rude.\n• Thread the glowing crystal gates — don\'t bonk them!\n• Medals at 10 🥉 20 🥈 30 🥇 and 40 💠.\n• Day and night flights. Speed creeps up. Stay frosty. 🐤',
      playerOptions: const [1],
      supportsBots: false,
      gameBuilder: (ctx, players, cb) => FlapDashScreen(players: players, callbacks: cb),
    );
  }
}
