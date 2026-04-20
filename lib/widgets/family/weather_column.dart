import 'package:flutter/material.dart';
import '../../data/family_placeholders.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';

/// Weather side column: a horizontal "next 8 hours" strip of forecast
/// points, the current temperature, a one-line condition, and an italic
/// advisory tip highlighted by a crimson rule.
class WeatherColumn extends StatelessWidget {
  final String location;
  final String currentTemp;
  final String condition;
  final String tip;
  final List<ForecastPoint> forecast;

  const WeatherColumn({
    super.key,
    required this.location,
    required this.currentTemp,
    required this.condition,
    required this.tip,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _ForecastStrip(location: location, forecast: forecast),
        const SizedBox(height: 10),
        _CurrentAndTip(
          currentTemp: currentTemp,
          condition: condition,
          tip: tip,
        ),
      ],
    );
  }
}

class _ForecastStrip extends StatelessWidget {
  final String location;
  final List<ForecastPoint> forecast;
  const _ForecastStrip({required this.location, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 2, bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('NEXT 8 HOURS', style: FamilyType.metaCaps()),
              Text(
                location,
                style: FamilyType.metaCaps(color: FamilyPalette.textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [for (final p in forecast) _ForecastCell(point: p)],
          ),
        ],
      ),
    );
  }
}

class _ForecastCell extends StatelessWidget {
  final ForecastPoint point;
  const _ForecastCell({required this.point});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 54,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(point.label.toUpperCase(), style: FamilyType.forecastHour()),
          const SizedBox(height: 6),
          Icon(point.icon, color: point.iconColor, size: 18),
          const SizedBox(height: 6),
          Text(point.temp, style: FamilyType.forecastTemp()),
        ],
      ),
    );
  }
}

class _CurrentAndTip extends StatelessWidget {
  final String currentTemp;
  final String condition;
  final String tip;

  const _CurrentAndTip({
    required this.currentTemp,
    required this.condition,
    required this.tip,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(top: 6),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: FamilyPalette.divider, width: 1),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(currentTemp, style: FamilyType.tempLarge()),
              const SizedBox(width: 4),
              Text('°', style: FamilyType.tempDegree()),
            ],
          ),
          const SizedBox(height: 8),
          Text(condition, style: FamilyType.weatherCondition()),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.only(top: 10),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: FamilyPalette.divider, width: 1),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 3,
                  height: 16,
                  margin: const EdgeInsets.only(top: 6),
                  color: FamilyPalette.crimson,
                ),
                const SizedBox(width: 10),
                Expanded(child: Text(tip, style: FamilyType.weatherTip())),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
