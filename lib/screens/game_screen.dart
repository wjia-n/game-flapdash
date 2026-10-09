import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/flap_engine.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/meadow.dart';
import '../theme/sky_themes.dart';

/// Game screen: the engine owns all state; this widget renders it and
/// forwards taps. Ticker drives engine.tick()/dyingTick().
class GameScreen extends StatefulWidget {
  final FlapEngine engine;
  final FlapAudio audio;
  final FlapSettings settings;

  const GameScreen({
    super.key,
    required this.engine,
    required this.audio,
    required this.settings,
  });

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen>
    with WidgetsBindingObserver, SingleTickerProviderStateMixin {
  FlapEngine get _e => widget.engine;
  SkyThemeDef get _t => SkyThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);
  BirdStyleDef get _bird => BirdStyles.byIndex(widget.settings.birdStyle,
      custom: widget.settings.customBird);
  PipeStyleDef get _pipe => PipeStyles.byIndex(widget.settings.pipeStyle,
      custom: widget.settings.customPipe);

  Ticker? _ticker;
  Duration _lastTick = Duration.zero;
  bool _paused = false;
  bool _reviewAsked = false;
  int _flaps = 0;
  double _shakeAmp = 0;

  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.flapdash';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _e.onEvent = _onEvent;
    _e.addListener(_onEngine);
    _ticker = createTicker(_onTick)..start();
    widget.audio.startGameMusic();
    // Auto-begin after a beat so the countdown owns the flow.
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && _e.phase == FlapPhase.idle && !_paused) _e.begin();
    });
  }

  void _onEngine() {
    if (!mounted) return;
    setState(() {});
  }

  void _onTick(Duration d) {
    final dt = (d - _lastTick).inMicroseconds / 1e6;
    _lastTick = d;
    if (_paused || !mounted) return;
    if (_e.phase == FlapPhase.flying) {
      _e.tick(dt);
    } else if (_e.phase == FlapPhase.dying) {
      _e.dyingTick(dt);
    }
  }

  void _onEvent(FlapEvent e) {
    final a = widget.audio;
    switch (e) {
      case FlapEvent.flap:
        _flaps++;
        a.flap();
      case FlapEvent.score:
        a.score();
      case FlapEvent.medal:
        a.medal();
      case FlapEvent.crash:
        a.crash();
        _shakeAmp = 14;
      case FlapEvent.gameOver:
        _onGameOver();
      case FlapEvent.countdownTick:
        a.countBeep();
      case FlapEvent.gameStart:
        a.gameStart();
      case FlapEvent.attackTimeUp:
        a.win();
      case FlapEvent.attackHurry:
        a.countBeep();
      case FlapEvent.invalid:
        // Deliberately silent — stray taps during countdown shouldn't nag.
        break;
    }
  }

  Future<void> _onGameOver() async {
    final s = widget.settings;
    final newBest = await s.recordRun(score: _e.score, flaps: _flaps);
    widget.audio.lose();
    // Sensible review moment: a fresh personal best, occasionally.
    if (mounted &&
        newBest &&
        _e.score >= 10 &&
        s.gamesPlayed % 3 == 0 &&
        !_reviewAsked) {
      _reviewAsked = true;
      try {
        final review = InAppReview.instance;
        if (await review.isAvailable()) {
          await review.requestReview();
        }
      } catch (_) {}
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Backgrounding mid-flight = pause. Engine freezes its timers.
    if (state == AppLifecycleState.paused) {
      if (_e.flying || _e.phase == FlapPhase.countdown) {
        _setPaused(true);
      }
      widget.audio.onAppPaused();
    } else if (state == AppLifecycleState.resumed) {
      widget.audio.onAppResumed();
    }
  }

  void _setPaused(bool v) {
    if (_paused == v) return;
    setState(() => _paused = v);
    _e.setPaused(v);
    widget.audio.click();
    if (v) {
      widget.audio.onAppPaused();
    } else {
      widget.audio.onAppResumed();
      _lastTick = Duration.zero;
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _e.removeListener(_onEngine);
    _ticker?.dispose();
    _e.dispose();
    super.dispose();
  }

  void _tap() {
    if (_paused) return;
    if (_e.idle) {
      _e.begin();
    } else {
      _e.flap();
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final e = _e;
    return Scaffold(
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: _tap,
        child: Stack(
          children: [
            // The world (shakes briefly on crash).
            TweenAnimationBuilder<double>(
              tween: Tween(begin: _shakeAmp, end: 0),
              duration: const Duration(milliseconds: 500),
              onEnd: () => _shakeAmp = 0,
              builder: (_, amp, child) => Transform.translate(
                offset: Offset(
                  amp == 0 ? 0 : (Random().nextDouble() - 0.5) * amp,
                  amp == 0 ? 0 : (Random().nextDouble() - 0.5) * amp,
                ),
                child: child,
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: _FlapPainter(
                  e: e,
                  theme: t,
                  bird: _bird,
                  pipe: _pipe,
                ),
              ),
            ),
            // HUD.
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Score plaque.
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.black.withValues(alpha: 0.35),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2),
                      ),
                      child: Text(
                        '${e.score}',
                        style: Meadow.display(30,
                            color: Colors.white, theme: t),
                      ),
                    ),
                    if (e.mode == FlapMode.attack && e.flying)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.black.withValues(alpha: 0.35),
                          border: Border.all(
                              color: Colors.white.withValues(alpha: 0.6),
                              width: 2),
                        ),
                        child: Text(
                          '⏱ ${e.timeLeft.ceil()}',
                          style: Meadow.display(22,
                              color: Colors.white, theme: t),
                        ),
                      ),
                    // Pause button.
                    GestureDetector(
                      onTap: () {
                        if (e.flying ||
                            e.phase == FlapPhase.countdown) {
                          _setPaused(!_paused);
                        }
                      },
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.black.withValues(alpha: 0.35),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.6),
                              width: 2),
                        ),
                        child: Icon(
                          _paused ? Icons.play_arrow : Icons.pause,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // Banner narration (countdown, medals, hurry…).
            if (e.banner.isNotEmpty &&
                (e.phase == FlapPhase.countdown ||
                    e.phase == FlapPhase.dying ||
                    _paused))
              Positioned(
                top: 96,
                left: 0,
                right: 0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 22, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: Colors.black.withValues(alpha: 0.45),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.5),
                          width: 2),
                    ),
                    child: Text(
                      _paused
                          ? 'Paused'
                          : (e.phase == FlapPhase.countdown
                              ? '${e.countdown}'
                              : e.banner),
                      style: Meadow.display(
                          e.phase == FlapPhase.countdown ? 54 : 22,
                          color: Colors.white,
                          theme: t),
                    ),
                  ),
                ),
              ),
            // Tap-to-start hint.
            if (e.idle && !_paused)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('🐤', style: const TextStyle(fontSize: 72)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 26, vertical: 14),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.black.withValues(alpha: 0.45),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.6),
                            width: 2),
                      ),
                      child: Text(
                        'Tap to take flight!',
                        style: Meadow.display(24,
                            color: Colors.white, theme: t),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      e.mode == FlapMode.attack
                          ? '⏱ 60 seconds — thread every gate'
                          : 'Medals at 10 🥉 20 🥈 30 🥇 40 💠',
                      style: Meadow.body(14,
                          color: Colors.white, theme: t),
                    ),
                  ],
                ),
              ),
            // Pause overlay.
            if (_paused && !e.isOver)
              Positioned.fill(
                child: Container(
                  color: Colors.black.withValues(alpha: 0.55),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Paused',
                            style: Meadow.display(40,
                                color: Colors.white, theme: t)),
                        const SizedBox(height: 18),
                        PuffyButton(
                          label: '▶  Resume',
                          width: 220,
                          theme: t,
                          onTap: () => _setPaused(false),
                        ),
                        const SizedBox(height: 12),
                        PuffyButton(
                          label: '🏠  Quit to Menu',
                          width: 220,
                          fontSize: 16,
                          theme: t,
                          color: const Color(0xFF8A94A6),
                          onTap: () {
                            widget.audio.click();
                            Navigator.of(context).pop();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // Game-over panel.
            if (e.isOver) _gameOverPanel(theme: t),
          ],
        ),
      ),
    );
  }

  Widget _gameOverPanel({required SkyThemeDef theme}) {
    final e = _e;
    final s = widget.settings;
    final newBest = e.score > 0 && e.score >= s.best;
    final medalLine = e.medal != null
        ? 'Medal earned: ${e.medal}'
        : 'Medal: ${e.medalFor(e.score)}';
    return Positioned.fill(
      child: Container(
        color: Colors.black.withValues(alpha: 0.45),
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 30),
              padding: const EdgeInsets.symmetric(
                  horizontal: 24, vertical: 22),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: (theme.night
                        ? const Color(0xFF141B3D)
                        : Colors.white)
                    .withValues(alpha: 0.96),
                border: Border.all(
                    color: Colors.white.withValues(alpha: 0.8), width: 3),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 10),
                    blurRadius: 24,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    e.deathReason ?? 'Time!',
                    style: Meadow.display(26, theme: theme),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${s.pilotName} scored',
                    style: Meadow.body(14, theme: theme),
                  ),
                  Text(
                    '${e.score}',
                    style: Meadow.display(64, theme: theme),
                  ),
                  if (newBest && e.score > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 6),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: const Color(0xFFFFB800)
                            .withValues(alpha: 0.25),
                        border: Border.all(
                            color: const Color(0xFFFFB800), width: 2),
                      ),
                      child: Text('🏆 NEW BEST!',
                          style: Meadow.label(16, theme: theme)),
                    ),
                  Text(
                    medalLine,
                    style: Meadow.body(14, theme: theme),
                    textAlign: TextAlign.center,
                  ),
                  Text(
                    'Best: ${s.best}   •   ${difficultySpecs[e.difficulty].name}',
                    style: Meadow.body(13, theme: theme),
                  ),
                  const SizedBox(height: 16),
                  PuffyButton(
                    label: '🚀  Fly Again',
                    width: 230,
                    theme: theme,
                    color: const Color(0xFF6BAE3F),
                    onTap: () {
                      widget.audio.click();
                      _flaps = 0;
                      _reviewAsked = false;
                      e.restart();
                    },
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _SmallBtn(
                        theme: theme,
                        icon: Icons.home,
                        label: 'Menu',
                        onTap: () {
                          widget.audio.click();
                          Navigator.of(context).pop();
                        },
                      ),
                      const SizedBox(width: 12),
                      _SmallBtn(
                        theme: theme,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          await Share.share(
                              'I scored ${e.score} in Flap Dash as ${s.pilotName}! Can you beat me? $storeUrl');
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallBtn extends StatelessWidget {
  final SkyThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _SmallBtn(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.black.withValues(alpha: 0.08),
          border: Border.all(
              color: Colors.white.withValues(alpha: 0.7), width: 2),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: Meadow.display(1).color),
            const SizedBox(width: 6),
            Text(label, style: Meadow.label(14, theme: theme)),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// The world painter: sky, celestial body, clouds, hills, material gates,
// the bird, and floating score pops. All physical, all storybook.
class _FlapPainter extends CustomPainter {
  final FlapEngine e;
  final SkyThemeDef theme;
  final BirdStyleDef bird;
  final PipeStyleDef pipe;

  _FlapPainter({
    required this.e,
    required this.theme,
    required this.bird,
    required this.pipe,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // Sky.
    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.skyTop, theme.skyBot],
        ).createShader(Offset.zero & size),
    );

    if (theme.night) {
      final rnd = Random(7);
      for (int i = 0; i < 46; i++) {
        canvas.drawCircle(
            Offset(rnd.nextDouble() * w, rnd.nextDouble() * h * 0.7),
            1.6,
            Paint()..color = Colors.white70);
      }
      // Moon with a bite of shadow.
      canvas.drawCircle(Offset(w * 0.82, h * 0.13), 26,
          Paint()..color = theme.celestial);
      canvas.drawCircle(Offset(w * 0.82 - 10, h * 0.13 - 6), 21,
          Paint()..color = theme.skyTop);
    } else {
      // Sun with soft halo.
      canvas.drawCircle(
          Offset(w * 0.85, h * 0.12),
          46,
          Paint()..color = theme.celestial.withValues(alpha: 0.35));
      canvas.drawCircle(Offset(w * 0.85, h * 0.12), 32,
          Paint()..color = theme.celestial);
    }

    // Drifting clouds.
    final rnd = Random(3);
    for (int i = 0; i < 4; i++) {
      final cx =
          (rnd.nextDouble() * w + e.flightTime * (8 + i * 4)) % (w + 160) -
              80;
      final cy = rnd.nextDouble() * h * 0.45 + 20;
      final cp = Paint()..color = theme.cloud.withValues(alpha: 0.85);
      canvas.drawCircle(Offset(cx, cy), 22, cp);
      canvas.drawCircle(Offset(cx + 24, cy + 6), 17, cp);
      canvas.drawCircle(Offset(cx - 24, cy + 7), 15, cp);
    }

    // Hills with depth.
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.2, h * 1.06), radius: w * 0.52),
        pi,
        pi,
        true,
        Paint()..color = theme.hillFar);
    canvas.drawArc(
        Rect.fromCircle(center: Offset(w * 0.85, h * 1.1), radius: w * 0.46),
        pi,
        pi,
        true,
        Paint()..color = theme.hillNear);

    // Gates.
    for (final g in e.gates) {
      _drawGate(canvas, w, h, g);
    }

    // Floating score pops.
    for (final p in e.pops) {
      final a = (1 - p.ageMs / 900).clamp(0.0, 1.0);
      final ty = TextPainter(
        text: TextSpan(
          text: '+1',
          style: TextStyle(
            fontSize: 30,
            fontWeight: FontWeight.w900,
            color: Colors.white.withValues(alpha: a),
            shadows: const [
              Shadow(color: Colors.black54, offset: Offset(0, 2), blurRadius: 4)
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      ty.paint(
          canvas,
          Offset(p.x * w - ty.width / 2,
              p.y * h - (p.ageMs / 900) * 60 - ty.height / 2));
    }

    // The bird.
    _drawBird(canvas, w, h);
  }

  void _drawGate(Canvas canvas, double w, double h, Gate g) {
    final gx = g.x * w;
    final gw = FlapEngine.gateW * w;
    final gapH = e.spec.gapH * h;
    final gc = e.gapCenter(g) * h;
    final gapTop = gc - gapH / 2;
    final gapBot = gc + gapH / 2;
    // Slight parallax sway already baked into gapCenter; add a subtle
    // horizontal lean for storm gates.
    final lean = e.spec.wobble > 0
        ? cos(e.wobbleTime * 2.2 + g.wobblePhase) * 4.0
        : 0.0;
    _drawPipe(canvas, Rect.fromLTWH(gx + lean * 0.3, -24, gw, gapTop + 24));
    _drawPipe(canvas, Rect.fromLTWH(gx - lean * 0.3, gapBot, gw, h - gapBot + 24));
    // Shadow under the gate pair for depth.
    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(gx - 8, h - 26, gw + 16, 16),
          const Radius.circular(8)),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
  }

  void _drawPipe(Canvas canvas, Rect r) {
    // Body.
    canvas.drawRRect(
        RRect.fromRectAndRadius(r, const Radius.circular(10)),
        Paint()..color = pipe.main);
    // Light edge (bevel highlight).
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(r.left + 5, r.top + 6, 9, r.height - 12),
            const Radius.circular(4)),
        Paint()..color = pipe.light.withValues(alpha: 0.75));
    // Dark edge (ambient occlusion on the far side).
    canvas.drawRRect(
        RRect.fromRectAndRadius(
            Rect.fromLTWH(r.right - 12, r.top + 6, 7, r.height - 12),
            const Radius.circular(3.5)),
        Paint()..color = pipe.dark.withValues(alpha: 0.6));
    // Crystal facets for crystalline materials.
    if (pipe.crystalline) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left + r.width * 0.42, r.top + 10, 5,
                  r.height - 20),
              const Radius.circular(2.5)),
          Paint()..color = Colors.white.withValues(alpha: 0.5));
    } else {
      // Wood/metal grain bands.
      final band = Paint()..color = pipe.dark.withValues(alpha: 0.35);
      double y = r.top + 26;
      while (y < r.bottom - 20) {
        canvas.drawRect(Rect.fromLTWH(r.left + 4, y, r.width - 8, 3), band);
        y += 44;
      }
    }
    // Cap lip — physical rim.
    final capTop = r.top < 0 ? null : r.top;
    final capBot = r.bottom > 2000 ? null : r.bottom;
    if (capTop != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left - 5, capTop - 7, r.width + 10, 15),
              const Radius.circular(7)),
          Paint()..color = pipe.dark);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left - 5, capTop - 7, r.width + 10, 7),
              const Radius.circular(3.5)),
          Paint()..color = pipe.light);
    }
    if (capBot != null) {
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left - 5, capBot - 8, r.width + 10, 15),
              const Radius.circular(7)),
          Paint()..color = pipe.dark);
    }
  }

  void _drawBird(Canvas canvas, double w, double h) {
    final bx = FlapEngine.birdX * w;
    final by = e.birdY * h;
    final tilt = (e.vy * 0.45).clamp(-0.55, 0.7);
    final flapPop = e.phase == FlapPhase.flying
        ? (1 + 0.08 * sin(e.wingT * 2)).clamp(0.95, 1.1)
        : 1.0;
    canvas.save();
    canvas.translate(bx, by);
    canvas.rotate(tilt);
    canvas.scale(flapPop);
    // Drop shadow on the world below (fake AO).
    // Body.
    canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: 54, height: 42),
        Paint()..color = bird.body);
    // Belly.
    canvas.drawOval(Rect.fromCenter(center: const Offset(2, 10), width: 34, height: 20),
        Paint()..color = bird.belly.withValues(alpha: 0.85));
    // Wing — flaps visibly.
    final wingUp = sin(e.wingT) * 11;
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-5, -8 + wingUp * 0.45), width: 32, height: 17 + wingUp),
        Paint()..color = bird.wing);
    canvas.drawOval(
        Rect.fromCenter(
            center: Offset(-5, -8 + wingUp * 0.45), width: 20, height: (17 + wingUp) * 0.55),
        Paint()..color = Colors.white.withValues(alpha: 0.25));
    // Eye.
    canvas.drawCircle(const Offset(13, -8), 8.5, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(15, -8), 3.8, Paint()..color = Colors.black);
    canvas.drawCircle(
        const Offset(16.2, -9.2), 1.2, Paint()..color = Colors.white);
    // Beak.
    final beak = Path()
      ..moveTo(25, -2)
      ..lineTo(40, 3)
      ..lineTo(25, 8)
      ..close();
    canvas.drawPath(beak, Paint()..color = bird.beak);
    // Tail.
    final tail = Path()
      ..moveTo(-25, 0)
      ..lineTo(-40, -11)
      ..lineTo(-37, 9)
      ..close();
    canvas.drawPath(tail, Paint()..color = bird.wing);
    canvas.restore();

    // Dizzy X eyes while dying.
    if (e.phase == FlapPhase.dying) {
      canvas.save();
      canvas.translate(bx + 13, by - 8);
      final p = Paint()
        ..color = Colors.black
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round;
      canvas.drawLine(const Offset(-5, -5), const Offset(5, 5), p);
      canvas.drawLine(const Offset(-5, 5), const Offset(5, -5), p);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
