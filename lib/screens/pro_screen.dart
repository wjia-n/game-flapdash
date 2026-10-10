import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../services/audio_service.dart';
import '../services/iap_service.dart';
import '../services/settings_service.dart';
import '../theme/meadow.dart';
import '../theme/sky_themes.dart';

/// Flap Dash PRO: Free-vs-Pro comparison, real purchase, restore, tip jar.
/// All prices come from the store — never hardcoded, never placeholders.
class ProScreen extends StatefulWidget {
  final FlapAudio audio;
  final FlapSettings settings;
  final StoreService store;

  const ProScreen({
    super.key,
    required this.audio,
    required this.settings,
    required this.store,
  });

  @override
  State<ProScreen> createState() => _ProScreenState();
}

class _ProScreenState extends State<ProScreen> {
  SkyThemeDef get _t => SkyThemes.byId(widget.settings.themeId,
      custom: widget.settings.customTheme);

  @override
  void initState() {
    super.initState();
    widget.store.lastThanks.addListener(_onThanks);
  }

  
  void _onThanks() {
    final msg = widget.store.lastThanks.value;
    if (msg == null || !mounted) return;
    widget.audio.win();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: Meadow.body(15, theme: _t)),
        backgroundColor: const Color(0xFF2E3A4A),
        behavior: SnackBarBehavior.floating,
      ),
    );
    widget.store.lastThanks.value = null;
  }

  @override
  void dispose() {
    widget.store.lastThanks.removeListener(_onThanks);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = _t;
    final s = widget.settings;
    final store = widget.store;
    return SkyBackdrop(
      theme: t,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back,
                color: t.night ? Colors.white : const Color(0xFF2E3A4A)),
            onPressed: () {
              widget.audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Flap Dash PRO', style: Meadow.display(22, theme: t)),
          centerTitle: true,
        ),
        body: SafeArea(
          child: ListenableBuilder(
            listenable: s,
            builder: (_, _) => SingleChildScrollView(
              padding:
                  const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              child: Column(
                children: [
                                    _TipsCard(
                    theme: t,
                    store: store,
                    audio: widget.audio,
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

// ---------------------------------------------------------------------------
/// Free vs Pro comparison table — buyers see the big difference.


// ---------------------------------------------------------------------------
class _TipsCard extends StatelessWidget {
  final SkyThemeDef theme;
  final StoreService store;
  final FlapAudio audio;
  const _TipsCard(
      {required this.theme, required this.store, required this.audio});

  @override
  Widget build(BuildContext context) {
    final tips = [
      store.coffeeProduct,
      store.chocolateProduct,
    ].whereType<ProductDetails>().toList();
    final night = theme.night;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        color: (night ? const Color(0xFF141B3D) : Colors.white)
            .withValues(alpha: night ? 0.72 : 0.85),
        border: Border.all(
            color: Colors.white.withValues(alpha: 0.8), width: 2),
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
          Text('Tip the Maker', style: Meadow.display(20, theme: theme)),
          const SizedBox(height: 8),
          Text(
            'Flap Dash is free forever. A small tip keeps new games coming!',
            style: Meadow.body(14, theme: theme),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Meadow.body(13, theme: theme),
              textAlign: TextAlign.center,
            )
          else if (tips.isEmpty)
            Text('Tips coming soon.', style: Meadow.body(13, theme: theme))
          else
            Wrap(
              spacing: 10,
              alignment: WrapAlignment.center,
              children: [
                for (final p in tips)
                  PickChip(
                    theme: theme,
                    label:
                        '${p.id == StoreService.chocolateId ? '🍫' : '☕'} ${p.price}',
                    selected: false,
                    onTap: () {
                      audio.click();
                      store.buyTip(p);
                    },
                  ),
              ],
            ),
        ],
      ),
    );
  }
}
