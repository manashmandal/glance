import 'package:flutter/material.dart';
import '../../models/route_stop.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/station_dot.dart';

/// Horizontal rail of stations connected by dividers. Stops flagged
/// `current` render with a sage dot, `destination` with a crimson dot;
/// intermediate stops use an outlined neutral dot. The connector before
/// the destination is tinted crimson.
class RoutePreview extends StatelessWidget {
  final List<RouteStop> stops;

  const RoutePreview({super.key, required this.stops});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stops.length; i++) {
      children.add(_RailStop(stop: stops[i]));
      if (i < stops.length - 1) {
        final isLastLeg = i == stops.length - 2;
        children.add(Expanded(child: _RailConnector(accent: isLastLeg)));
      }
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: children,
    );
  }
}

class _RailStop extends StatelessWidget {
  final RouteStop stop;
  const _RailStop({required this.stop});

  @override
  Widget build(BuildContext context) {
    final emphasised = stop.isCurrent || stop.isDestination;
    final dot = stop.isCurrent
        ? const StationDot(
            color: FamilyPalette.sage,
            size: 9,
            glow: true,
          )
        : stop.isDestination
            ? const StationDot(
                color: FamilyPalette.crimson,
                size: 9,
                glow: true,
              )
            : const StationDot.outlined(color: FamilyPalette.textTertiary);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        dot,
        const SizedBox(width: 8),
        Text(
          stop.name,
          style: FamilyType.routeStation(
            color: emphasised
                ? FamilyPalette.textPrimary
                : FamilyPalette.textSecondary,
            bold: emphasised,
          ),
        ),
      ],
    );
  }
}

class _RailConnector extends StatelessWidget {
  final bool accent;
  const _RailConnector({required this.accent});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 1,
        color: accent
            ? FamilyPalette.crimson.withValues(alpha: 0.4)
            : FamilyPalette.divider,
      ),
    );
  }
}
