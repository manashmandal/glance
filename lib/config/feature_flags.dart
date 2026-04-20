import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FeatureFlag {
  final String key;
  final String label;
  final String description;
  final bool defaultValue;

  const FeatureFlag({
    required this.key,
    required this.label,
    required this.description,
    required this.defaultValue,
  });
}

/// Runtime feature gates. Default values ship in release builds. In debug
/// builds, overrides persisted via `SharedPreferences` take precedence so
/// you can flip flags from the in-app Dev pane without a rebuild.
class FeatureFlags {
  FeatureFlags._();

  static const layoutPane = FeatureFlag(
    key: 'ff_layout_pane',
    label: 'Layout presets',
    description:
        'Show the Layout pane with Editorial / Hero only / Split / Dense variants.',
    defaultValue: true,
  );

  static const layoutEditMode = FeatureFlag(
    key: 'ff_layout_edit_mode',
    label: 'Layout edit mode',
    description:
        'Show Edit mode + Snap-to-grid controls. No underlying editor yet.',
    defaultValue: false,
  );

  static const refreshCadence = FeatureFlag(
    key: 'ff_refresh_cadence',
    label: 'Refresh cadence',
    description:
        'Show refresh-interval chips in Departures. Timer is hardcoded to 1 min.',
    defaultValue: false,
  );

  static const List<FeatureFlag> all = [
    layoutPane,
    layoutEditMode,
    refreshCadence,
  ];

  static final Map<String, bool> _overrides = {};

  static bool isEnabled(FeatureFlag flag) =>
      _overrides[flag.key] ?? flag.defaultValue;

  static bool hasOverride(FeatureFlag flag) => _overrides.containsKey(flag.key);

  /// Load persisted overrides. Debug builds only — release builds ignore
  /// stored overrides so a leftover flag flip in dev prefs can't change
  /// production behavior.
  static Future<void> load() async {
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    for (final flag in all) {
      if (prefs.containsKey(flag.key)) {
        _overrides[flag.key] = prefs.getBool(flag.key) ?? flag.defaultValue;
      }
    }
  }

  static Future<void> setOverride(FeatureFlag flag, bool value) async {
    _overrides[flag.key] = value;
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(flag.key, value);
  }

  static Future<void> clearOverride(FeatureFlag flag) async {
    _overrides.remove(flag.key);
    if (!kDebugMode) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(flag.key);
  }
}
