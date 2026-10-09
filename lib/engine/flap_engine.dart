import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

// ---------------------------------------------------------------------------
// Flap Dash engine — owns ALL game state and phases. The UI only renders and
// forwards input. A watchdog recovers any phase found without a live timer,
// so stuck states are impossible by construction.
// ---------------------------------------------------------------------------

/// Phases owned entirely by the engine.
/// [idle] = pre-flight; [countdown] = 3-2-1 on engine timers; [flying] =
/// physics live, taps flap; [dying] = crash animation on an engine timer;
/// [over] = final score settled. Input is only legal in [flying] (flap),
/// [idle]/[over] (start/restart).
enum FlapPhase { idle, countdown, flying, dying, over }

/// Play modes.
enum FlapMode { classic, attack }

/// Difficulty tiers: Breeze (free), Gust (free), Storm (pro).
class DifficultySpec {
  final String name;
  final String blurb;
  final double baseSpeed; // fraction of width per second
  final double maxSpeed;
  final double gapH; // fraction of height
  final double wobble; // gate sway amplitude (fraction of height), Storm only

  const DifficultySpec({
    required this.name,
    required this.blurb,
    required this.baseSpeed,
    required this.maxSpeed,
    required this.gapH,
    required this.wobble,
  });
}

const difficultySpecs = [
  DifficultySpec(
    name: 'Breeze',
    blurb: 'Gentle wind, wide gates — learn to fly.',
    baseSpeed: 0.24,
    maxSpeed: 0.32,
    gapH: 0.27,
    wobble: 0.0,
  ),
  DifficultySpec(
    name: 'Gust',
    blurb: 'Faster gates, tighter gaps.',
    baseSpeed: 0.28,
    maxSpeed: 0.40,
    gapH: 0.23,
    wobble: 0.0,
  ),
  DifficultySpec(
    name: 'Storm',
    blurb: 'PRO — wild wind, swaying gates, pure chaos.',
    baseSpeed: 0.32,
    maxSpeed: 0.50,
    gapH: 0.20,
    wobble: 0.055,
  ),
];

/// A gate (pair of pipes). [gapY] is the rest center (fraction of height);
/// the rendered center sways when [wobble] > 0.
class Gate {
  double x; // fraction of width
  double gapY;
  final double wobblePhase;
  bool scored = false;
  Gate(this.x, this.gapY, this.wobblePhase);
}

/// Floating "+1" feedback pops the engine spawns on every score.
class ScorePop {
  final double x; // fraction of width
  final double y; // fraction of height
  final DateTime at = DateTime.now();
  ScorePop(this.x, this.y);

  double get ageMs => DateTime.now().difference(at).inMilliseconds.toDouble();
}

/// Events the UI turns into sound / juice. The engine emits them; it never
/// plays audio itself.
enum FlapEvent {
  flap,
  score,
  medal,
  crash,
  gameOver,
  countdownTick,
  gameStart,
  attackTimeUp,
  attackHurry,
  invalid,
}

class FlapEngine extends ChangeNotifier {
  final int difficulty; // 0/1/2
  final FlapMode mode;

  DifficultySpec get spec => difficultySpecs[difficulty.clamp(0, 2)];

  FlapPhase phase = FlapPhase.idle;
  int score = 0;
  double birdY = 0.45; // fraction of height
  double vy = 0; // fraction per second
  final List<Gate> gates = [];
  final List<ScorePop> pops = [];
  double speed = 0.28;
  int countdown = 3;
  double timeLeft = 60.0; // attack mode
  double flightTime = 0; // seconds of flight this run
  double wingT = 0;
  double wobbleTime = 0;
  double shakeT = 99; // seconds since crash (UI shakes while small)
  String banner = '';
  String? deathReason;
  String? medal; // latest medal name earned this run
  bool paused = false;

  /// UI hook for sounds / juice. Set by the screen.
  void Function(FlapEvent event)? onEvent;

  final _rand = Random();
  Timer? _timer; // single phase-transition timer
  Timer? _watchdog; // stuck-state recovery
  bool _disposed = false;
  bool _hurryFired = false;
  final Set<int> _medalsGiven = {};

  static const double birdX = 0.32;
  static const double birdR = 0.035;
  static const double gateW = 0.09;
  static const double flapImpulse = -0.95;
  static const double gravity = 2.9;

  FlapEngine({required this.difficulty, required this.mode}) {
    banner = mode == FlapMode.attack
        ? '60 seconds — grab every gate!'
        : 'Tap to flap. Thread the gates.';
    _watchdog = Timer.periodic(const Duration(seconds: 2), (_) => _recover());
  }

  bool get flying => phase == FlapPhase.flying;
  bool get idle => phase == FlapPhase.idle;
  bool get isOver => phase == FlapPhase.over;

  @override
  void dispose() {
    _disposed = true;
    _timer?.cancel();
    _watchdog?.cancel();
    super.dispose();
  }

  void _arm(Duration d, void Function() fn) {
    if (_disposed || paused) return;
    _timer?.cancel();
    _timer = Timer(d, () {
      _timer = null;
      if (!_disposed && !paused) fn();
    });
  }

  /// Pause: freeze the phase timer and physics. Resume re-arms the phase.
  void setPaused(bool v) {
    if (paused == v || _disposed) return;
    paused = v;
    if (v) {
      _timer?.cancel();
      _timer = null;
    } else {
      _recover();
    }
    notifyListeners();
  }

  /// Watchdog: recover any phase found without a live timer.
  /// Stuck states impossible by construction. Respects [paused].
  void _recover() {
    if (_disposed || paused || _timer != null) return;
    switch (phase) {
      case FlapPhase.countdown:
        // Re-arm the beat (never skip one) — RULES.md 12: pause during
        // countdown freezes the beat; resume re-arms it (no skip).
        _arm(const Duration(milliseconds: 700), _advanceCountdown);
      case FlapPhase.dying:
        _finish(); // crash anim interrupted: settle the score
      case FlapPhase.idle:
      case FlapPhase.flying:
      case FlapPhase.over:
        break; // flying is tick-driven (UI), over/idle need nothing
    }
  }

  // ------------------------------------------------------------- flow
  /// Start a run from idle/over. Engine-owned reset, no stale state.
  void begin() {
    if (phase != FlapPhase.idle && phase != FlapPhase.over) return;
    _timer?.cancel();
    score = 0;
    birdY = 0.45;
    vy = 0;
    gates
      ..clear()
      ..addAll([Gate(1.25, _randGap(), _randPhase()), Gate(1.9, _randGap(), _randPhase())]);
    pops.clear();
    speed = spec.baseSpeed;
    flightTime = 0;
    wingT = 0;
    wobbleTime = 0;
    shakeT = 99;
    deathReason = null;
    medal = null;
    _medalsGiven.clear();
    _hurryFired = false;
    timeLeft = 60.0;
    phase = FlapPhase.countdown;
    countdown = 3;
    banner = 'Get ready…';
    onEvent?.call(FlapEvent.countdownTick);
    notifyListeners();
    _arm(const Duration(milliseconds: 700), _advanceCountdown);
  }

  void _advanceCountdown() {
    if (phase != FlapPhase.countdown || _disposed) return;
    countdown--;
    if (countdown <= 0) {
      phase = FlapPhase.flying;
      banner = mode == FlapMode.attack ? 'Go! 60 seconds!' : 'Fly!';
      onEvent?.call(FlapEvent.gameStart);
      notifyListeners();
    } else {
      banner = '$countdown…';
      onEvent?.call(FlapEvent.countdownTick);
      notifyListeners();
      _arm(const Duration(milliseconds: 700), _advanceCountdown);
    }
  }

  /// The one legal in-flight input. Silently ignored outside [flying]
  /// (an invalid tap still gets an audible blip via [FlapEvent.invalid]
  /// only when the UI chooses to send it — engine never double-fires).
  void flap() {
    if (phase != FlapPhase.flying || paused) {
      onEvent?.call(FlapEvent.invalid);
      return;
    }
    vy = flapImpulse;
    wingT = 0; // restart the wingbeat for visible feedback
    onEvent?.call(FlapEvent.flap);
    notifyListeners();
  }

  double _randGap() => 0.3 + _rand.nextDouble() * 0.4;
  double _randPhase() => _rand.nextDouble() * pi * 2;

  /// Effective (swaying) gap center for [g].
  double gapCenter(Gate g) =>
      g.gapY + sin(wobbleTime * 2.2 + g.wobblePhase) * spec.wobble;

  /// Physics tick, driven by the UI's ticker (60fps). The engine owns every
  /// state transition inside it; the UI never transitions on its own.
  void tick(double dt) {
    if (phase != FlapPhase.flying || paused || _disposed) return;
    dt = dt.clamp(0.0, 0.05);
    flightTime += dt;
    wobbleTime += dt;
    wingT += dt * 10;
    vy += gravity * dt;
    birdY += vy * dt;

    if (mode == FlapMode.attack) {
      timeLeft -= dt;
      if (!_hurryFired && timeLeft <= 10) {
        _hurryFired = true;
        banner = '10 seconds left!';
        onEvent?.call(FlapEvent.attackHurry);
      }
      if (timeLeft <= 0) {
        timeLeft = 0;
        phase = FlapPhase.over;
        deathReason = null;
        banner = 'Time! Score: $score';
        onEvent?.call(FlapEvent.attackTimeUp);
        notifyListeners();
        return;
      }
    }

    // Out of sky = crash.
    if (birdY < 0.02) {
      _crash('To the moon! 🌙');
      return;
    }
    if (birdY > 0.97) {
      _crash('Face-plant! 💥');
      return;
    }

    for (final g in gates) {
      g.x -= speed * dt / 1.0;
    }
    gates.removeWhere((g) => g.x < -0.25);
    while (gates.isEmpty || gates.last.x < 1.0) {
      final prevX = gates.isEmpty ? 0.85 : gates.last.x;
      gates.add(Gate(prevX + 0.65, _randGap(), _randPhase()));
    }

    final gapH = spec.gapH;
    for (final g in gates) {
      // Scoring: bird fully passed the gate. Visible, never silent.
      if (!g.scored && g.x + gateW < birdX) {
        g.scored = true;
        score++;
        pops.add(ScorePop(birdX + 0.1, birdY - 0.12));
        speed = (spec.baseSpeed + score * 0.004).clamp(
            spec.baseSpeed, spec.maxSpeed);
        _checkMedals();
        banner = score % 5 == 0 ? '$score gates! Keep going!' : banner;
        onEvent?.call(FlapEvent.score);
      }
      // Collision with the swaying gate.
      if ((birdX + birdR > g.x) && (birdX - birdR < g.x + gateW)) {
        final gc = gapCenter(g);
        final gapTop = gc - gapH / 2;
        final gapBot = gc + gapH / 2;
        if (birdY - birdR < gapTop || birdY + birdR > gapBot) {
          _crash('Gate crash! 💥');
          return;
        }
      }
    }
    // Age out floating score pops.
    pops.removeWhere((p) => p.ageMs > 900);
    notifyListeners();
  }

  static const _medalDefs = [
    (10, 'Bronze 🥉'),
    (20, 'Silver 🥈'),
    (30, 'Gold 🥇'),
    (40, 'Platinum 💠'),
  ];

  void _checkMedals() {
    for (final (at, name) in _medalDefs) {
      if (score >= at && !_medalsGiven.contains(at)) {
        _medalsGiven.add(at);
        medal = name;
        banner = '$name medal!';
        onEvent?.call(FlapEvent.medal);
      }
    }
  }

  String medalFor(int s) {
    String m = '';
    for (final (at, name) in _medalDefs) {
      if (s >= at) m = name;
    }
    return m.isEmpty ? 'no medal yet — keep flapping!' : m;
  }

  void _crash(String reason) {
    if (phase != FlapPhase.flying) return;
    phase = FlapPhase.dying;
    deathReason = reason;
    shakeT = 0;
    vy = -0.4; // little pop before the fall
    banner = reason;
    onEvent?.call(FlapEvent.crash);
    notifyListeners();
    // Engine-owned settle: the run ALWAYS ends ~1s after a crash.
    _arm(const Duration(milliseconds: 1000), _finish);
  }

  /// Dying-frame physics so the bird tumbles visibly during the crash beat.
  void dyingTick(double dt) {
    if (phase != FlapPhase.dying || paused || _disposed) return;
    dt = dt.clamp(0.0, 0.05);
    shakeT += dt;
    vy += gravity * dt;
    birdY = (birdY + vy * dt).clamp(0.02, 1.02);
    wingT += dt * 4;
    notifyListeners();
  }

  void _finish() {
    if (phase != FlapPhase.over) {
      phase = FlapPhase.over;
      banner = '${deathReason ?? 'Finished!'} Score: $score';
      onEvent?.call(FlapEvent.gameOver);
      notifyListeners();
    }
  }

  /// Full restart — identical to [begin] from any non-flying phase.
  void restart() => begin();
}
