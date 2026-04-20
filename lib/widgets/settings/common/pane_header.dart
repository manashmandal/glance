import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// The three-line header at the top of every settings pane:
/// caps eyebrow, big title, italic subtitle. An optional trailing slot
/// (e.g. "MOUNTED IN Kitchen · Always-on") sits on the right.
class PaneHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String subtitle;
  final Widget? trailing;

  const PaneHeader({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                eyebrow.toUpperCase(),
                style: FamilyType.settingsEyebrow(color: FamilyPalette.crimson),
              ),
              const SizedBox(height: 10),
              Text(title, style: FamilyType.settingsTitle()),
              const SizedBox(height: 10),
              Text(subtitle, style: FamilyType.settingsSubtitle()),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}
