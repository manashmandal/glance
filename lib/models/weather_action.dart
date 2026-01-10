/// Represents an AI-generated weather action/recommendation
class WeatherAction {
  final String action;
  final String? icon;
  final DateTime generatedAt;
  final WeatherActionSource source;

  WeatherAction({
    required this.action,
    this.icon,
    required this.generatedAt,
    required this.source,
  });

  factory WeatherAction.fallback(String action, {String? icon}) {
    return WeatherAction(
      action: action,
      icon: icon,
      generatedAt: DateTime.now(),
      source: WeatherActionSource.ruleBased,
    );
  }

  factory WeatherAction.fromAi(String action, {String? icon}) {
    return WeatherAction(
      action: action,
      icon: icon,
      generatedAt: DateTime.now(),
      source: WeatherActionSource.aiGenerated,
    );
  }

  bool get isStale {
    // Consider action stale after 30 minutes
    return DateTime.now().difference(generatedAt).inMinutes > 30;
  }
}

enum WeatherActionSource {
  aiGenerated,
  ruleBased,
}
