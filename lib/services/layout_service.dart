import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_layout.dart';

class LayoutService {
  static const String _keyDashboardLayoutLandscape =
      'dashboard_layout_landscape';
  static const String _keyDashboardLayoutPortrait = 'dashboard_layout_portrait';
  static const String _keyDashboardLayout = 'dashboard_layout'; // Legacy key

  static Future<void> saveLayout(
    DashboardLayout layout, {
    bool isPortrait = false,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isPortrait ? _keyDashboardLayoutPortrait : _keyDashboardLayoutLandscape;
    await prefs.setString(key, layout.toJsonString());
  }

  static Future<DashboardLayout> getLayout({bool isPortrait = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isPortrait ? _keyDashboardLayoutPortrait : _keyDashboardLayoutLandscape;
    var jsonString = prefs.getString(key);

    // Fallback to legacy key for landscape (migration support)
    if (jsonString == null && !isPortrait) {
      jsonString = prefs.getString(_keyDashboardLayout);
    }

    if (jsonString == null) {
      return _getDefaultLayout(isPortrait);
    }

    try {
      return DashboardLayout.fromJsonString(jsonString);
    } catch (e) {
      print('Error loading layout: $e');
      return _getDefaultLayout(isPortrait);
    }
  }

  static DashboardLayout _getDefaultLayout(bool isPortrait) {
    return isPortrait
        ? DashboardLayout.defaultPortraitLayout
        : DashboardLayout.defaultLandscapeLayout;
  }

  static Future<void> resetToDefault({bool isPortrait = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final key =
        isPortrait ? _keyDashboardLayoutPortrait : _keyDashboardLayoutLandscape;
    await prefs.remove(key);
  }

  static Future<void> resetAllLayouts() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDashboardLayoutLandscape);
    await prefs.remove(_keyDashboardLayoutPortrait);
    await prefs.remove(_keyDashboardLayout);
  }
}
