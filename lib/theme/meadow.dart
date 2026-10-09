import 'package:flutter/material.dart';
import 'sky_themes.dart';

/// "Sunlit Meadow" design system for Flap Dash.
/// Warm storybook UI: chunky physically-pressable buttons, soft cloud cards,
/// readable bold type. No neon, no cyberpunk, no generic Material look.
///
/// Everything takes the active [SkyThemeDef] so UI tints follow the sky.
class Meadow {
  static const shadow = Color(0xFF1A2A3A);

  static TextStyle display(double size, {Color? color, SkyThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: color ?? _ink(theme),
        letterSpacing: 0.6,
        shadows: const [
          Shadow(color: shadow, offset: Offset(0, 2), blurRadius: 4),
        ],
      );

  static TextStyle body(double size, {Color? color, SkyThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color ?? _inkSoft(theme),
        height: 1.35,
      );

  static TextStyle label(double size, {Color? color, SkyThemeDef? theme}) =>
      TextStyle(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color ?? _ink(theme),
        letterSpacing: 0.8,
      );

  static Color _ink(SkyThemeDef? theme) =>
      theme != null && theme.night ? Colors.white : const Color(0xFF2E3A4A);

  static Color _inkSoft(SkyThemeDef? theme) => theme != null && theme.night
      ? Colors.white.withValues(alpha: 0.85)
      : const Color(0xFF4A5A70);

  static ThemeData theme(SkyThemeDef t) {
    return ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: t.skyTop,
      colorScheme: ColorScheme(
        brightness: t.night ? Brightness.dark : Brightness.light,
        primary: t.celestial,
        onPrimary: t.skyTop,
        secondary: t.cloud,
        onSecondary: t.skyTop,
        surface: t.skyBot,
        onSurface: _ink(t),
        error: const Color(0xFFD64545),
        onError: Colors.white,
      ),
      dialogTheme: DialogThemeData(backgroundColor: t.skyBot),
    );
  }
}

/// Sky gradient backdrop with soft drifting clouds — used behind menus.
class SkyBackdrop extends StatelessWidget {
  final Widget child;
  final SkyThemeDef theme;
  const SkyBackdrop({super.key, required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [theme.skyTop, theme.skyBot],
        ),
      ),
      child: CustomPaint(
        painter: _CloudDriftPainter(theme),
        child: child,
      ),
    );
  }
}

class _CloudDriftPainter extends CustomPainter {
  final SkyThemeDef t;
  _CloudDriftPainter(this.t);

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()..color = t.cloud.withValues(alpha: 0.5);
    final spots = [
      (0.15, 0.12, 46.0),
      (0.72, 0.2, 60.0),
      (0.45, 0.06, 34.0),
      (0.9, 0.42, 40.0),
    ];
    for (final (fx, fy, r) in spots) {
      final c = Offset(size.width * fx, size.height * fy);
      canvas.drawCircle(c, r, p);
      canvas.drawCircle(c + Offset(r * 0.9, r * 0.2), r * 0.7, p);
      canvas.drawCircle(c + Offset(-r * 0.9, r * 0.25), r * 0.65, p);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// A chunky rounded button with real press travel — looks physically pushable.
class PuffyButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final double width;
  final double fontSize;
  final SkyThemeDef? theme;
  final Color? color;

  const PuffyButton({
    super.key,
    required this.label,
    required this.onTap,
    this.width = 250,
    this.fontSize = 19,
    this.theme,
    this.color,
  });

  @override
  State<PuffyButton> createState() => _PuffyButtonState();
}

class _PuffyButtonState extends State<PuffyButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null;
    final base = widget.color ?? const Color(0xFF6BAE3F);
    final top = Color.lerp(base, Colors.white, 0.28)!;
    final bottom = Color.lerp(base, Colors.black, 0.18)!;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _pressed = false);
              widget.onTap!();
            }
          : null,
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 90),
        width: widget.width,
        padding: const EdgeInsets.symmetric(vertical: 15),
        transform: Matrix4.translationValues(0, _pressed ? 3 : 0, 0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: enabled ? [top, base, bottom] : [bottom, bottom],
          ),
          border: Border.all(
              color: enabled
                  ? Colors.white.withValues(alpha: 0.85)
                  : Colors.white.withValues(alpha: 0.3),
              width: 3),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: _pressed ? 0.2 : 0.35),
              offset: Offset(0, _pressed ? 2 : 6),
              blurRadius: _pressed ? 4 : 10,
            ),
          ],
        ),
        alignment: Alignment.center,
        child: Text(
          widget.label,
          style: Meadow.display(widget.fontSize,
              color: enabled
                  ? Colors.white
                  : Colors.white.withValues(alpha: 0.5),
              theme: widget.theme),
        ),
      ),
    );
  }
}

/// A soft rounded card for menu sections.
class CloudCard extends StatelessWidget {
  final String title;
  final Widget child;
  final SkyThemeDef theme;
  const CloudCard(
      {super.key, required this.title, required this.child, required this.theme});

  @override
  Widget build(BuildContext context) {
    final night = theme.night;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: (night ? const Color(0xFF141B3D) : Colors.white)
            .withValues(alpha: night ? 0.72 : 0.82),
        border: Border.all(
            color: Colors.white.withValues(alpha: night ? 0.25 : 0.9), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            offset: const Offset(0, 6),
            blurRadius: 14,
          ),
        ],
      ),
      child: Column(
        children: [
          Text(title, style: Meadow.display(20, theme: theme)),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

/// A rounded selection chip.
class PickChip extends StatelessWidget {
  final SkyThemeDef theme;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final Color? dot;
  const PickChip({
    super.key,
    required this.theme,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 140),
        margin: const EdgeInsets.symmetric(horizontal: 3, vertical: 3),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: selected
              ? theme.celestial
              : (theme.night
                  ? Colors.white.withValues(alpha: 0.1)
                  : Colors.black.withValues(alpha: 0.08)),
          border: Border.all(
            color: selected
                ? Colors.white
                : (theme.night
                    ? Colors.white.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.18)),
            width: selected ? 2.5 : 1.5,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    offset: const Offset(0, 3),
                    blurRadius: 6,
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: dot,
                  border: Border.all(color: Colors.white, width: 1.5),
                ),
              ),
              const SizedBox(width: 7),
            ],
            Text(
              label,
              style: Meadow.label(13,
                  theme: theme,
                  color: selected
                      ? const Color(0xFF2E3A4A)
                      : (theme.night ? Colors.white : const Color(0xFF2E3A4A))),
            ),
          ],
        ),
      ),
    );
  }
}

/// A round icon toggle (metal-ring style, circular like the touch controls).
class MeadowToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;
  final SkyThemeDef theme;
  const MeadowToggle(
      {super.key, required this.value, required this.onChanged, required this.theme});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 64,
        height: 34,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(17),
          color: value ? const Color(0xFF6BAE3F) : Colors.black.withValues(alpha: 0.3),
          border: Border.all(color: Colors.white.withValues(alpha: 0.8), width: 2),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                offset: const Offset(0, 3),
                blurRadius: 5),
          ],
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            width: 26,
            height: 26,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Colors.white, Color(0xFFDCE6F2)],
              ),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withValues(alpha: 0.4),
                    offset: const Offset(0, 2),
                    blurRadius: 3),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Small helper: a labeled settings row.
class SettingRow extends StatelessWidget {
  final String label;
  final Widget control;
  final SkyThemeDef theme;
  const SettingRow(
      {super.key, required this.label, required this.control, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 7),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
      decoration: BoxDecoration(
        color: (theme.night ? Colors.white : Colors.black)
            .withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: Colors.white.withValues(alpha: theme.night ? 0.25 : 0.6),
            width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(child: Text(label, style: Meadow.body(16, theme: theme))),
          control,
        ],
      ),
    );
  }
}

/// A volume slider styled like a feather on a rail.
class FeatherSlider extends StatelessWidget {
  final double value;
  final ValueChanged<double> onChanged;
  final SkyThemeDef theme;
  const FeatherSlider(
      {super.key, required this.value, required this.onChanged, required this.theme});

  @override
  Widget build(BuildContext context) {
    return SliderTheme(
      data: SliderTheme.of(context).copyWith(
        trackHeight: 6,
        activeTrackColor: theme.celestial,
        inactiveTrackColor: Colors.black.withValues(alpha: 0.2),
        thumbShape: const _FeatherThumb(),
        overlayShape: SliderComponentShape.noOverlay,
      ),
      child: Slider(value: value, onChanged: onChanged),
    );
  }
}

class _FeatherThumb extends SliderComponentShape {
  const _FeatherThumb();

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) =>
      const Size(26, 26);

  @override
  void paint(PaintingContext context, Offset center,
      {required Animation<double> activationAnimation,
      required Animation<double> enableAnimation,
      required bool isDiscrete,
      required TextPainter labelPainter,
      required RenderBox parentBox,
      required SliderThemeData sliderTheme,
      required TextDirection textDirection,
      required double value,
      required double textScaleFactor,
      required Size sizeWithOverflow}) {
    final canvas = context.canvas;
    canvas.drawCircle(
        center + const Offset(0, 2), 12, Paint()..color = Colors.black38);
    canvas.drawCircle(
        center,
        11,
        Paint()
          ..shader = const RadialGradient(
            center: Alignment(-0.4, -0.5),
            radius: 1.0,
            colors: [Color(0xFFFFE08A), Color(0xFFFFB800)],
          ).createShader(Rect.fromCircle(center: center, radius: 11)));
  }
}
