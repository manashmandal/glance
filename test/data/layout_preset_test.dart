import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/layout_preset.dart';

void main() {
  group('LayoutPresetConfig.of', () {
    test('editorial preset has default flex and scale', () {
      final c = LayoutPresetConfig.of(LayoutPreset.editorial);
      expect(c.heroOnly, isFalse);
      expect(c.upcomingFlex, equals(6));
      expect(c.weatherFlex, equals(4));
      expect(c.densityScale, equals(1.0));
    });

    test('heroOnly preset hides the bottom row', () {
      final c = LayoutPresetConfig.of(LayoutPreset.heroOnly);
      expect(c.heroOnly, isTrue);
    });

    test('split preset gives equal flex to upcoming and weather', () {
      final c = LayoutPresetConfig.of(LayoutPreset.split);
      expect(c.upcomingFlex, equals(c.weatherFlex));
    });

    test('dense preset scales typography down', () {
      final c = LayoutPresetConfig.of(LayoutPreset.dense);
      expect(c.densityScale, lessThan(1.0));
    });

    test('every preset value has a config', () {
      for (final preset in LayoutPreset.values) {
        expect(() => LayoutPresetConfig.of(preset), returnsNormally);
      }
    });
  });

  group('LayoutPresetSerialization', () {
    test('round-trips every preset via storage key', () {
      for (final preset in LayoutPreset.values) {
        expect(
          LayoutPresetSerialization.fromStorageKey(preset.storageKey),
          equals(preset),
        );
      }
    });

    test('unknown storage key defaults to editorial', () {
      expect(
        LayoutPresetSerialization.fromStorageKey('nope'),
        equals(LayoutPreset.editorial),
      );
      expect(
        LayoutPresetSerialization.fromStorageKey(null),
        equals(LayoutPreset.editorial),
      );
    });
  });
}
