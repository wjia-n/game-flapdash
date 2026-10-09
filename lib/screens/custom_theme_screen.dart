import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/meadow.dart';
import '../theme/sky_themes.dart';

/// Style Creator (PRO): design your own sky, bird and gates from a curated
/// palette. Changes preview live.
class CustomThemeScreen extends StatelessWidget {
  final FlapAudio audio;
  final FlapSettings settings;

  const CustomThemeScreen(
      {super.key, required this.audio, required this.settings});

  SkyThemeDef get _t =>
      SkyThemes.byId('custom', custom: settings.customTheme);
  BirdStyleDef get _bird => settings.customBird;
  PipeStyleDef get _pipe => settings.customPipe;

  static const _palette = [
    0xFFFFC93B, // sunbeam
    0xFFFF9F1C, // tangerine
    0xFFFF6B35, // ember
    0xFFD64545, // cardinal
    0xFFE8875A, // clay
    0xFFFFAEC9, // blossom
    0xFF38BDF8, // sky
    0xFF4AA8DE, // bluebird
    0xFF2E5A88, // deep sea
    0xFF3FB97F, // parrot
    0xFF2E7D4F, // vine
    0xFF6BAE3F, // leaf
    0xFF8B5A2B, // oak
    0xFFB08968, // sparrow
    0xFF8B6F47, // owl
    0xFF2E3440, // penguin
    0xFF6B7280, // slate
    0xFFB87333, // copper
    0xFFE8E2D4, // marble
    0xFFFFFFFF, // snow
  ];

  @override
  Widget build(BuildContext context) {
    final t = _t;
    return SkyBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Color(0xFF2E3A4A)),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('🎨 Style Creator',
              style: Meadow.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: settings,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                  // Live preview: bird through a gate on your sky.
                  Container(
                    height: 190,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(22),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [t.skyTop, t.skyBot],
                      ),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.85),
                          width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.25),
                          offset: const Offset(0, 6),
                          blurRadius: 14,
                        ),
                      ],
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: CustomPaint(
                      size: Size.infinite,
                      painter: _PreviewPainter(
                          bird: _bird, pipe: _pipe, theme: t),
                    ),
                  ),
                  const SizedBox(height: 16),
                  CloudCard(
                    theme: t,
                    title: 'My Sky',
                    child: Column(
                      children: [
                        _ColorRow(
                          label: 'Top of sky',
                          key_: 'skyTop',
                          settings: settings,
                          audio: audio,
                        ),
                        _ColorRow(
                          label: 'Bottom of sky',
                          key_: 'skyBot',
                          settings: settings,
                          audio: audio,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CloudCard(
                    theme: t,
                    title: 'My Bird',
                    child: Column(
                      children: [
                        _ColorRow(
                          label: 'Feathers',
                          key_: 'birdBody',
                          settings: settings,
                          audio: audio,
                        ),
                        _ColorRow(
                          label: 'Wings',
                          key_: 'birdWing',
                          settings: settings,
                          audio: audio,
                        ),
                        _ColorRow(
                          label: 'Beak',
                          key_: 'birdBeak',
                          settings: settings,
                          audio: audio,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  CloudCard(
                    theme: t,
                    title: 'My Gates',
                    child: _ColorRow(
                      label: 'Gate material',
                      key_: 'pipeMain',
                      settings: settings,
                      audio: audio,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () {
                      audio.click();
                      settings.resetCustomColors();
                    },
                    child: Text('Reset my creation',
                        style: Meadow.label(13, theme: t)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Your creation appears as "My Sky", "My Bird" and "My Gates" in the Style Studio.',
                    style: Meadow.body(12, theme: t),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ColorRow extends StatelessWidget {
  final String label;
  final String key_;
  final FlapSettings settings;
  final FlapAudio audio;
  const _ColorRow({
    required this.label,
    required this.key_,
    required this.settings,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final current = settings.customColors[key_];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: Meadow.label(14,
                  theme: SkyThemes.byId('meadow'))),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final argb in CustomThemeScreen._palette)
                GestureDetector(
                  onTap: () {
                    audio.click();
                    settings.setCustomColor(key_, argb | 0xFF000000);
                  },
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(argb | 0xFF000000),
                      border: Border.all(
                        color: current == (argb | 0xFF000000)
                            ? const Color(0xFFFFB800)
                            : Colors.white,
                        width: current == (argb | 0xFF000000) ? 4 : 2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          offset: const Offset(0, 2),
                          blurRadius: 4,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Live preview of the custom bird + gates on the custom sky.
class _PreviewPainter extends CustomPainter {
  final BirdStyleDef bird;
  final PipeStyleDef pipe;
  final SkyThemeDef theme;
  _PreviewPainter(
      {required this.bird, required this.pipe, required this.theme});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    // Gates.
    final gw = w * 0.16;
    final gx = w * 0.62;
    final gapTop = h * 0.32;
    final gapBot = h * 0.68;
    for (final r in [
      Rect.fromLTWH(gx, -10, gw, gapTop + 10),
      Rect.fromLTWH(gx, gapBot, gw, h - gapBot + 10),
    ]) {
      canvas.drawRRect(RRect.fromRectAndRadius(r, const Radius.circular(8)),
          Paint()..color = pipe.main);
      canvas.drawRRect(
          RRect.fromRectAndRadius(
              Rect.fromLTWH(r.left + 4, r.top + 6, 7, r.height - 12),
              const Radius.circular(3.5)),
          Paint()..color = pipe.light.withValues(alpha: 0.8));
    }
    // Bird.
    canvas.save();
    canvas.translate(w * 0.3, h * 0.5);
    canvas.drawOval(Rect.fromCenter(center: Offset.zero, width: 52, height: 40),
        Paint()..color = bird.body);
    canvas.drawOval(
        Rect.fromCenter(center: const Offset(-4, -8), width: 30, height: 16),
        Paint()..color = bird.wing);
    canvas.drawCircle(const Offset(12, -8), 8, Paint()..color = Colors.white);
    canvas.drawCircle(const Offset(14, -8), 3.6, Paint()..color = Colors.black);
    final beak = Path()
      ..moveTo(24, -2)
      ..lineTo(38, 3)
      ..lineTo(24, 8)
      ..close();
    canvas.drawPath(beak, Paint()..color = bird.beak);
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter old) => true;
}
