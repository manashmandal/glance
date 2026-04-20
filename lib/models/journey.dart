class JourneyLeg {
  final String originId;
  final String originName;
  final String destinationId;
  final String destinationName;
  final DateTime? departure;
  final DateTime? arrival;
  final String? lineName;
  final bool walking;

  const JourneyLeg({
    required this.originId,
    required this.originName,
    required this.destinationId,
    required this.destinationName,
    this.departure,
    this.arrival,
    this.lineName,
    this.walking = false,
  });

  factory JourneyLeg.fromJson(Map<String, dynamic> json) {
    final origin = json['origin'] as Map<String, dynamic>?;
    final destination = json['destination'] as Map<String, dynamic>?;
    final line = json['line'] as Map<String, dynamic>?;
    return JourneyLeg(
      originId: origin?['id'] as String? ?? '',
      originName: origin?['name'] as String? ?? '',
      destinationId: destination?['id'] as String? ?? '',
      destinationName: destination?['name'] as String? ?? '',
      departure: _parseTime(json['departure'] ?? json['plannedDeparture']),
      arrival: _parseTime(json['arrival'] ?? json['plannedArrival']),
      lineName: line?['name'] as String?,
      walking: json['walking'] == true,
    );
  }

  static DateTime? _parseTime(Object? value) {
    if (value is! String || value.isEmpty) return null;
    try {
      return DateTime.parse(value).toLocal();
    } catch (_) {
      return null;
    }
  }
}

class Journey {
  final List<JourneyLeg> legs;

  const Journey({required this.legs});

  factory Journey.fromJson(Map<String, dynamic> json) {
    final rawLegs = json['legs'] as List? ?? const [];
    return Journey(
      legs: rawLegs
          .whereType<Map<String, dynamic>>()
          .map(JourneyLeg.fromJson)
          .toList(growable: false),
    );
  }

  DateTime? get departure {
    for (final leg in legs) {
      if (leg.departure != null) return leg.departure;
    }
    return null;
  }
}
