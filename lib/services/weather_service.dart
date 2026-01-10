import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  // Berlin coordinates (using default for now as per request)
  static const double _lat = 52.52;
  static const double _lng = 13.41;
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  static Future<WeatherData> getWeather() async {
    try {
      const url = '$_baseUrl'
          '?latitude=$_lat'
          '&longitude=$_lng'
          '&current=temperature_2m,weather_code,precipitation_probability,wind_speed_10m,relative_humidity_2m'
          '&hourly=temperature_2m,weather_code,precipitation_probability'
          '&daily=temperature_2m_max,temperature_2m_min'
          '&timezone=auto'
          '&forecast_hours=12';

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }
}
