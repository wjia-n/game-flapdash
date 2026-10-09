import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/meadow.dart';
import '../theme/sky_themes.dart';
import 'menu_screen.dart';

/// Launch splash (single flow, two moments):
/// 1. Company moment — the official WAJIHA logo, nothing else.
/// 2. Game splash — game logo + name, animated loading line, Credits: WAJIHA.
class SplashScreen extends StatefulWidget {
  final FlapAudio audio;
  final FlapSettings settings;
  const SplashScreen({super.key, required this.audio, required this.settings});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _loader;
  bool _companyDone = false;

  @override
  void initState() {
    super.initState();
    _loader = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );
    _run();
  }

  Future<void> _run() async {
    // Pre-warm audio off the critical path while the company moment shows.
    widget.audio.prewarm();
    await Future.delayed(const Duration(milliseconds: 1300));
    if (!mounted) return;
    setState(() => _companyDone = true);
    widget.audio.startMenuMusic();
    _loader.forward();
    await Future.delayed(const Duration(milliseconds: 1900));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MenuScreen(
          audio: widget.audio,
          settings: widget.settings,
        ),
      ),
    );
  }

  @override
  void dispose() {
    _loader.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_companyDone) return const _CompanyMoment();
    final theme = SkyThemes.byId(
      widget.settings.themeId,
      custom: widget.settings.customTheme,
    );
    return Scaffold(
      body: SkyBackdrop(
        theme: theme,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(40),
                  border: Border.all(
                      color: Colors.white.withValues(alpha: 0.9), width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 10),
                      blurRadius: 24,
                    ),
                  ],
                ),
                clipBehavior: Clip.antiAlias,
                child:
                    Image.asset('assets/flapdash_logo.png', fit: BoxFit.cover),
              ),
              const SizedBox(height: 20),
              Text('FLAP DASH', style: Meadow.display(48, theme: theme)),
              const SizedBox(height: 4),
              Text(
                'ONE TAP AT A TIME',
                style: Meadow.label(13, theme: theme),
              ),
              const SizedBox(height: 28),
              // Animated loading line.
              SizedBox(
                width: 220,
                child: AnimatedBuilder(
                  animation: _loader,
                  builder: (_, _) => Column(
                    children: [
                      Container(
                        height: 8,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(4),
                          color: Colors.black.withValues(alpha: 0.18),
                          border: Border.all(
                              color:
                                  Colors.white.withValues(alpha: 0.7)),
                        ),
                        child: FractionallySizedBox(
                          alignment: Alignment.centerLeft,
                          widthFactor: _loader.value.clamp(0.02, 1.0),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(4),
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFFFE08A),
                                  Color(0xFFFFB800),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        _loader.value < 1
                            ? 'Warming up the wings…'
                            : 'Ready to fly!',
                        style: Meadow.body(13, theme: theme),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 44),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    'assets/wajiha_logo.png',
                    width: 30,
                    height: 30,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Credits: WAJIHA',
                    style: Meadow.label(14, theme: theme),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Moment 1: the official company logo on deep navy — untouched artwork.
class _CompanyMoment extends StatelessWidget {
  const _CompanyMoment();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0B1026),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0.85, end: 1.0),
              duration: const Duration(milliseconds: 1100),
              curve: Curves.easeOut,
              builder: (_, scale, child) =>
                  Transform.scale(scale: scale, child: child),
              child: Image.asset(
                'assets/wajiha_logo.png',
                width: 150,
                height: 150,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'WAJIHA',
              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.w900,
                letterSpacing: 6,
                color: Color(0xFF8FB8FF),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
