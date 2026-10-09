import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/sky_themes.dart';

/// Persisted settings + stats for Flap Dash. Survives app restarts.
///
/// Stores: audio toggles, the renameable pilot profile (ONE JSON string —
/// NEVER setStringList; Android stores StringLists as an unordered StringSet
/// and scrambles order), theme/bird/pipe appearance choices (incl. custom
/// creator colors), mode + difficulty, Pro unlock, and lifetime stats.
class FlapSettings extends ChangeNotifier {
  static const _kMusic = 'flapdash_music_on';
  static const _kSfx = 'flapdash_sfx_on';
  static const _kVolume = 'flapdash_volume';
  /// Order-safe profile storage: a single JSON string (NEVER setStringList —
  /// Android stores StringLists as an unordered StringSet and scrambles
  /// order). Master-rules key for this game.
  static const _kProfileJson = 'flapdash_player_names_json';
  /// Key used before the master-rules rename; migrated once into
  /// [_kProfileJson].
  static const _kLegacyProfileJson = 'flapdash_profile_json';
  /// Legacy plain-string pilot name (migrated once into the JSON profile).
  static const _kLegacyName = 'flapdash_pilot_name';
  static const _kMode = 'flapdash_mode'; // 0 classic, 1 attack
  static const _kDifficulty = 'flapdash_difficulty'; // 0/1/2
  static const _kTheme = 'flapdash_theme_id';
  static const _kBird = 'flapdash_bird_style';
  static const _kPipe = 'flapdash_pipe_style';
  static const _kBestClassic = 'flapdash_best'; // legacy int key, kept
  static const _kBestAttack = 'flapdash_best_attack';
  static const _kGames = 'flapdash_games_played';
  static const _kFlaps = 'flapdash_total_flaps';
  static const _kIsPro = 'flapdash_is_pro';
  static const _kCustomPrefix = 'flapdash_custom_';

  static const defaultPilotName = 'Dash';

  /// Encode the pilot profile as one JSON string (order-preserving).
  static String encodeProfile(Map<String, String> profile) =>
      jsonEncode(profile);

  static String _cleanName(Object? v) {
    final s = v is String ? v.trim() : '';
    return s.isEmpty ? defaultPilotName : s;
  }

  /// Decode the persisted profile; falls back to defaults on missing/corrupt
  /// data. Migrates the legacy plain-string key once.
  static String decodePilotName(String? raw, {String? legacy}) {
    if (raw != null) {
      try {
        final d = jsonDecode(raw);
        if (d is Map && d['name'] != null) return _cleanName(d['name']);
      } catch (_) {}
    }
    return _cleanName(legacy);
  }

  bool musicOn = true;
  bool sfxOn = true;
  double volume = 0.8;
  String pilotName = defaultPilotName;
  int mode = 0; // 0 classic endless, 1 score attack
  int difficulty = 0; // 0 breeze, 1 gust, 2 storm
  String themeId = 'meadow';
  int birdStyle = 0;
  int pipeStyle = 0;
  int bestClassic = 0;
  int bestAttack = 0;
  int gamesPlayed = 0;
  int totalFlaps = 0;
  bool isPro = false;

  /// Custom creator colors (ARGB ints). Defaults mirror Sunny Finch /
  /// Crystal Gates / Meadow Day.
  Map<String, int> customColors = Map.of(_defaultCustomColors);

  static const Map<String, int> _defaultCustomColors = {
    'skyTop': 0xFF7CC7F2,
    'skyBot': 0xFFD9F1FF,
    'birdBody': 0xFFFFC93B,
    'birdWing': 0xFFFF9F1C,
    'birdBeak': 0xFFFF6B35,
    'pipeMain': 0xFF38BDF8,
  };

  /// The user-designed custom sky (for the 'custom' theme tile).
  SkyThemeDef get customTheme {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return SkyThemeDef(
      id: 'custom',
      name: 'My Creation',
      skyTop: c('skyTop'),
      skyBot: c('skyBot'),
      hillFar: c('skyTop'),
      hillNear: c('skyBot'),
      night: false,
      celestial: const Color(0xFFFFD93B),
      cloud: const Color(0xFFFFFFFF),
    );
  }

  /// The user-designed custom bird (last bird-style index = custom).
  BirdStyleDef get customBird {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    return BirdStyleDef(
      id: 'custom',
      name: 'My Creation',
      body: c('birdBody'),
      wing: c('birdWing'),
      beak: c('birdBeak'),
      belly: c('birdBody'),
    );
  }

  /// The user-designed custom pipe (last pipe-style index = custom).
  PipeStyleDef get customPipe {
    Color c(String k) => Color(customColors[k] ?? 0xFF000000);
    final main = c('pipeMain');
    return PipeStyleDef(
      id: 'custom',
      name: 'My Creation',
      main: main,
      light: Color.lerp(main, Colors.white, 0.45)!,
      dark: Color.lerp(main, Colors.black, 0.35)!,
      crystalline: true,
    );
  }

  SharedPreferences? _prefs;

  Future<void> load() async {
    _prefs = await SharedPreferences.getInstance();
    final p = _prefs!;
    musicOn = p.getBool(_kMusic) ?? true;
    sfxOn = p.getBool(_kSfx) ?? true;
    volume = p.getDouble(_kVolume) ?? 0.8;
    // Pilot profile: prefer the order-safe JSON key; fall back to the legacy
    // keys once (one-time migration into the master-rules key).
    pilotName = decodePilotName(
      p.getString(_kProfileJson) ?? p.getString(_kLegacyProfileJson),
      legacy: p.getString(_kLegacyName),
    );
    mode = (p.getInt(_kMode) ?? 0).clamp(0, 1);
    difficulty = (p.getInt(_kDifficulty) ?? 0).clamp(0, 2);
    themeId = p.getString(_kTheme) ?? 'meadow';
    birdStyle = (p.getInt(_kBird) ?? 0).clamp(0, BirdStyles.all.length);
    pipeStyle = (p.getInt(_kPipe) ?? 0).clamp(0, PipeStyles.all.length);
    bestClassic = p.getInt(_kBestClassic) ?? 0;
    bestAttack = p.getInt(_kBestAttack) ?? 0;
    gamesPlayed = p.getInt(_kGames) ?? 0;
    totalFlaps = p.getInt(_kFlaps) ?? 0;
    isPro = p.getBool(_kIsPro) ?? false;
    for (final k in _defaultCustomColors.keys) {
      customColors[k] =
          p.getInt('$_kCustomPrefix$k') ?? _defaultCustomColors[k]!;
    }
    _enforceFreeLimits(silent: true);
    notifyListeners();
  }

  Future<void> _save() async {
    final p = _prefs;
    if (p == null) return;
    await p.setBool(_kMusic, musicOn);
    await p.setBool(_kSfx, sfxOn);
    await p.setDouble(_kVolume, volume);
    await p.setString(_kProfileJson, encodeProfile({'name': pilotName}));
    await p.remove(_kLegacyProfileJson); // drop the legacy keys for good
    await p.remove(_kLegacyName);
    await p.setInt(_kMode, mode);
    await p.setInt(_kDifficulty, difficulty);
    await p.setString(_kTheme, themeId);
    await p.setInt(_kBird, birdStyle);
    await p.setInt(_kPipe, pipeStyle);
    await p.setInt(_kBestClassic, bestClassic);
    await p.setInt(_kBestAttack, bestAttack);
    await p.setInt(_kGames, gamesPlayed);
    await p.setInt(_kFlaps, totalFlaps);
    await p.setBool(_kIsPro, isPro);
    for (final e in customColors.entries) {
      await p.setInt('$_kCustomPrefix${e.key}', e.value);
    }
  }

  /// Free-tier limits: clamp pro-only choices back when not Pro.
  void _enforceFreeLimits({bool silent = false}) {
    if (isPro) return;
    var changed = false;
    if (themeId == 'custom' || SkyThemes.isProTheme(themeId)) {
      themeId = 'meadow';
      changed = true;
    }
    if (birdStyle == BirdStyles.all.length || BirdStyles.isPro(birdStyle)) {
      birdStyle = 0;
      changed = true;
    }
    if (pipeStyle == PipeStyles.all.length || PipeStyles.isPro(pipeStyle)) {
      pipeStyle = 0;
      changed = true;
    }
    if (difficulty > 1) {
      difficulty = 1;
      changed = true;
    }
    if (changed && !silent) {
      notifyListeners();
      _save();
    }
  }

  Future<void> setPro(bool v) async {
    isPro = v;
    if (!v) _enforceFreeLimits();
    notifyListeners();
    await _save();
  }

  /// Writes ONLY the pilot profile key — cheap enough for per-keystroke
  /// saves from the name field (the full [_save] writes every key).
  Future<void> _saveProfile() async {
    final p = _prefs;
    if (p == null) return;
    await p.setString(_kProfileJson, encodeProfile({'name': pilotName}));
    await p.remove(_kLegacyProfileJson);
    await p.remove(_kLegacyName);
  }

  /// Live keystroke save for the rename field: stores the raw text
  /// immediately (never lost mid-word), one order-preserving JSON string.
  Future<void> updatePilotNameLive(String v) async {
    pilotName = v;
    notifyListeners();
    await _saveProfile();
  }

  /// Commit on focus loss / keyboard done: trims and normalizes the name.
  Future<void> setPilotName(String name) async {
    final clean = name.trim();
    pilotName = clean.isEmpty ? defaultPilotName : clean;
    notifyListeners();
    await _saveProfile();
  }

  Future<void> setMusic(bool v) async {
    musicOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setSfx(bool v) async {
    sfxOn = v;
    notifyListeners();
    await _save();
  }

  Future<void> setVolume(double v) async {
    volume = v.clamp(0.0, 1.0);
    notifyListeners();
    await _save();
  }

  Future<void> setMode(int v) async {
    mode = v.clamp(0, 1);
    notifyListeners();
    await _save();
  }

  Future<void> setDifficulty(int v) async {
    v = v.clamp(0, 2);
    // Storm is a Pro feature.
    if (v == 2 && !isPro) return;
    difficulty = v;
    notifyListeners();
    await _save();
  }

  Future<void> setTheme(String id) async {
    // Pro-only themes (incl. the custom creator) require Pro.
    if (!isPro && (id == 'custom' || SkyThemes.isProTheme(id))) return;
    themeId = id;
    notifyListeners();
    await _save();
  }

  Future<void> setBirdStyle(int v) async {
    final max = BirdStyles.all.length; // last index = custom creator
    v = v.clamp(0, max);
    final isCustom = v == max;
    if (!isPro && (isCustom || BirdStyles.isPro(v))) return;
    birdStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setPipeStyle(int v) async {
    final max = PipeStyles.all.length; // last index = custom creator
    v = v.clamp(0, max);
    final isCustom = v == max;
    if (!isPro && (isCustom || PipeStyles.isPro(v))) return;
    pipeStyle = v;
    notifyListeners();
    await _save();
  }

  Future<void> setCustomColor(String key, int argb) async {
    if (!isPro) return; // custom creator is a Pro feature
    if (!_defaultCustomColors.containsKey(key)) return;
    customColors[key] = argb;
    notifyListeners();
    await _save();
  }

  Future<void> resetCustomColors() async {
    customColors = Map.of(_defaultCustomColors);
    notifyListeners();
    await _save();
  }

  /// Record a finished run. Returns true when a new best was set.
  Future<bool> recordRun({required int score, required int flaps}) async {
    gamesPlayed++;
    totalFlaps += flaps;
    bool newBest = false;
    if (mode == 1) {
      if (score > bestAttack) {
        bestAttack = score;
        newBest = true;
      }
    } else {
      if (score > bestClassic) {
        bestClassic = score;
        newBest = true;
      }
    }
    notifyListeners();
    await _save();
    return newBest;
  }

  int get best => mode == 1 ? bestAttack : bestClassic;
}
