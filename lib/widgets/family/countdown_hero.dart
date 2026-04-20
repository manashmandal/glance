import 'package:flutter/material.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/tiny_dot_separator.dart';

/// The giant "in N min" countdown plus the small "LEAVE BY 2:36 · WALK 4'"
/// supporting row underneath.
class CountdownHero extends StatelessWidget {
  final int minutes;
  final String leaveByTime;
  final String walkDuration;

  const CountdownHero({
    super.key,
    required this.minutes,
    required this.leaveByTime,
    required this.walkDuration,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 260,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          _Number(minutes: minutes),
          const SizedBox(height: 14),
          _LeaveByRow(leaveByTime: leaveByTime, walkDuration: walkDuration),
        ],
      ),
    );
  }
}

class _Number extends StatelessWidget {
  final int minutes;
  const _Number({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('in', style: FamilyType.countdownLabel()),
        const SizedBox(width: 16),
        Text('$minutes', style: FamilyType.countdownNumber()),
        const SizedBox(width: 16),
        Text('min', style: FamilyType.countdownLabel()),
      ],
    );
  }
}

class _LeaveByRow extends StatelessWidget {
  final String leaveByTime;
  final String walkDuration;
  const _LeaveByRow({required this.leaveByTime, required this.walkDuration});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text('LEAVE BY', style: FamilyType.metaCaps()),
        const SizedBox(width: 10),
        Text(leaveByTime, style: FamilyType.leaveByTime()),
        const SizedBox(width: 10),
        const TinyDotSeparator(),
        const SizedBox(width: 10),
        Text(
          'WALK $walkDuration',
          style: FamilyType.metaCaps(color: FamilyPalette.textSecondary),
        ),
      ],
    );
  }
}
