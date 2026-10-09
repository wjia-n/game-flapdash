import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/settings_service.dart';
import '../theme/meadow.dart';
import '../theme/sky_themes.dart';

/// Settings: audio toggles + volume, with live preview of the theme.
class SettingsScreen extends StatelessWidget {
  final FlapAudio audio;
  final FlapSettings settings;

  const SettingsScreen(
      {super.key, required this.audio, required this.settings});

  SkyThemeDef get _t =>
      SkyThemes.byId(settings.themeId, custom: settings.customTheme);

  void _apply() {
    audio.configure(
      musicOn: settings.musicOn,
      sfxOn: settings.sfxOn,
      volume: settings.volume,
    );
  }

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
            icon: Icon(Icons.arrow_back,
                color: t.night ? Colors.white : const Color(0xFF2E3A4A)),
            onPressed: () {
              audio.click();
              Navigator.of(context).pop();
            },
          ),
          title: Text('Settings', style: Meadow.display(24, theme: t)),
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
                  SettingRow(
                    theme: t,
                    label: '🎵 Music',
                    control: MeadowToggle(
                      theme: t,
                      value: settings.musicOn,
                      onChanged: (v) {
                        audio.click();
                        settings.setMusic(v);
                        _apply();
                        if (v) audio.startMenuMusic();
                      },
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: '🔊 Sound effects',
                    control: MeadowToggle(
                      theme: t,
                      value: settings.sfxOn,
                      onChanged: (v) {
                        settings.setSfx(v);
                        _apply();
                        audio.click();
                      },
                    ),
                  ),
                  SettingRow(
                    theme: t,
                    label: '🔈 Volume',
                    control: SizedBox(
                      width: 150,
                      child: FeatherSlider(
                        theme: t,
                        value: settings.volume,
                        onChanged: (v) {
                          settings.setVolume(v);
                          _apply();
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Toggle music off and on to hear it start reliably — it always comes back. 🎶',
                    style: Meadow.body(13, theme: t),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),
                  PuffyButton(
                    label: 'Done',
                    width: 200,
                    theme: t,
                    onTap: () {
                      audio.click();
                      Navigator.of(context).pop();
                    },
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
