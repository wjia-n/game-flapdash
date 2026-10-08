import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wajiha_game_core/wajiha_game_core.dart';

/// Flap Dash — tap to flap through the crystal gates. 🐤
class FlapDashScreen extends StatefulWidget {
  final List<Player> players;
  final GameCallbacks callbacks;

  const FlapDashScreen({super.key, required this.players, required this.callbacks});

  @override
  State<FlapDashScreen> createState() => _FlapDashScreenState();
}

class _Gate {
  double x;
  double gapY; // center of gap, fraction of height
  bool scored = false;
  _Gate(this.x, this.gapY);
}

class _FlapDashScreenState extends State<FlapDashScreen> {
  static const _bestKey = 'flapdash_best';

  final _rand = Random();
  Ticker? _ticker;
  double _lastSec = 0;
  bool over = false;
  bool started = false;
  bool night = false;

  double birdY = 0.45; // fraction of height
  double vy = 0; // fraction per second
  List<_Gate> gates = [];
  double speed = 0.28; // fraction of width per second
  int best = 0;
  double wingT = 0;

  static const double _birdX = 0.32;
  static const double _gapH = 0.24;
  static const double _gateW = 0.09;

  int get score => widget.players[0].score;

  @override
  void initState() {
    super.initState();
    _loadBest();
  }

  Future<void> _loadBest() async {
    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() => best = prefs.getInt(_bestKey) ?? 0);
  }

  void _begin() {
    setState(() {
      started = true;
      over = false;
      night = _rand.nextBool();
      birdY = 0.45;
      vy = 0;
      gates = [_Gate(1.2, _randGap()), _Gate(1.85, _randGap())];
      widget.players[0].score = 0;
      speed = 0.28;
    });
    widget.callbacks.refreshHud();
    _lastSec = 0;
    _ticker?.dispose();
    _ticker = Ticker(_tick)..start();
    Sfx.click();
  }

  double _randGap() => 0.25 + _rand.nextDouble() * 0.5;

  void _flap() {
    if (over || !started) return;
    Sfx.move();
    setState(() => vy = -0.85);
  }

  void _tick(Duration d) {
    final sec = d.inMicroseconds / 1e6;
    final dt = min(0.05, _lastSec == 0 ? 0.016 : sec - _lastSec);
    _lastSec = sec;
    if (over || !mounted || !started) return;
    setState(() {
      wingT += dt * 10;
      vy += 2.6 * dt; // gravity
      birdY += vy * dt;
      if (birdY < 0.02 || birdY > 0.98) {
        _gameOver(birdY <= 0.02 ? 'To the moon! 🌙' : 'Face-plant! 💥');
        return;
      }
      for (final g in gates) {
        g.x -= speed * dt;
      }
      gates.removeWhere((g) => g.x < -0.2);
      while (gates.isEmpty || gates.last.x < 1.0) {
        gates.add(_Gate((gates.isEmpty ? 0.9 : gates.last.x) + 0.65, _randGap()));
      }
      // scoring + collisions
      const birdR = 0.035;
      for (final g in gates) {
        if (!g.scored && g.x + _gateW < _birdX) {
          g.scored = true;
          widget.players[0].score++;
          speed = min(0.42, speed + 0.004);
          Sfx.tap();
          widget.callbacks.refreshHud();
        }
        if ((_birdX + birdR > g.x) && (_birdX - birdR < g.x + _gateW)) {
          final gapTop = g.gapY - _gapH / 2;
          final gapBot = g.gapY + _gapH / 2;
          if (birdY - birdR < gapTop || birdY + birdR > gapBot) {
            _gameOver('Gate crash! 💎');
            return;
          }
        }
      }
    });
  }

  String _medal(int s) {
    if (s >= 40) return 'Platinum 💠';
    if (s >= 30) return 'Gold 🥇';
    if (s >= 20) return 'Silver 🥈';
    if (s >= 10) return 'Bronze 🥉';
    return 'no medal yet — keep flapping!';
  }

  Future<void> _gameOver(String reason) async {
    if (over) return;
    over = true;
    _ticker?.stop();
    Sfx.lose();
    final s = score;
    final isBest = s > best;
    if (isBest) {
      best = s;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_bestKey, best);
    }
    if (!mounted) return;
    widget.callbacks.finish(
      headline: '$reason Score: $s! 🐤',
      subline: 'Medal: ${_medal(s)}${isBest ? ' — NEW BEST! 🏆' : ' — best: $best'}',
    );
  }

  @override
  void dispose() {
    _ticker?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeController.of(context).theme;
    if (!started) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('🐤', style: TextStyle(fontSize: 64)),
              const SizedBox(height: 12),
              Text('Tap to flap. Thread the gates.',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: theme.text),
                  textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text('Medals at 10 🥉 20 🥈 30 🥇 40 💠. Day and night flights. Don\'t bonk the crystals!',
                  style: TextStyle(color: theme.muted, fontWeight: FontWeight.w600), textAlign: TextAlign.center),
              const SizedBox(height: 20),
              WajihaButton(label: 'Take flight', emoji: '🚀', onTap: _begin, primary: true),
              const SizedBox(height: 12),
              Text('Best: $best', style: TextStyle(color: theme.muted, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      );
    }
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: _flap,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.infinite,
            painter: _FlapPainter(
              birdY: birdY,
              vy: vy,
              gates: gates,
              night: night,
              wingT: wingT,
              theme: theme,
            ),
          ),
          Positioned(
            top: 8, left: 12, right: 12,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('🐤 $score', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w900, color: theme.text)),
                Text(night ? '🌙 night flight' : '☀️ day flight',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.muted)),
                Text('best $best', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: theme.muted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FlapPainter extends CustomPainter {
  final double birdY;
  final double vy;
  final List<_Gate> gates;
  final bool night;
  final double wingT;
  final GameTheme theme;

  _FlapPainter({
    required this.birdY,
    required this.vy,
    required this.gates,
    required this.night,
    required this.wingT,
    required this.theme,
  });

  static const double _birdX = 0.32;
  static const double _gapH = 0.24;
  static const double _gateW = 0.09;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // sky
    final sky = night ? const Color(0xFF141A33) : const Color(0xFF8ED6FF);
    canvas.drawRect(Offset.zero & size, Paint()..color = sky);
    if (night) {
      final rnd = Random(7);
      for (int i = 0; i < 40; i++) {
        canvas.drawCircle(
            Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.7), 1.6, Paint()..color = Colors.white70);
      }
      canvas.drawCircle(Offset(w * 0.82, h * 0.14), 26, Paint()..color = const Color(0xFFF5F0DC));
      canvas.drawCircle(Offset(w * 0.82 - 10, h * 0.14 - 6), 22, Paint()..color = const Color(0xFF141A33));
    } else {
      // sun + clouds
      canvas.drawCircle(Offset(w * 0.85, h * 0.12), 34, Paint()..color = const Color(0xFFFFD93B));
      final rnd = Random(3);
      for (int i = 0; i < 5; i++) {
        final cx = rnd.nextDouble() * w;
        final cy = rnd.nextDouble() * h * 0.5;
        canvas.drawCircle(Offset(cx, cy), 22, Paint()..color = Colors.white.withValues(alpha: 0.85));
        canvas.drawCircle(Offset(cx + 24, cy + 6), 17, Paint()..color = Colors.white.withValues(alpha: 0.85));
      }
    }
    // distant hills
    canvas.drawArc(Rect.fromCircle(center: Offset(w * 0.2, h * 1.05), radius: w * 0.5), pi, pi, true,
        Paint()..color = (night ? const Color(0xFF1E2A4A) : const Color(0xFF7BC96F)));
    canvas.drawArc(Rect.fromCircle(center: Offset(w * 0.85, h * 1.08), radius: w * 0.45), pi, pi, true,
        Paint()..color = (night ? const Color(0xFF1E2A4A) : const Color(0xFF7BC96F)));

    // crystal gates
    for (final g in gates) {
      final gx = g.x * w;
      final gw = _gateW * w;
      final gapTop = (g.gapY - _gapH / 2) * h;
      final gapBot = (g.gapY + _gapH / 2) * h;
      final crystal = night ? const Color(0xFF7C5CFF) : const Color(0xFF38BDF8);
      // top crystal
      _drawCrystal(canvas, Rect.fromLTWH(gx, -20, gw, gapTop + 20), crystal);
      // bottom crystal
      _drawCrystal(canvas, Rect.fromLTWH(gx, gapBot, gw, h - gapBot + 20), crystal);
    }

    // the bird (dash the finch!)
    final bx = _birdX * w;
    final by = birdY * h;
    final tilt = (vy * 0.5).clamp(-0.5, 0.6);
    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(tilt);
    // body
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 52, height: 40), Paint()..color = const Color(0xFFFFC93B));
    // wing (flaps)
    final wingUp = sin(wingT) * 10;
    canvas.drawOval(Rect.fromCenter(center: Offset(-4, -8 + wingUp * 0.4), width: 30, height: 16 + wingUp),
        Paint()..color = const Color(0xFFFF9F1C));
    // eye
    canvas.drawCircle(const Offset(12, -8), 8, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(14, -8), 3.6, Paint()..color = Colors.black);
    // beak
    final beak = Path()
      ..moveTo(24, -2)
      ..lineTo(38, 3)
      ..lineTo(24, 8)
      ..close();
    canvas.drawPath(beak, Paint()..color = const Color(0xFFFF6B35));
    // tail
    final tail = Path()
      ..moveTo(-24, 0)
      ..lineTo(-38, -10)
      ..lineTo(-36, 8)
      ..close();
    canvas.drawPath(tail, Paint()..color = const Color(0xFFFF9F1C));
    canvas.restore();
  }

  void _drawCrystal(Canvas canvas, Rect r, Color c) {
    canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(10)), Paint()..color = c);
    // facets
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left + 6, r.top + 8, 8, r.height - 16), const Radius.circular(4)),
        Paint()..color = Colors.white.withValues(alpha: 0.35));
    // caps
    canvas.drawRRect(
        RRect.fromRectAndRadius(Rect.fromLTWH(r.left - 4, r.top, r.width + 8, 14), const Radius.circular(7)),
        Paint()..color = c.withValues(alpha: 0.9));
  }

  @override
  bool shouldRepaint(covariant _FlapPainter old) => true;
}
