import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../data/api_diagnostics.dart';
import '../models/weather_data.dart';

class WeatherService {
  // Berlin coordinates (using default for now as per request)
  static const double _lat = 52.52;
  static const double _lng = 13.41;
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';
  static const String _endpointLabel = 'api.open-meteo.com/v1/forecast';
  static const Duration _timeout = Duration(seconds: 10);

  static Future<WeatherData> getWeather() async {
    final sw = Stopwatch()..start();
    try {
      const url = '$_baseUrl'
          '?latitude=$_lat'
          '&longitude=$_lng'
          '&current=temperature_2m,weather_code,precipitation_probability,wind_speed_10m,relative_humidity_2m'
          '&hourly=temperature_2m,weather_code,precipitation_probability'
          '&daily=temperature_2m_max,temperature_2m_min'
          '&timezone=auto'
          '&forecast_hours=12';

      final response = await http.get(Uri.parse(url)).timeout(_timeout);
      sw.stop();

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        _record(sw, success: true, code: 200);
        return WeatherData.fromJson(data);
      }
      _record(sw, success: false, code: response.statusCode);
      throw Exception('Failed to load weather data: ${response.statusCode}');
    } catch (e) {
      sw.stop();
      _record(sw, success: false, error: e);
      debugPrint('❌ Weather API error: $e');
      throw Exception('Error fetching weather: $e');
    }
  }

  static void _record(
    Stopwatch sw, {
    required bool success,
    int? code,
    Object? error,
  }) {
    final d = sw.elapsed;
    String label;
    if (error != null) {
      label = error.toString().contains('TimeoutException')
          ? 'timeout · ${d.inSeconds}s'
          : 'error · ${error.runtimeType}';
    } else if (code == 200) {
      final ms = d.inMilliseconds;
      label = ms >= 1000
          ? '200 · ${(ms / 1000).toStringAsFixed(1)}s'
          : '200 · ${ms}ms';
    } else {
      label = '${code ?? 'fail'} · ${d.inSeconds}s';
    }
    ApiDiagnostics.record(ApiAttempt(
      endpoint: _endpointLabel,
      statusLabel: label,
      success: success,
      at: DateTime.now(),
      source: ApiSource.weather,
    ));
  }
}
