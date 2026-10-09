# Flap Dash — RULES.md
_The authoritative source of truth for Flap Dash gameplay. If the
implementation ever diverges from this document, fix the implementation._

## 1. Objective
Tap to flap a bird through an endless stream of gates. Every gate threaded
cleanly is 1 point. The run ends when the bird bonks a gate or leaves the
sky. In Score Attack mode, the run also ends when the 60-second clock hits
zero — the score stands.

## 2. Setup
- Portrait orientation, single player (the renameable Pilot).
- Difficulty chosen in Flight Setup: Breeze, Gust, or Storm (Pro).
- Mode chosen in Flight Setup: Classic (endless) or Score Attack (60s).
- Sky, bird style, and gate style chosen in the Style Studio; they never
  change gameplay values.
- Each run starts with a 3-2-1 countdown owned by the engine.

## 3. Turn order
There are no turns — Flap Dash is a real-time arcade game. The engine ticks
physics at frame rate once the countdown reaches "Fly!".

## 4. Legal moves
- Tap anywhere while flying: the bird gets an upward flap impulse.
- Tap on the pre-flight screen: starts the countdown.
- Tap Fly Again on the game-over panel: starts a new run.
- Pause: legal while flying or counting down; freezes physics and timers.

## 5. Illegal moves
- Tapping during the countdown does nothing (no flap, no skip).
- Tapping during the crash animation does nothing.
- Tapping on the game-over panel (except its buttons) does nothing.
- There is no way to score without threading a gate, and no way to move a
  gate out of the way.

## 6. Captures
Not applicable — there are no opponents or pieces to capture.

## 7. Special rules
- **Gravity:** constant downward acceleration; the bird always falls unless
  flapped.
- **Ceiling:** touching the top of the sky ("To the moon!") ends the run.
- **Floor:** touching the bottom ("Face-plant!") ends the run.
- **Storm sway:** on Storm difficulty, gate gaps sway up and down over time;
  collision uses the swaying center, not the rest center.
- **Speed creep:** gate speed increases with every gate scored, up to the
  difficulty's max speed.

## 8. Scoring
- Threading a gate (bird fully passes it without touching) = +1.
- Score is shown big in the HUD and pops as a floating "+1" at the bird.
- A medal is awarded the first time the run reaches 10 🥉, 20 🥈, 30 🥇,
  40 💠 — announced with a banner and fanfare, never silently.
- Best scores are kept per mode (Classic best, Attack best); a new best is
  celebrated on the game-over panel.

## 9. Winning conditions
Flap Dash has no final win — it is a score-attack arcade game. The "win"
moments are: beating your best, and earning medals.

## 10. Draw conditions
Not applicable.

## 11. AI strategy
Not applicable — there are no bots or opponents. Difficulty is expressed
through physics parameters:

| Tier   | Base speed | Max speed | Gap height | Gate sway | Access |
|--------|-----------|-----------|------------|-----------|--------|
| Breeze | 0.24      | 0.32      | 0.27       | none      | free   |
| Gust   | 0.28      | 0.40      | 0.23       | none      | free   |
| Storm  | 0.32      | 0.50      | 0.20       | ±0.055    | PRO    |

## 12. Edge cases
- Pause during countdown freezes the beat; resume re-arms it (no skip).
- App backgrounding mid-flight auto-pauses; the engine's watchdog re-arms
  any phase found without a live timer, so no state can get stuck.
- Score Attack clock expiry mid-crash: the run ends as a crash first; the
  clock cannot resurrect a dead bird.
- Gates spawn only ahead of the screen and despawn behind it; the bird can
  never outrun spawning or face an empty sky.
- The crash animation (~1s, bird tumbles) always settles to the game-over
  panel via an engine-owned timer.

## 13. Test cases
See `test/flap_engine_test.dart`:
- Countdown reaches flying on engine timers.
- Flap is ignored outside flying (no state change, no crash).
- Scoring accumulates; a crash settles to over within ~1s; never stuck in
  dying.
- Ceiling/floor contact ends the run with the correct reason.
- Attack mode ends at time-up even without a crash.
- Restart from over resets score and re-enters countdown.
- Medals fire at 10/20/30/40.
- Pause freezes phase transitions; resume re-arms them.
