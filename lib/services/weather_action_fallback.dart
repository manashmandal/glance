import '../models/weather_data.dart';
import '../models/weather_action.dart';

/// Generates weather actions using rule-based logic (fallback when AI unavailable)
class WeatherActionFallback {
  static WeatherAction generate(WeatherData weather) {
    final actions = <String>[];

    // Temperature-based recommendations
    if (weather.temperature < 0) {
      actions.add('Bundle up! It\'s freezing outside');
    } else if (weather.temperature < 10) {
      actions.add('Wear a warm jacket today');
    } else if (weather.temperature > 30) {
      actions.add('Stay hydrated in the heat');
    }

    // Weather code-based recommendations
    switch (weather.weatherCode) {
      case 51:
      case 53:
      case 55: // Drizzle
        actions.add('Light rain expected - bring an umbrella');
        break;
      case 61:
      case 63:
      case 65: // Rain
        actions.add('Take an umbrella - rain expected');
        break;
      case 71:
      case 73:
      case 75: // Snow
        actions.add('Snow today - dress warmly and wear appropriate footwear');
        break;
      case 95:
      case 96:
      case 99: // Thunderstorm
        actions.add('Thunderstorms expected - stay indoors if possible');
        break;
      case 45:
      case 48: // Fog
        actions.add('Foggy conditions - drive carefully');
        break;
    }

    // Precipitation probability
    if (weather.precipitationProbability != null &&
        weather.precipitationProbability! > 50) {
      if (!actions.any((a) => a.contains('umbrella'))) {
        actions.add('High chance of precipitation - umbrella recommended');
      }
    }

    // Wind speed
    if (weather.windSpeed != null && weather.windSpeed! > 40) {
      actions.add('Strong winds today - secure loose items');
    }

    // Check hourly forecast for changes
    if (weather.hourlyForecast != null && weather.hourlyForecast!.isNotEmpty) {
      final hasRainLater = weather.hourlyForecast!
          .any((h) => [51, 53, 55, 61, 63, 65].contains(h.weatherCode));
      if (hasRainLater && !actions.any((a) => a.contains('umbrella'))) {
        actions.add('Rain expected later - take an umbrella');
      }
    }

    // Default if no specific actions
    if (actions.isEmpty) {
      if (weather.weatherCode == 0) {
        actions.add('Perfect weather - enjoy your day!');
      } else {
        actions.add('Have a great day!');
      }
    }

    // Return the most relevant action (first one)
    return WeatherAction.fallback(
      actions.first,
      icon: _getIconForAction(actions.first),
    );
  }

  static String? _getIconForAction(String action) {
    final lowerAction = action.toLowerCase();
    if (lowerAction.contains('umbrella')) return 'umbrella';
    if (lowerAction.contains('warm') ||
        lowerAction.contains('jacket') ||
        lowerAction.contains('freezing')) return 'cold';
    if (lowerAction.contains('heat') || lowerAction.contains('hydrated'))
      return 'hot';
    if (lowerAction.contains('snow')) return 'snow';
    if (lowerAction.contains('thunder')) return 'storm';
    if (lowerAction.contains('wind')) return 'wind';
    if (lowerAction.contains('fog')) return 'fog';
    return 'sun';
  }
}
