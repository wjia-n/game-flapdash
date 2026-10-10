import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:share_plus/share_plus.dart';
import '../engine/flap_engine.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/meadow.dart';
import '../theme/sky_themes.dart';
import 'custom_theme_screen.dart';
import 'game_screen.dart';
import 'pro_screen.dart';
import 'settings_screen.dart';

/// Main menu — Sunlit Meadow edition.
/// Logo, PLAY, mode + difficulty setup, style picker, pilot name, tip jar,
/// settings, share/rate/how-to.
class MenuScreen extends StatefulWidget {
  final FlapAudio audio;
  final FlapSettings settings;

  const MenuScreen({super.key, required this.audio, required this.settings});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

class _MenuScreenState extends State<MenuScreen> {
  final StoreService _store = StoreService();

  FlapSettings get _s => widget.settings;
  SkyThemeDef get _t =>
      SkyThemes.byId(_s.themeId, custom: _s.customTheme);

  static const storeUrl =
      'https://play.google.com/store/apps/details?id=com.gameswajiha.flapdash';

  @override
  void initState() {
    super.initState();
    widget.audio.startMenuMusic();
    _store.init().then((_) {
      if (mounted) setState(() {});
    });
    _store.lastThanks.addListener(_onThanks);
  }

  void _onThanks() {
    final msg = _store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Meadow.body(15, theme: _t)),
        backgroundColor: const Color(0xFF2E3A4A),
        behavior: SnackBarBehavior.floating,
      ),
    );
    _store.lastThanks.value = null;
  }

  
  @override
  void dispose() {
    _store.lastThanks.removeListener(_onThanks);
    _store.dispose();
    super.dispose();
  }

  /// Real in-app review flow: the Play in-app review sheet when available,
  /// otherwise the store listing. Graceful when not from Play.
  Future<void> _requestReview() async {
    final review = InAppReview.instance;
    try {
      if (await review.isAvailable()) {
        await review.requestReview();
      } else {
        await review.openStoreListing(appStoreId: null);
      }
    } catch (_) {
      // Review UI unavailable on this device/build: stay silent, no fake UI.
    }
  }

  void _play() {
    widget.audio.gameStart();
    final engine = FlapEngine(
      difficulty: _s.difficulty,
      mode: FlapMode.values[_s.mode],
    );
    // App-scoped music: game screen switches to the game track on entry;
    // we switch back to menu music on return.
    Navigator.of(context)
        .push(MaterialPageRoute(
      builder: (_) => GameScreen(
        engine: engine,
        audio: widget.audio,
        settings: _s,
      ),
    ))
        .then((_) {
      if (mounted) widget.audio.startMenuMusic();
    });
  }

  void _goPro() {
    widget.audio.click();
    Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => ProScreen(
        audio: widget.audio,
        settings: _s,
        store: _store,
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return SkyBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ListenableBuilder(
            listenable: _s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                children: [
                  const SizedBox(height: 8),
                  // Logo plaque.
                  Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.9),
                          width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.35),
                          offset: const Offset(0, 8),
                          blurRadius: 18,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.asset('assets/flapdash_logo.png',
                        fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 12),
                  Text('FLAP DASH', style: Meadow.display(44, theme: t)),
                  Text(
                    'ONE TAP AT A TIME',
                    style: Meadow.label(12, theme: t),
                  ),
                  const SizedBox(height: 20),
                  PuffyButton(
                    label: '▶  Take Flight',
                    onTap: _play,
                    theme: t,
                    width: 260,
                    color: const Color(0xFF6BAE3F),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onTap: _goPro,
                    child: Container(
                      width: 260,
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFFFE08A), Color(0xFFFFB800)],
                        ),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.9),
                            width: 3),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.35),
                            offset: const Offset(0, 5),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '☕  Tip Jar',
                        style: Meadow.label(17,
                            theme: t, color: const Color(0xFF5E421E)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),
                  _ModeCard(theme: t),
                  const SizedBox(height: 14),
                  _StyleCard(theme: t),
                  const SizedBox(height: 14),
                  _PilotCard(theme: t),
                  const SizedBox(height: 14),
                  _SupportCard(theme: t, store: _store),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MenuIcon(
                        theme: t,
                        icon: Icons.share,
                        label: 'Share',
                        onTap: () async {
                          widget.audio.click();
                          await Share.share(
                              'I\'m flying high in Flap Dash! Can you beat me? $storeUrl');
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.star_rate,
                        label: 'Rate',
                        onTap: () async {
                          widget.audio.click();
                          await _requestReview();
                        },
                      ),
                      const SizedBox(width: 22),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.settings,
                        label: 'Settings',
                        onTap: () async {
                          widget.audio.click();
                          await Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) => SettingsScreen(
                              audio: widget.audio,
                              settings: _s,
                            ),
                          ));
                          if (mounted) setState(() {});
                        },
                      ),
                      const SizedBox(width: 26),
                      _MenuIcon(
                        theme: t,
                        icon: Icons.help_outline,
                        label: 'How to Play',
                        onTap: () {
                          widget.audio.click();
                          _showHowTo(context, t);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  if (_s.gamesPlayed > 0)
                    Text(
                      'Best: ${_s.bestClassic}   •   Flights: ${_s.gamesPlayed}   •   Flaps: ${_s.totalFlaps}',
                      style: Meadow.label(12, theme: t),
                    ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset('assets/wajiha_logo.png',
                          width: 22, height: 22, fit: BoxFit.contain),
                      const SizedBox(width: 8),
                      Text('Credits: WAJIHA',
                          style: Meadow.label(12, theme: t)),
                    ],
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showHowTo(BuildContext context, SkyThemeDef t) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            color: (t.night ? const Color(0xFF141B3D) : Colors.white)
                .withValues(alpha: 0.95),
            border: Border.all(
                color: Colors.white.withValues(alpha: 0.8), width: 3),
          ),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('How to Play', style: Meadow.display(24, theme: t)),
                const SizedBox(height: 12),
                for (final line in [
                  '• TAP anywhere to flap your wings. Gravity is rude.',
                  '• Thread the crystal gates — don\'t bonk them!',
                  '• Each gate = 1 point. Speed creeps up as you score.',
                  '• Medals at 10 🥉  20 🥈  30 🥇  40 💠.',
                  '• Classic: fly as far as you can. Score Attack: 60 seconds!',
                  '• Breeze is gentle, Gust is spicy, Storm (PRO) sways the gates.',
                  '• Bonk a gate or leave the sky and the flight ends.',
                ])
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Text(line, style: Meadow.body(14, theme: t)),
                  ),
                const SizedBox(height: 16),
                Center(
                  child: PuffyButton(
                    label: 'Got it!',
                    width: 180,
                    fontSize: 16,
                    theme: t,
                    onTap: () {
                      widget.audio.click();
                      Navigator.of(context).pop();
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
class _MenuIcon extends StatelessWidget {
  final SkyThemeDef theme;
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _MenuIcon(
      {required this.theme,
      required this.icon,
      required this.label,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            width: 62,
            height: 62,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF8FD18A), Color(0xFF6BAE3F)],
              ),
              border:
                  Border.all(color: Colors.white.withValues(alpha: 0.9), width: 3),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.35),
                  offset: const Offset(0, 4),
                  blurRadius: 8,
                ),
              ],
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 6),
          Text(label, style: Meadow.label(12, theme: theme)),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Mode setup: game mode + difficulty tier + pilot name.
class _ModeCard extends StatelessWidget {
  final SkyThemeDef theme;
  const _ModeCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    return CloudCard(
      theme: theme,
      title: 'Flight Setup',
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PickChip(
                theme: theme,
                label: '🕊 Classic',
                selected: s.mode == 0,
                onTap: () {
                  audio.click();
                  s.setMode(0);
                },
              ),
              PickChip(
                theme: theme,
                label: '⏱ Score Attack',
                selected: s.mode == 1,
                onTap: () {
                  audio.click();
                  s.setMode(1);
                },
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            s.mode == 0
                ? 'Endless flight — medals at 10 / 20 / 30 / 40.'
                : '60 seconds on the clock. Every gate counts!',
            style: Meadow.body(12, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Wrap(
            alignment: WrapAlignment.center,
            children: [
              for (int d = 0; d < 3; d++)
                PickChip(
                  theme: theme,
                  label:
                      '${d == 2 && !s.isPro ? '🔒 ' : ''}${difficultySpecs[d].name}',
                  selected: s.difficulty == d,
                  onTap: () {
                    audio.click();
                    if (d == 2 && !s.isPro) {
                      screen._goPro();
                      return;
                    }
                    s.setDifficulty(d);
                  },
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            difficultySpecs[s.difficulty].blurb,
            style: Meadow.body(12, theme: theme),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Style picker: 12 skies + custom, 8 birds + custom, 8 pipes + custom.
class _StyleCard extends StatelessWidget {
  final SkyThemeDef theme;
  const _StyleCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    final audio = screen.widget.audio;
    final isPro = s.isPro;
    return CloudCard(
      theme: theme,
      title: 'Style Studio',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sky:', style: Meadow.label(14, theme: theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.center,
            children: [
              for (final th in SkyThemes.all)
                _SkyTile(
                  theme: theme,
                  th: th,
                  selected: s.themeId == th.id,
                  locked: SkyThemes.isProTheme(th.id) && !isPro,
                  onTap: () {
                    audio.click();
                    if (SkyThemes.isProTheme(th.id) && !isPro) {
                      screen._goPro();
                      return;
                    }
                    s.setTheme(th.id);
                  },
                ),
              _SkyTile(
                theme: theme,
                th: s.customTheme,
                selected: s.themeId == 'custom',
                locked: !isPro,
                custom: true,
                onTap: () {
                  audio.click();
                  if (!isPro) {
                    screen._goPro();
                    return;
                  }
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => CustomThemeScreen(
                      audio: audio,
                      settings: s,
                    ),
                  ));
                },
              ),
            ],
          ),
          if (!isPro)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                '🔒 ${SkyThemes.all.length - SkyThemes.freeThemeIds.length} more skies in PRO',
                style: Meadow.label(12, theme: theme),
              ),
            ),
          const SizedBox(height: 14),
          Text('Bird:', style: Meadow.label(14, theme: theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < BirdStyles.all.length; i++)
                PickChip(
                  theme: theme,
                  label:
                      '${BirdStyles.isPro(i) && !isPro ? '🔒 ' : ''}${BirdStyles.all[i].name}',
                  dot: BirdStyles.all[i].body,
                  selected: s.birdStyle == i,
                  onTap: () {
                    audio.click();
                    if (BirdStyles.isPro(i) && !isPro) {
                      screen._goPro();
                      return;
                    }
                    s.setBirdStyle(i);
                  },
                ),
              PickChip(
                theme: theme,
                label: '${!isPro ? '🔒 ' : ''}🎨 My Bird',
                selected: s.birdStyle == BirdStyles.all.length,
                onTap: () {
                  audio.click();
                  if (!isPro) {
                    screen._goPro();
                    return;
                  }
                  s.setBirdStyle(BirdStyles.all.length);
                },
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Gates:', style: Meadow.label(14, theme: theme)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: [
              for (int i = 0; i < PipeStyles.all.length; i++)
                PickChip(
                  theme: theme,
                  label:
                      '${PipeStyles.isPro(i) && !isPro ? '🔒 ' : ''}${PipeStyles.all[i].name}',
                  dot: PipeStyles.all[i].main,
                  selected: s.pipeStyle == i,
                  onTap: () {
                    audio.click();
                    if (PipeStyles.isPro(i) && !isPro) {
                      screen._goPro();
                      return;
                    }
                    s.setPipeStyle(i);
                  },
                ),
              PickChip(
                theme: theme,
                label: '${!isPro ? '🔒 ' : ''}🎨 My Gates',
                selected: s.pipeStyle == PipeStyles.all.length,
                onTap: () {
                  audio.click();
                  if (!isPro) {
                    screen._goPro();
                    return;
                  }
                  s.setPipeStyle(PipeStyles.all.length);
                },
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Custom styles live in the 🎨 Style Creator (PRO).',
              style: Meadow.body(12, theme: theme),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

class _SkyTile extends StatelessWidget {
  final SkyThemeDef theme;
  final SkyThemeDef th;
  final bool selected;
  final bool locked;
  final bool custom;
  final VoidCallback onTap;
  const _SkyTile({
    required this.theme,
    required this.th,
    required this.selected,
    required this.locked,
    required this.onTap,
    this.custom = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Container(
            width: 96,
            padding:
                const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [th.skyTop, th.skyBot],
              ),
              border: Border.all(
                color: selected
                    ? const Color(0xFFFFB800)
                    : Colors.white.withValues(alpha: 0.5),
                width: selected ? 3 : 1.5,
              ),
            ),
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: th.celestial,
                    border:
                        Border.all(color: Colors.white, width: 1.5),
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  custom ? '🎨 My Sky' : th.name,
                  style: Meadow.label(10,
                      theme: theme,
                      color: th.night
                          ? Colors.white
                          : const Color(0xFF2E3A4A)),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (locked)
            Container(
              width: 96,
              height: 64,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withValues(alpha: 0.55),
              ),
              child:
                  const Icon(Icons.lock, color: Colors.white, size: 22),
            ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Renameable pilot profile.
class _PilotCard extends StatelessWidget {
  final SkyThemeDef theme;
  const _PilotCard({required this.theme});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final s = screen._s;
    return CloudCard(
      theme: theme,
      title: 'Pilot',
      child: Column(
        children: [
          _NameField(
            theme: theme,
            initial: s.pilotName,
            onChanged: (v) => s.updatePilotNameLive(v),
            onDone: (v) => s.setPilotName(v),
          ),
          const SizedBox(height: 8),
          Text(
            'Your name flies on the scoreboard and game-over card.',
            style: Meadow.body(12, theme: theme),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _NameField extends StatefulWidget {
  final SkyThemeDef theme;
  final String initial;
  final ValueChanged<String> onChanged;
  final ValueChanged<String> onDone;
  const _NameField({
    required this.theme,
    required this.initial,
    required this.onChanged,
    required this.onDone,
  });

  @override
  State<_NameField> createState() => _NameFieldState();
}

class _NameFieldState extends State<_NameField> {
  late final TextEditingController _c;
  late final FocusNode _focus;

  @override
  void initState() {
    super.initState();
    _c = TextEditingController(text: widget.initial);
    // Commit (trim + normalize) whenever the field loses focus — the
    // "names only on keyboard-done" bug is how profiles used to get lost.
    _focus = FocusNode()..addListener(_onFocus);
  }

  void _onFocus() {
    if (!_focus.hasFocus) widget.onDone(_c.text);
  }

  @override
  void didUpdateWidget(covariant _NameField old) {
    super.didUpdateWidget(old);
    // Only mirror external changes; never fight the user's typing.
    if (old.initial != widget.initial && _c.text != widget.initial) {
      _c.text = widget.initial;
    }
  }

  @override
  void dispose() {
    _focus.removeListener(_onFocus);
    _focus.dispose();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.black.withValues(alpha: 0.08),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.7), width: 1.5),
      ),
      child: TextField(
        controller: _c,
        focusNode: _focus,
        style: Meadow.body(16, theme: widget.theme),
        maxLength: 14,
        decoration: InputDecoration(
          counterText: '',
          border: InputBorder.none,
          hintText: 'Pilot name',
          hintStyle: Meadow.body(14,
              theme: widget.theme,
              color: (widget.theme.night ? Colors.white : Colors.black)
                  .withValues(alpha: 0.4)),
        ),
        onSubmitted: widget.onDone,
        onEditingComplete: () => widget.onDone(_c.text),
        onChanged: widget.onChanged,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Tip jar (IAP).
class _SupportCard extends StatelessWidget {
  final SkyThemeDef theme;
  final StoreService store;
  const _SupportCard({required this.theme, required this.store});

  @override
  Widget build(BuildContext context) {
    final screen = context.findAncestorStateOfType<_MenuScreenState>()!;
    final audio = screen.widget.audio;
    return CloudCard(
      theme: theme,
      title: 'Support Wajiha',
      child: Column(
        children: [
          Text(
            'Flap Dash is 100% free. If it made you smile, a small tip keeps new games coming!',
            style: Meadow.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Builder(builder: (_) {
            final tips = [
              store.coffeeProduct,
              store.chocolateProduct,
            ].whereType<ProductDetails>().toList();
            if (!store.storeReady) {
              return Text(
                store.error ?? 'Loading…',
                style: Meadow.body(13, theme: theme),
                textAlign: TextAlign.center,
              );
            }
            if (tips.isEmpty) {
              return Text('Tips coming soon.',
                  style: Meadow.body(13, theme: theme));
            }
            return Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  PickChip(
                    theme: theme,
                    label: p.id == StoreService.chocolateId
                        ? '🍫 ${p.price}'
                        : '☕ ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}
