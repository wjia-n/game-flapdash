import 'package:flutter/material.dart';

/// Sky themes, bird styles and pipe styles for Flap Dash.
///
/// Every entry stays inside the game's own art direction: warm storybook
/// skies, physical materials (crystal, wood, bamboo, stone, copper, marble),
/// soft depth and realistic lighting. No neon, no cyberpunk, no AI-dashboard
/// looks.

// ------------------------------------------------------------------ themes
class SkyThemeDef {
  final String id;
  final String name;
  final Color skyTop;
  final Color skyBot;
  final Color hillFar;
  final Color hillNear;
  final bool night;
  final Color celestial; // sun or moon color
  final Color cloud;

  const SkyThemeDef({
    required this.id,
    required this.name,
    required this.skyTop,
    required this.skyBot,
    required this.hillFar,
    required this.hillNear,
    required this.night,
    required this.celestial,
    required this.cloud,
  });
}

class SkyThemes {
  /// First 4 are FREE. The rest are PRO.
  static const List<String> freeThemeIds = [
    'meadow',
    'sunset',
    'starry',
    'snowy',
  ];

  static const List<SkyThemeDef> all = [
    SkyThemeDef(
      id: 'meadow',
      name: 'Meadow Day',
      skyTop: Color(0xFF7CC7F2),
      skyBot: Color(0xFFD9F1FF),
      hillFar: Color(0xFF8FD18A),
      hillNear: Color(0xFF6FBF6E),
      night: false,
      celestial: Color(0xFFFFD93B),
      cloud: Color(0xFFFFFFFF),
    ),
    SkyThemeDef(
      id: 'sunset',
      name: 'Sunset Grove',
      skyTop: Color(0xFFE8875A),
      skyBot: Color(0xFFFFD9A3),
      hillFar: Color(0xFF9A6B8F),
      hillNear: Color(0xFF7E5578),
      night: false,
      celestial: Color(0xFFFFF1C9),
      cloud: Color(0xFFFFE4C4),
    ),
    SkyThemeDef(
      id: 'starry',
      name: 'Starry Night',
      skyTop: Color(0xFF0E1430),
      skyBot: Color(0xFF27315E),
      hillFar: Color(0xFF1E2A4A),
      hillNear: Color(0xFF16203A),
      night: true,
      celestial: Color(0xFFF5F0DC),
      cloud: Color(0xFF3A4670),
    ),
    SkyThemeDef(
      id: 'snowy',
      name: 'Snowy Morning',
      skyTop: Color(0xFFA9D3E8),
      skyBot: Color(0xFFF2FAFF),
      hillFar: Color(0xFFDCEBF5),
      hillNear: Color(0xFFFFFFFF),
      night: false,
      celestial: Color(0xFFFFF6D9),
      cloud: Color(0xFFFFFFFF),
    ),
    SkyThemeDef(
      id: 'dawn',
      name: 'Dawn Mist',
      skyTop: Color(0xFFFFA98A),
      skyBot: Color(0xFFFFE8D6),
      hillFar: Color(0xFFC9A48F),
      hillNear: Color(0xFFB08A76),
      night: false,
      celestial: Color(0xFFFFF4DE),
      cloud: Color(0xFFFFDCC8),
    ),
    SkyThemeDef(
      id: 'autumn',
      name: 'Autumn Orchard',
      skyTop: Color(0xFFEFA24E),
      skyBot: Color(0xFFFFF0CE),
      hillFar: Color(0xFFC98A4B),
      hillNear: Color(0xFFB0743A),
      night: false,
      celestial: Color(0xFFFFE3A1),
      cloud: Color(0xFFFFE8C9),
    ),
    SkyThemeDef(
      id: 'desert',
      name: 'Desert Noon',
      skyTop: Color(0xFFFFC46B),
      skyBot: Color(0xFFFFF6DC),
      hillFar: Color(0xFFE8B96A),
      hillNear: Color(0xFFDDA557),
      night: false,
      celestial: Color(0xFFFFF3C4),
      cloud: Color(0xFFFFF0D2),
    ),
    SkyThemeDef(
      id: 'blossom',
      name: 'Cherry Blossom',
      skyTop: Color(0xFFFFAEC9),
      skyBot: Color(0xFFFFF0F6),
      hillFar: Color(0xFFE89BB8),
      hillNear: Color(0xFFDD86A9),
      night: false,
      celestial: Color(0xFFFFF6D9),
      cloud: Color(0xFFFFDFEA),
    ),
    SkyThemeDef(
      id: 'ocean',
      name: 'Ocean Cliffs',
      skyTop: Color(0xFF4FA3DE),
      skyBot: Color(0xFFDFF3FF),
      hillFar: Color(0xFF6FB3A3),
      hillNear: Color(0xFF5AA38F),
      night: false,
      celestial: Color(0xFFFFEDAE),
      cloud: Color(0xFFFFFFFF),
    ),
    SkyThemeDef(
      id: 'midnight',
      name: 'Midnight Moon',
      skyTop: Color(0xFF05081A),
      skyBot: Color(0xFF141B3D),
      hillFar: Color(0xFF101A38),
      hillNear: Color(0xFF0A122A),
      night: true,
      celestial: Color(0xFFF8F4E2),
      cloud: Color(0xFF232D55),
    ),
    SkyThemeDef(
      id: 'volcano',
      name: 'Ember Volcano',
      skyTop: Color(0xFF4A2430),
      skyBot: Color(0xFFFF9A5E),
      hillFar: Color(0xFF5E2E3A),
      hillNear: Color(0xFF45202C),
      night: false,
      celestial: Color(0xFFFFD166),
      cloud: Color(0xFF8A5A4A),
    ),
    SkyThemeDef(
      id: 'lagoon',
      name: 'Tropical Lagoon',
      skyTop: Color(0xFF4FD6B0),
      skyBot: Color(0xFFEFFFF7),
      hillFar: Color(0xFF6FC7A8),
      hillNear: Color(0xFF5AB795),
      night: false,
      celestial: Color(0xFFFFF3B0),
      cloud: Color(0xFFFFFFFF),
    ),
  ];

  static SkyThemeDef byId(String id, {SkyThemeDef? custom}) {
    if (id == 'custom') return custom ?? all.first;
    return all.firstWhere((t) => t.id == id, orElse: () => all.first);
  }

  static bool isProTheme(String id) =>
      !freeThemeIds.contains(id) && id != 'custom';
}

// ------------------------------------------------------------------ birds
class BirdStyleDef {
  final String id;
  final String name;
  final Color body;
  final Color wing;
  final Color beak;
  final Color belly;

  const BirdStyleDef({
    required this.id,
    required this.name,
    required this.body,
    required this.wing,
    required this.beak,
    required this.belly,
  });
}

class BirdStyles {
  /// 0-3 FREE, 4+ PRO.
  static const List<BirdStyleDef> all = [
    BirdStyleDef(
      id: 'finch',
      name: 'Sunny Finch',
      body: Color(0xFFFFC93B),
      wing: Color(0xFFFF9F1C),
      beak: Color(0xFFFF6B35),
      belly: Color(0xFFFFE08A),
    ),
    BirdStyleDef(
      id: 'robin',
      name: 'Meadow Robin',
      body: Color(0xFF8B5E3C),
      wing: Color(0xFF6E4A2E),
      beak: Color(0xFFFFD93B),
      belly: Color(0xFFE8875A),
    ),
    BirdStyleDef(
      id: 'bluebird',
      name: 'Sky Bluebird',
      body: Color(0xFF4AA8DE),
      wing: Color(0xFF3584B8),
      beak: Color(0xFFFFB800),
      belly: Color(0xFFBFE3F5),
    ),
    BirdStyleDef(
      id: 'sparrow',
      name: 'Dusty Sparrow',
      body: Color(0xFFB08968),
      wing: Color(0xFF96704F),
      beak: Color(0xFF5E4128),
      belly: Color(0xFFDECAA8),
    ),
    BirdStyleDef(
      id: 'owl',
      name: 'Moon Owl',
      body: Color(0xFF8B6F47),
      wing: Color(0xFF6E5636),
      beak: Color(0xFFFFB800),
      belly: Color(0xFFD9C69E),
    ),
    BirdStyleDef(
      id: 'parrot',
      name: 'Palm Parrot',
      body: Color(0xFF3FB97F),
      wing: Color(0xFF2E9A66),
      beak: Color(0xFFFF8A3B),
      belly: Color(0xFFA8E6C5),
    ),
    BirdStyleDef(
      id: 'penguin',
      name: 'Pebble Penguin',
      body: Color(0xFF2E3440),
      wing: Color(0xFF232936),
      beak: Color(0xFFFFB800),
      belly: Color(0xFFFFFFFF),
    ),
    BirdStyleDef(
      id: 'cardinal',
      name: 'Scarlet Cardinal',
      body: Color(0xFFD64545),
      wing: Color(0xFFB23636),
      beak: Color(0xFFFFB800),
      belly: Color(0xFFF2A3A3),
    ),
  ];

  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;

  static BirdStyleDef byIndex(int i, {BirdStyleDef? custom}) {
    if (i == all.length) return custom ?? all.first; // 'custom'
    return all[i.clamp(0, all.length - 1)];
  }
}

// ------------------------------------------------------------------ pipes
class PipeStyleDef {
  final String id;
  final String name;
  final Color main;
  final Color light;
  final Color dark;
  final bool crystalline;

  const PipeStyleDef({
    required this.id,
    required this.name,
    required this.main,
    required this.light,
    required this.dark,
    required this.crystalline,
  });
}

class PipeStyles {
  /// 0-3 FREE, 4+ PRO.
  static const List<PipeStyleDef> all = [
    PipeStyleDef(
      id: 'crystal',
      name: 'Crystal Gates',
      main: Color(0xFF38BDF8),
      light: Color(0xFFA8E1FD),
      dark: Color(0xFF1D7FB8),
      crystalline: true,
    ),
    PipeStyleDef(
      id: 'oak',
      name: 'Oak Trunks',
      main: Color(0xFF8B5A2B),
      light: Color(0xFFB98A52),
      dark: Color(0xFF5E3A1A),
      crystalline: false,
    ),
    PipeStyleDef(
      id: 'bamboo',
      name: 'Bamboo Stalks',
      main: Color(0xFF6BAE3F),
      light: Color(0xFF9AD56E),
      dark: Color(0xFF47802A),
      crystalline: false,
    ),
    PipeStyleDef(
      id: 'slate',
      name: 'Slate Pillars',
      main: Color(0xFF6B7280),
      light: Color(0xFF9AA3B2),
      dark: Color(0xFF454C58),
      crystalline: false,
    ),
    PipeStyleDef(
      id: 'copper',
      name: 'Copper Pipes',
      main: Color(0xFFB87333),
      light: Color(0xFFE0A45C),
      dark: Color(0xFF7E4F22),
      crystalline: false,
    ),
    PipeStyleDef(
      id: 'marble',
      name: 'Marble Columns',
      main: Color(0xFFE8E2D4),
      light: Color(0xFFFFFFFF),
      dark: Color(0xFFB8B09C),
      crystalline: true,
    ),
    PipeStyleDef(
      id: 'vine',
      name: 'Thorn Vines',
      main: Color(0xFF2E7D4F),
      light: Color(0xFF57A878),
      dark: Color(0xFF1C5533),
      crystalline: false,
    ),
    PipeStyleDef(
      id: 'cherry',
      name: 'Cherry Wood',
      main: Color(0xFFA31621),
      light: Color(0xFFD4454F),
      dark: Color(0xFF6E0F16),
      crystalline: false,
    ),
  ];

  static const freeCount = 4;
  static bool isPro(int index) => index >= freeCount;

  static PipeStyleDef byIndex(int i, {PipeStyleDef? custom}) {
    if (i == all.length) return custom ?? all.first; // 'custom'
    return all[i.clamp(0, all.length - 1)];
  }
}
