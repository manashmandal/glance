class WeatherData {
  final double temperature;
  final int weatherCode;
  final double maxTemp;
  final double minTemp;

  WeatherData({
    required this.temperature,
    required this.weatherCode,
    required this.maxTemp,
    required this.minTemp,
  });

  factory WeatherData.fromJson(Map<String, dynamic> json) {
    final current = json['current'];
    final daily = json['daily'];

    return WeatherData(
      temperature: current['temperature_2m']?.toDouble() ?? 0.0,
      weatherCode: current['weather_code']?.toInt() ?? 0,
      maxTemp: daily['temperature_2m_max']?[0]?.toDouble() ?? 0.0,
      minTemp: daily['temperature_2m_min']?[0]?.toDouble() ?? 0.0,
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
}
