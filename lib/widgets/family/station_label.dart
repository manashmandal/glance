import 'package:flutter/material.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/station_dot.dart';

/// The large current-station label under the brand signature
/// (e.g. a sage dot + "S+U Alexanderplatz").
class StationLabel extends StatelessWidget {
  final String stationName;

  const StationLabel({super.key, required this.stationName});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        const StationDot(color: FamilyPalette.sage, size: 9),
        const SizedBox(width: 10),
        Text(stationName, style: FamilyType.stationLarge()),
      ],
    );
  }
}
