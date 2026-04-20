import 'package:flutter/material.dart';
import '../../data/family_placeholders.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/station_dot.dart';
import 'common/tiny_dot_separator.dart';

/// Two-row preview: the partner's travel hint (arrow + time + name +
/// "leave by 2:45") sitting above a rail of stations connected by
/// dashed-style dividers.
class RoutePreview extends StatelessWidget {
  final RouteHint hint;
  final List<RouteStop> stops;

  const RoutePreview({super.key, required this.hint, required this.stops});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _EventStrip(hint: hint),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.only(top: 2),
          child: _RouteRail(stops: stops),
        ),
      ],
    );
  }
}

class _EventStrip extends StatelessWidget {
  final RouteHint hint;
  const _EventStrip({required this.hint});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text(
          '→',
          style: FamilyType.routeEvent(color: FamilyPalette.textSecondary),
        ),
        const SizedBox(width: 10),
        Text(
          hint.departureTime,
          style: FamilyType.routeEvent(
            color: FamilyPalette.textPrimary,
            weight: FontWeight.w600,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          hint.personName,
          style: FamilyType.routeEvent(color: FamilyPalette.textPrimary),
        ),
        const SizedBox(width: 10),
        const TinyDotSeparator(),
        const SizedBox(width: 10),
        Text(
          hint.destinationArea,
          style: FamilyType.routeEvent(color: FamilyPalette.textSecondary),
        ),
        const SizedBox(width: 10),
        const TinyDotSeparator(),
        const SizedBox(width: 10),
        Text(
          hint.leaveBy,
          style: FamilyType.routeEvent(
            color: FamilyPalette.crimson,
            weight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _RouteRail extends StatelessWidget {
  final List<RouteStop> stops;
  const _RouteRail({required this.stops});

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < stops.length; i++) {
      final stop = stops[i];
      children.add(_RailStop(stop: stop));
      if (i < stops.length - 1) {
        final isLastLeg = i == stops.length - 2;
        children.add(Expanded(child: _RailConnector(accent: isLastLeg)));
      }
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
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
