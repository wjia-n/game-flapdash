import 'package:flutter_test/flutter_test.dart';
import 'package:flapdash/engine/flap_engine.dart';

/// Engine state-machine tests: phases transition on engine timers only,
/// scoring is deterministic, and no phase can get stuck.
void main() {
  group('FlapEngine state machine', () {
    test('begin() starts a countdown that reaches flying', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      expect(e.phase, FlapPhase.idle);
      e.begin();
      expect(e.phase, FlapPhase.countdown);
      expect(e.countdown, 3);
      // 3 beats of 700ms.
      await Future.delayed(const Duration(milliseconds: 2300));
      expect(e.phase, FlapPhase.flying);
      e.dispose();
    });

    test('flap only works while flying', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      e.flap(); // idle: invalid, no crash, no state change
      expect(e.phase, FlapPhase.idle);
      e.begin();
      e.flap(); // countdown: still no flap
      expect(e.phase, FlapPhase.countdown);
      e.dispose();
    });

    test('physics tick scores and never double-crashes', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      e.begin();
      await Future.delayed(const Duration(milliseconds: 2300));
      expect(e.phase, FlapPhase.flying);
      // Keep the bird alive by flapping on a simple schedule: flap whenever
      // falling. Run ~8 simulated seconds.
      for (int i = 0; i < 480; i++) {
        if (e.vy > 0.35) e.flap();
        e.tick(1 / 60);
        if (e.phase != FlapPhase.flying) break;
      }
      // Either still flying (scoring) or dying/over (crashed once).
      expect(
          [FlapPhase.flying, FlapPhase.dying, FlapPhase.over],
          contains(e.phase));
      final crashed = e.phase != FlapPhase.flying;
      if (crashed) {
        // Dying always settles to over ~1s later — never stuck in dying.
        await Future.delayed(const Duration(milliseconds: 1300));
        expect(e.phase, FlapPhase.over);
      } else {
        expect(e.score, greaterThan(0)); // survived: must have scored
      }
      e.dispose();
    });

    test('ceiling crash ends the run and settles to over', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      e.begin();
      await Future.delayed(const Duration(milliseconds: 2300));
      e.vy = -5; // rocket to the moon
      e.tick(1 / 60);
      expect(e.phase, FlapPhase.dying);
      expect(e.deathReason, contains('moon'));
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(e.phase, FlapPhase.over);
      e.dispose();
    });

    test('attack mode ends at time-up even without crashing', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.attack);
      e.begin();
      await Future.delayed(const Duration(milliseconds: 2300));
      e.timeLeft = 0.05;
      e.tick(1 / 60);
      expect(e.phase, FlapPhase.over);
      expect(e.deathReason, isNull);
      e.dispose();
    });

    test('restart works from over', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      e.begin();
      await Future.delayed(const Duration(milliseconds: 2300));
      e.vy = 5; // face-plant
      for (int i = 0; i < 10 && e.phase == FlapPhase.flying; i++) {
        e.tick(1 / 60);
      }
      expect(e.phase, FlapPhase.dying);
      await Future.delayed(const Duration(milliseconds: 1300));
      expect(e.phase, FlapPhase.over);
      e.restart();
      expect(e.phase, FlapPhase.countdown);
      expect(e.score, 0);
      e.dispose();
    });

    test('medals fire at 10/20/30/40', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      expect(e.medalFor(9), contains('no medal'));
      expect(e.medalFor(10), contains('Bronze'));
      expect(e.medalFor(25), contains('Silver'));
      expect(e.medalFor(33), contains('Gold'));
      expect(e.medalFor(50), contains('Platinum'));
      e.dispose();
    });

    test('pause freezes phase transitions', () async {
      final e = FlapEngine(difficulty: 0, mode: FlapMode.classic);
      e.begin();
      e.setPaused(true);
      await Future.delayed(const Duration(milliseconds: 1600));
      expect(e.phase, FlapPhase.countdown); // frozen, not stuck
      e.setPaused(false); // watchdog re-arms the beat (no skip)
      await Future.delayed(const Duration(milliseconds: 2800));
      expect(e.phase, FlapPhase.flying);
      e.dispose();
    });
  });
}
