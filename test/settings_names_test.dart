import 'package:flutter_test/flutter_test.dart';
import 'package:flapdash/services/settings_service.dart';

/// Profile-name persistence: ONE JSON string, never setStringList
/// (Android's StringSet would scramble order). Legacy keys migrate once.
void main() {
  group('FlapSettings profile encoding', () {
    test('encode/decode round-trips the pilot name', () {
      const name = 'SkyQueen';
      final raw = FlapSettings.encodeProfile({'name': name});
      expect(FlapSettings.decodePilotName(raw), name);
    });

    test('corrupt JSON falls back to the default name', () {
      expect(FlapSettings.decodePilotName('not-json{{{'),
          FlapSettings.defaultPilotName);
      expect(FlapSettings.decodePilotName(null),
          FlapSettings.defaultPilotName);
    });

    test('legacy plain-string name migrates when no JSON exists', () {
      expect(
          FlapSettings.decodePilotName(null, legacy: 'OldPilot'),
          'OldPilot');
    });

    test('blank names fall back to the default', () {
      final raw = FlapSettings.encodeProfile({'name': '   '});
      expect(FlapSettings.decodePilotName(raw),
          FlapSettings.defaultPilotName);
    });
  });
}
