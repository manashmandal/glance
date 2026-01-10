class WeatherData {
  final double temperature;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;
  // New fields for AI context
  final double? precipitationProbability;
  final double? windSpeed;
  final double? humidity;
  final List<HourlyForecast>? hourlyForecast;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
    this.precipitationProbability,
    this.windSpeed,
    this.humidity,
    this.hourlyForecast,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];
    final hourly = json['hourly'];

    List<HourlyForecast>? hourlyList;
    if (hourly != null) {
      final times = hourly['time'] as List?;
      final temps = hourly['temperature_2m'] as List?;
      final codes = hourly['weather_code'] as List?;
      final precip = hourly['precipitation_probability'] as List?;

      if (times != null && temps != null) {
        hourlyList = [];
        // Get next 12 hours
        final limit = times.length > 12 ? 12 : times.length;
        for (int i = 0; i < limit; i++) {
          hourlyList.add(HourlyForecast(
            time: DateTime.parse(times[i]),
            temperature: temps[i]?.toDouble() ?? 0.0,
            weatherCode: codes?[i]?.toInt() ?? 0,
            precipitationProbability: precip?[i]?.toDouble(),
          ));
        }
      }
    }

    return WeatherData(
      temperature: current['temperature_2m']?.toDouble() ?? 0.0,
      weatherCode: current['weather_code']?.toInt() ?? 0,
      maxTemp: daily['temperature_2m_max']?[0]?.toDouble() ?? 0.0,
      minTemp: daily['temperature_2m_min']?[0]?.toDouble() ?? 0.0,
      precipitationProbability: current['precipitation_probability']?.toDouble(),
      windSpeed: current['wind_speed_10m']?.toDouble(),
      humidity: current['relative_humidity_2m']?.toDouble(),
      hourlyForecast: hourlyList,
    );
  }

  String get weatherDescription {
    switch (weatherCode) {
      case 0:
        return 'Clear sky';
      case 1:
      case 2:
      case 3:
        return 'Partly cloudy';
      case 45:
      case 48:
        return 'Foggy';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }

  /// Generate a text summary for AI processing
  String toAiContextString() {
    final buffer = StringBuffer();
    buffer.writeln('Current weather conditions:');
    buffer.writeln('- Temperature: ${temperature.round()}°C');
    buffer.writeln('- Condition: $weatherDescription');
    buffer.writeln('- High/Low: ${maxTemp.round()}°C / ${minTemp.round()}°C');
    if (precipitationProbability != null) {
      buffer.writeln('- Precipitation chance: ${precipitationProbability!.round()}%');
    }
    if (windSpeed != null) {
      buffer.writeln('- Wind speed: ${windSpeed!.round()} km/h');
    }
    if (humidity != null) {
      buffer.writeln('- Humidity: ${humidity!.round()}%');
    }
    if (hourlyForecast != null && hourlyForecast!.isNotEmpty) {
      buffer.writeln('Next few hours:');
      for (final hour in hourlyForecast!.take(6)) {
        buffer.writeln('- ${hour.time.hour}:00: ${hour.temperature.round()}°C, ${hour.weatherCodeDescription}');
      }
    }
    return buffer.toString();
  }
}

class HourlyForecast {
  final DateTime time;
  final double temperature;
  final int weatherCode;
  final double? precipitationProbability;

  HourlyForecast({
    required this.time,
    required this.temperature,
    required this.weatherCode,
    this.precipitationProbability,
  });

  String get weatherCodeDescription {
    switch (weatherCode) {
      case 0:
        return 'Clear';
      case 1:
      case 2:
      case 3:
        return 'Cloudy';
      case 45:
      case 48:
        return 'Fog';
      case 51:
      case 53:
      case 55:
        return 'Drizzle';
      case 61:
      case 63:
      case 65:
        return 'Rain';
      case 71:
      case 73:
      case 75:
        return 'Snow';
      case 95:
      case 96:
      case 99:
        return 'Thunderstorm';
      default:
        return 'Unknown';
    }
  }
}
