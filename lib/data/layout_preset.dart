/// Named dashboard layouts. Each preset maps to a [LayoutPresetConfig]
/// that the dashboard consults when composing its body.
enum LayoutPreset { editorial, heroOnly, split, dense }

class LayoutPresetConfig {
  /// When true, hide the bottom row (upcoming + weather). The hero
  /// countdown and destination fill the remaining space.
  final bool heroOnly;

  /// Flex ratio between the upcoming list and weather column.
  final int upcomingFlex;
  final int weatherFlex;

  /// 1.0 = editorial default. <1 shrinks paddings and type for denser fit.
  final double densityScale;

  const LayoutPresetConfig({
    this.heroOnly = false,
    this.upcomingFlex = 6,
    this.weatherFlex = 4,
    this.densityScale = 1.0,
  });

  static const Map<LayoutPreset, LayoutPresetConfig> _configs = {
    LayoutPreset.editorial: LayoutPresetConfig(),
    LayoutPreset.heroOnly: LayoutPresetConfig(heroOnly: true),
    LayoutPreset.split: LayoutPresetConfig(upcomingFlex: 5, weatherFlex: 5),
    LayoutPreset.dense: LayoutPresetConfig(
      densityScale: 0.85,
      upcomingFlex: 6,
      weatherFlex: 4,
    ),
  };

  static LayoutPresetConfig of(LayoutPreset preset) => _configs[preset]!;
}

extension LayoutPresetSerialization on LayoutPreset {
  String get storageKey => name;
  static LayoutPreset fromStorageKey(String? key) {
    for (final p in LayoutPreset.values) {
      if (p.name == key) return p;
    }
    return LayoutPreset.editorial;
  }
}
