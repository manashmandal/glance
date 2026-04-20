import 'package:flutter/material.dart';
import '../../data/family_placeholders.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/station_dot.dart';

/// "Upcoming" section: a header with section label and a transit-mode
/// switcher, then a list of departure rows.
class UpcomingList extends StatelessWidget {
  final List<DepartureItem> departures;
  final TransitKind activeKind;
  final ValueChanged<TransitKind>? onKindSelected;

  const UpcomingList({
    super.key,
    required this.departures,
    required this.activeKind,
    this.onKindSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _Header(activeKind: activeKind, onKindSelected: onKindSelected),
        const SizedBox(height: 12),
        for (final departure in departures) _DepartureRow(item: departure),
      ],
    );
  }
}

class _Header extends StatelessWidget {
  final TransitKind activeKind;
  final ValueChanged<TransitKind>? onKindSelected;

  const _Header({required this.activeKind, required this.onKindSelected});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Text('UPCOMING', style: FamilyType.sectionLabel()),
        const Spacer(),
        _SwitcherEntry(
          kind: TransitKind.regional,
          label: 'Regional',
          active: activeKind == TransitKind.regional,
          onTap: onKindSelected,
          showDot: true,
        ),
        const SizedBox(width: 18),
        _SwitcherEntry(
          kind: TransitKind.sBahn,
          label: 'S-Bahn',
          active: activeKind == TransitKind.sBahn,
          onTap: onKindSelected,
        ),
        const SizedBox(width: 18),
        _SwitcherEntry(
          kind: TransitKind.uBahn,
          label: 'U-Bahn',
          active: activeKind == TransitKind.uBahn,
          onTap: onKindSelected,
        ),
        const SizedBox(width: 18),
        _SwitcherEntry(
          kind: TransitKind.bus,
          label: 'Bus',
          active: activeKind == TransitKind.bus,
          onTap: onKindSelected,
        ),
      ],
    );
  }
}

class _SwitcherEntry extends StatelessWidget {
  final TransitKind kind;
  final String label;
  final bool active;
  final bool showDot;
  final ValueChanged<TransitKind>? onTap;

  const _SwitcherEntry({
    required this.kind,
    required this.label,
    required this.active,
    this.showDot = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(6),
      onTap: onTap == null ? null : () => onTap!(kind),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (showDot || active) ...[
              StationDot(
                color: active
                    ? FamilyPalette.crimson
                    : FamilyPalette.textTertiary,
                size: 6,
              ),
              const SizedBox(width: 6),
            ],
            Text(label, style: FamilyType.switcherEntry(active: active)),
          ],
        ),
      ),
    );
  }
}

class _DepartureRow extends StatelessWidget {
  final DepartureItem item;
  const _DepartureRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: FamilyPalette.divider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(item.time, style: FamilyType.upcomingTime()),
          const SizedBox(width: 20),
          Expanded(
            child: Text(
              item.destination,
              style: FamilyType.upcomingName(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 64,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                StationDot(color: item.lineColor, size: 6),
                const SizedBox(width: 6),
                Text(item.lineCode, style: FamilyType.upcomingLineCode()),
              ],
            ),
          ),
          SizedBox(
            width: 100,
            child: Text(
              item.statusText,
              style: item.isDelayed
                  ? FamilyType.statusDelay()
                  : FamilyType.statusOnTime(),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
