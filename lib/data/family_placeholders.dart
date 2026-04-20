import 'package:flutter/material.dart';
import '../theme/family_palette.dart';

/// Static placeholder data for the Family Dashboard.
///
/// Eventually these should be replaced by real services — calendar for
/// events, a route service for the preview rail, the existing BVG service
/// for departures, and the weather service for the forecast strip.

enum TransitKind { regional, sBahn, uBahn, bus }

class DepartureItem {
  final String time;
  final String destination;
  final String lineCode;
  final Color lineColor;
  final String statusText;
  final bool isDelayed;

  const DepartureItem({
    required this.time,
    required this.destination,
    required this.lineCode,
    required this.lineColor,
    required this.statusText,
    this.isDelayed = false,
  });
}

class ForecastPoint {
  final String label;
  final String temp;
  final IconData icon;
  final Color iconColor;

  const ForecastPoint({
    required this.label,
    required this.temp,
    required this.icon,
    required this.iconColor,
  });
}

class PartnerEvent {
  final String person;
  final String label;
  final String title;
  final String timeRange;
  final Color accent;

  const PartnerEvent({
    required this.person,
    required this.label,
    required this.title,
    required this.timeRange,
    required this.accent,
  });
}

class FamilyPlaceholders {
  const FamilyPlaceholders._();

  static const String version = 'v0.1.0';
  static const String commit = '18bf';
  static const String availableVersion = 'v0.2.0';

  static const String currentStationName = 'S+U Alexanderplatz';
  static const String destinationName = 'Flughafen BER';
  static const int countdownMinutes = 8;
  static const String leaveByTime = '2:36';
  static const String walkDuration = '4′';

  static const PartnerEvent upNext = PartnerEvent(
    person: 'Anna',
    label: 'Up next',
    title: 'Team review with Clara',
    timeRange: '3:00 – 4:30',
    accent: FamilyPalette.crimsonWarm,
  );

  static const String nextLineCode = 'RE8';
  static const String nextLineCategory = 'Regional';
  static const String nextPlatform = '1';

  static const List<DepartureItem> upcoming = [
    DepartureItem(
      time: '2:59',
      destination: 'Lübben, Bahnhof',
      lineCode: 'RE7',
      lineColor: FamilyPalette.textPrimary,
      statusText: "+6'",
      isDelayed: true,
    ),
    DepartureItem(
      time: '3:14',
      destination: 'Flughafen BER',
      lineCode: 'RE8',
      lineColor: FamilyPalette.crimson,
      statusText: 'On time',
    ),
    DepartureItem(
      time: '3:22',
      destination: 'Wünsdorf-Waldstadt',
      lineCode: 'RE3',
      lineColor: FamilyPalette.textTertiary,
      statusText: 'On time',
    ),
    DepartureItem(
      time: '3:38',
      destination: 'Senftenberg',
      lineCode: 'RE2',
      lineColor: FamilyPalette.textPrimary,
      statusText: 'On time',
    ),
  ];

  static const String weatherLocation = 'Berlin · Mitte';
  static const String currentTemp = '4';
  static const String weatherCondition = 'Partly cloudy · light rain at 6 PM';
  static const String weatherTip =
      'Light jacket. Bring an umbrella for the 6 PM shower.';

  static const List<ForecastPoint> forecast = [
    ForecastPoint(
      label: 'Now',
      temp: '4°',
      icon: Icons.cloud_outlined,
      iconColor: FamilyPalette.textSecondary,
    ),
    ForecastPoint(
      label: '4 PM',
      temp: '3°',
      icon: Icons.cloud_outlined,
      iconColor: FamilyPalette.textSecondary,
    ),
    ForecastPoint(
      label: '6 PM',
      temp: '2°',
      icon: Icons.grain,
      iconColor: FamilyPalette.crimson,
    ),
    ForecastPoint(
      label: '8 PM',
      temp: '2°',
      icon: Icons.grain,
      iconColor: FamilyPalette.crimson,
    ),
    ForecastPoint(
      label: '10 PM',
      temp: '1°',
      icon: Icons.wb_sunny_outlined,
      iconColor: FamilyPalette.textSecondary,
    ),
  ];
}
