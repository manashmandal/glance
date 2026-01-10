import 'package:flutter/services.dart';
import '../models/weather_data.dart';
import '../models/weather_action.dart';
import 'weather_action_fallback.dart';

/// Service for generating AI-based weather actions via platform channel
class WeatherAiService {
  static const _channel = MethodChannel('com.example.glance/weather_ai');
  static bool? _isAvailable;

  /// Check if on-device AI is available
  static Future<bool> checkAvailability() async {
    if (_isAvailable != null) return _isAvailable!;

    try {
      final result = await _channel.invokeMethod<Map>('checkAvailability');
      _isAvailable = result?['available'] == true;
      return _isAvailable!;
    } on PlatformException {
      _isAvailable = false;
      return false;
    } on MissingPluginException {
      // Platform channel not available (e.g., on web/desktop)
      _isAvailable = false;
      return false;
    }
  }

  /// Generate a weather action using AI or fallback to rules
  static Future<WeatherAction> generateAction(WeatherData weather) async {
    // First check if AI is available
    final aiAvailable = await checkAvailability();

    if (!aiAvailable) {
      return WeatherActionFallback.generate(weather);
    }

    try {
      final result = await _channel.invokeMethod<Map>('generateAction', {
        'weatherContext': weather.toAiContextString(),
      });

      if (result?['success'] == true && result?['action'] != null) {
        return WeatherAction.fromAi(result!['action'] as String);
      } else {
        // AI failed, use fallback
        return WeatherActionFallback.generate(weather);
      }
    } on PlatformException {
      return WeatherActionFallback.generate(weather);
    }
  }

  /// Dispose of native resources
  static Future<void> dispose() async {
    try {
      await _channel.invokeMethod('dispose');
    } catch (_) {
      // Ignore disposal errors
    }
  }
}
