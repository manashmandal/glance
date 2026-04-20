import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';

/// Small circular indicator used throughout the dashboard for stations,
/// calendar events, and upcoming-departure line codes.
///
/// - [filled] solid fill with an optional glow ring
/// - [outlined] hollow circle with a border (intermediate stations)
class StationDot extends StatelessWidget {
  final double size;
  final Color color;
  final bool filled;
  final bool glow;

  const StationDot({
    super.key,
    required this.color,
    this.size = 9,
    this.filled = true,
    this.glow = false,
  });

  const StationDot.outlined({super.key, required this.color, this.size = 7})
      : filled = false,
        glow = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: filled ? color : FamilyPalette.background,
        shape: BoxShape.circle,
        border: filled ? null : Border.all(color: color, width: 1.5),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.18),
                  spreadRadius: 3,
                ),
              ]
            : null,
      ),
    );
  }
}
