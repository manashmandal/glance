import 'package:shared_preferences/shared_preferences.dart';
import '../models/transport_type.dart';

class SettingsService {
  static const String _keyWeatherScale = 'weather_scale';
  static const String _keyDepartureScale = 'departure_scale';
  static const String _keyDefaultStationId = 'default_station_id';
  static const String _keyDefaultTransportType = 'default_transport_type';
  static const String _keySkipMinutes = 'skip_minutes';
  static const String _keyDurationMinutes = 'duration_minutes';
  static const String _keyShowWeatherActions = 'show_weather_actions';

  static Future<void> saveWeatherScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWeatherScale, scale);
  }

  static Future<double> getWeatherScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyWeatherScale) ?? 1.0;
  }

  static Future<void> saveDepartureScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDepartureScale, scale);
  }

  static Future<double> getDepartureScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyDepartureScale) ?? 1.0;
  }

  static Future<void> saveDefaultStationId(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultStationId, stationId);
  }

  static Future<String?> getDefaultStationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultStationId);
  }

  static Future<void> saveDefaultTransportType(TransportType type) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDefaultTransportType, type.index);
  }

  static Future<TransportType> getDefaultTransportType() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt(_keyDefaultTransportType) ?? 0;
    if (index >= 0 && index < TransportType.values.length) {
      return TransportType.values[index];
    }
    return TransportType.regional;
  }

  static Future<void> saveSkipMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySkipMinutes, minutes);
  }

  static Future<int> getSkipMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySkipMinutes) ?? 0;
  }

  static Future<void> saveDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDurationMinutes, minutes);
  }

  static Future<int> getDurationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDurationMinutes) ?? 60;
  }

  static Future<void> saveShowWeatherActions(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowWeatherActions, show);
  }

  static Future<bool> getShowWeatherActions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowWeatherActions) ?? false;
  }
}
