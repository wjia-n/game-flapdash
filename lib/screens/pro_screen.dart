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
    widget.store.proPurchased.addListener(_onPro);
    widget.store.lastThanks.addListener(_onThanks);
  }

  void _onPro() {
    if (widget.store.proPurchased.value && mounted) {
      widget.settings.setPro(true);
      widget.audio.win();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('PRO unlocked — enjoy everything!',
              style: Meadow.body(15, theme: _t)),
          backgroundColor: const Color(0xFF2E3A4A),
          behavior: SnackBarBehavior.floating,
        ),
      );
      widget.store.proPurchased.value = false;
    }
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
    widget.store.proPurchased.removeListener(_onPro);
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
                  _ComparisonCard(theme: t, isPro: s.isPro),
                  const SizedBox(height: 16),
                  _BuyCard(
                    theme: t,
                    settings: s,
                    store: store,
                    audio: widget.audio,
                  ),
                  const SizedBox(height: 16),
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
class _ComparisonCard extends StatelessWidget {
  final SkyThemeDef theme;
  final bool isPro;
  const _ComparisonCard({required this.theme, required this.isPro});

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('Complete Flap Dash game', true, true),
      ('Classic endless mode', true, true),
      ('Score Attack (60s)', true, true),
      ('Breeze & Gust difficulty', true, true),
      ('Renameable pilot', true, true),
      ('Music & sound effects', true, true),
      ('Sky themes', '4', '12+'),
      ('Bird styles', '4', '8+'),
      ('Gate styles', '4', '8+'),
      ('Storm difficulty (swaying gates)', false, true),
      ('Style creator (custom sky/bird/gates)', false, true),
    ];
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
          Text('Free vs PRO', style: Meadow.display(20, theme: theme)),
          const SizedBox(height: 4),
          Text(
            'One purchase. Yours forever.',
            style: Meadow.body(13, theme: theme),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Expanded(flex: 5, child: SizedBox()),
              Expanded(
                  flex: 2,
                  child: Text('FREE',
                      style: Meadow.label(12, theme: theme),
                      textAlign: TextAlign.center)),
              Expanded(
                  flex: 2,
                  child: Text('PRO',
                      style: Meadow.label(12, theme: theme),
                      textAlign: TextAlign.center)),
            ],
          ),
          const Divider(height: 14),
          for (final r in rows)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 5),
              child: Row(
                children: [
                  Expanded(
                    flex: 5,
                    child:
                        Text(r.$1, style: Meadow.body(13, theme: theme)),
                  ),
                  Expanded(flex: 2, child: _Cell(value: r.$2, theme: theme)),
                  Expanded(flex: 2, child: _Cell(value: r.$3, theme: theme)),
                ],
              ),
            ),
          if (isPro)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  color: const Color(0xFFFFB800).withValues(alpha: 0.25),
                  border: Border.all(color: const Color(0xFFFFB800)),
                ),
                child: Text('✦ PRO ACTIVE ✦',
                    style: Meadow.label(14, theme: theme)),
              ),
            ),
        ],
      ),
    );
  }
}

class _Cell extends StatelessWidget {
  final Object value; // bool | String
  final SkyThemeDef theme;
  const _Cell({required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    if (value is bool) {
      final v = value as bool;
      return Text(
        v ? '✓' : '—',
        style: Meadow.body(15,
            theme: theme,
            color: v
                ? const Color(0xFF2E9A3B)
                : (theme.night ? Colors.white54 : Colors.black38)),
        textAlign: TextAlign.center,
      );
    }
    return Text(
      value as String,
      style: Meadow.label(12, theme: theme),
      textAlign: TextAlign.center,
    );
  }
}

// ---------------------------------------------------------------------------
class _BuyCard extends StatelessWidget {
  final SkyThemeDef theme;
  final FlapSettings settings;
  final StoreService store;
  final FlapAudio audio;
  const _BuyCard({
    required this.theme,
    required this.settings,
    required this.store,
    required this.audio,
  });

  @override
  Widget build(BuildContext context) {
    final pro = store.proProduct;
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
          Text('Unlock PRO', style: Meadow.display(20, theme: theme)),
          const SizedBox(height: 8),
          if (settings.isPro)
            Text('You already own PRO — thank you!',
                style: Meadow.body(14, theme: theme),
                textAlign: TextAlign.center)
          else if (!store.storeReady)
            Text(
              store.error ?? 'Available after store setup.',
              style: Meadow.body(14, theme: theme),
              textAlign: TextAlign.center,
            )
          else if (pro != null) ...[
            Text(
                pro.description.isNotEmpty
                    ? pro.description
                    : 'Unlock everything in Flap Dash, forever.',
                style: Meadow.body(14, theme: theme),
                textAlign: TextAlign.center),
            const SizedBox(height: 12),
            ValueListenableBuilder<bool>(
              valueListenable: store.purchaseInProgress,
              builder: (_, busy, _) => PuffyButton(
                label: busy ? 'Working…' : 'Get PRO — ${pro.price}',
                width: 260,
                theme: theme,
                color: const Color(0xFFFFB800),
                onTap: busy
                    ? null
                    : () {
                        audio.click();
                        store.buyPro();
                      },
              ),
            ),
          ],
          ValueListenableBuilder<String?>(
            valueListenable: store.purchaseError,
            builder: (_, err, _) => err == null
                ? const SizedBox.shrink()
                : Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(err,
                        style: Meadow.body(13,
                            theme: theme,
                            color: const Color(0xFFD64545)),
                        textAlign: TextAlign.center),
                  ),
          ),
          const SizedBox(height: 10),
          TextButton(
            onPressed: () {
              audio.click();
              store.restore();
            },
            child: Text('Restore purchases',
                style: Meadow.label(13, theme: theme)),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
/// Consumable tips — pure support, with real store prices.
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
