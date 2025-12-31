import 'package:shared_preferences/shared_preferences.dart';
import '../models/widget_layout.dart';

class LayoutService {
  static const String _keyDashboardLayout = 'dashboard_layout';

  static Future<void> saveLayout(DashboardLayout layout) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDashboardLayout, layout.toJsonString());
  }

  static Future<DashboardLayout> getLayout() async {
    final prefs = await SharedPreferences.getInstance();
    final jsonString = prefs.getString(_keyDashboardLayout);

    if (jsonString == null) {
      return DashboardLayout.defaultLayout;
    }

    try {
      return DashboardLayout.fromJsonString(jsonString);
    } catch (e) {
      print('Error loading layout: $e');
      return DashboardLayout.defaultLayout;
    }
  }

  static Future<void> resetToDefault() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDashboardLayout);
  }
}
