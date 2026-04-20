import 'package:flutter/material.dart';
import '../models/journey.dart';
import '../models/route_stop.dart';
import '../models/train_departure.dart';
import '../models/weather_data.dart';
import '../theme/family_palette.dart';
import 'family_placeholders.dart';

/// Adapters that project service-layer models (TrainDeparture, WeatherData)
/// onto the view-model types consumed by the Family Dashboard widgets.
class FamilyAdapters {
  const FamilyAdapters._();

  /// Turn a list of BVG departures into display-ready rows. The line
  /// color is remapped into the night palette (crimson for the next /
  /// hero line, neutral grays for others) rather than using the
  /// multi-colored BVG line colors, which clash with the mood.
  static List<DepartureItem> departureItems(
    List<TrainDeparture> source, {
    String? highlightLine,
  }) {
    return source.map((d) {
      final isDelayed = (d.delay ?? 0) > 0;
      final isHighlighted =
          highlightLine != null && d.line == highlightLine;
      return DepartureItem(
        time: _shortTime(d.departureTime) ?? d.time,
        destination: d.destination,
        lineCode: d.line,
        lineColor: isHighlighted
            ? FamilyPalette.crimson
            : FamilyPalette.textPrimary.withValues(
                alpha: isDelayed ? 0.55 : 0.85,
              ),
        statusText: isDelayed ? "+${((d.delay ?? 0) / 60).round()}'" : 'On time',
        isDelayed: isDelayed,
      );
    }).toList(growable: false);
  }

  /// Hero countdown minutes based on the first actionable departure.
  static int? countdownMinutes(TrainDeparture? next) {
    if (next?.departureTime == null) return null;
    final diff = next!.departureTime!.difference(DateTime.now()).inMinutes;
    return diff < 0 ? 0 : diff;
  }

  /// "Leave by" time = departure time − walk duration.
  static String? leaveByTime(TrainDeparture? next, int walkMinutes) {
    if (next?.departureTime == null) return null;
    final leaveAt = next!.departureTime!.subtract(Duration(minutes: walkMinutes));
    return _shortTime(leaveAt);
  }

  /// Normalize the BVG "Pl. 3" platform string into just the platform
  /// number (or null if absent). Kept in the adapter so the dashboard
  /// stays a pure renderer.
  static String? displayPlatform(TrainDeparture? next) {
    final raw = next?.platform;
    if (raw == null) return null;
    final cleaned =
        raw.replaceFirst('Pl. ', '').replaceFirst('Pl.', '').trim();
    return cleaned.isEmpty ? null : cleaned;
  }

  /// Builds rail stops from a journey: origin of the first transit leg,
  /// then each non-walking leg's destination, deduped by id. The first
  /// stop is marked current; the last, destination. Returns `const []`
  /// if the journey is null, has no transit legs, or collapses to fewer
  /// than two unique stops.
  static List<RouteStop> routeStops(Journey? journey) {
    if (journey == null) return const [];
    final transit =
        journey.legs.where((l) => !l.walking).toList(growable: false);
    if (transit.isEmpty) return const [];

    final ids = <String>{};
    final names = <String>[];

    void addStop(String id, String name) {
      if (id.isEmpty || !ids.add(id)) return;
      names.add(_shortStationName(name));
    }

    addStop(transit.first.originId, transit.first.originName);
    for (final leg in transit) {
      addStop(leg.destinationId, leg.destinationName);
    }
    if (names.length < 2) return const [];

    return [
      RouteStop(name: names.first, role: RouteStopRole.current),
      for (var i = 1; i < names.length - 1; i++) RouteStop(name: names[i]),
      RouteStop(name: names.last, role: RouteStopRole.destination),
    ];
  }

  static String _shortStationName(String raw) {
    var name = raw.trim();
    name = name.replaceAll(RegExp(r'\s*\(Berlin[^)]*\)\s*$'), '');
    name = name.replaceAll(RegExp(r'\s+Bhf$'), '');
    return name.trim();
  }

  /// Translate hourly forecast into compact strip points.
  static List<ForecastPoint> forecastPoints(WeatherData? weather) {
    final hours = weather?.hourlyForecast;
    if (hours == null || hours.isEmpty) return FamilyPlaceholders.forecast;

    final now = DateTime.now();
    final points = <ForecastPoint>[];
    final offsets = [0, 2, 4, 6, 8];
    for (final offset in offsets) {
      final target = now.add(Duration(hours: offset));
      final match = _closestForecast(hours, target);
      if (match == null) continue;
      final icon = _iconForCode(match.weatherCode);
      final isPrecip = _isPrecipCode(match.weatherCode);
      points.add(
        ForecastPoint(
          label: offset == 0 ? 'Now' : _hourLabel(target),
          temp: '${match.temperature.round()}°',
          icon: icon,
          iconColor:
              isPrecip ? FamilyPalette.crimson : FamilyPalette.textSecondary,
        ),
      );
    }
    return points.isEmpty ? FamilyPlaceholders.forecast : points;
  }

  /// Take the one-line condition summary off of a weather sample.
  static String weatherCondition(WeatherData? weather) {
    if (weather == null) return FamilyPlaceholders.weatherCondition;
    final description = weather.weatherDescription;
    final precip = weather.precipitationProbability;
    if (precip != null && precip >= 50) {
      final next = _nextPrecipHour(weather.hourlyForecast);
      if (next != null) {
        return '$description · rain around ${_hourLabel(next)}';
      }
    }
    return description;
  }

  /// Short time format "h:mm" (no AM/PM).
  static String? _shortTime(DateTime? time) {
    if (time == null) return null;
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    return '$hour:${time.minute.toString().padLeft(2, '0')}';
  }

  static String _hourLabel(DateTime time) {
    final hour = time.hour > 12
        ? time.hour - 12
        : (time.hour == 0 ? 12 : time.hour);
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour $suffix';
  }

  static HourlyForecast? _closestForecast(
    List<HourlyForecast> hours,
    DateTime target,
  ) {
    HourlyForecast? best;
    var bestDelta = const Duration(days: 1);
    for (final h in hours) {
      final delta = h.time.difference(target).abs();
      if (delta < bestDelta) {
        best = h;
        bestDelta = delta;
      }
    }
    return best;
  }

  static DateTime? _nextPrecipHour(List<HourlyForecast>? hours) {
    if (hours == null) return null;
    final now = DateTime.now();
    for (final h in hours) {
      if (h.time.isBefore(now)) continue;
      if (_isPrecipCode(h.weatherCode) ||
          (h.precipitationProbability ?? 0) >= 50) {
        return h.time;
      }
    }
    return null;
  }

  static bool _isPrecipCode(int code) {
    return (code >= 51 && code <= 67) ||
        (code >= 80 && code <= 99) ||
        (code >= 71 && code <= 77);
  }

  static IconData _iconForCode(int code) {
    if (code == 0) return Icons.wb_sunny_outlined;
    if (code >= 1 && code <= 3) return Icons.cloud_outlined;
    if (code == 45 || code == 48) return Icons.blur_on;
    if (code >= 51 && code <= 67) return Icons.grain;
    if (code >= 71 && code <= 77) return Icons.ac_unit;
    if (code >= 80 && code <= 82) return Icons.grain;
    if (code >= 95) return Icons.thunderstorm_outlined;
    return Icons.cloud_outlined;
  }
}
