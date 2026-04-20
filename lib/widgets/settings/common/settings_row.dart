import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// Horizontal row used inside each settings pane: a heading + description
/// on the left and an arbitrary control on the right.
///
/// Optionally renders a divider above itself (used for repeated rows).
class SettingsRow extends StatelessWidget {
  final String title;
  final String description;
  final Widget control;
  final Widget? trailingBadge;
  final bool showDivider;
  final CrossAxisAlignment alignment;

  const SettingsRow({
    super.key,
    required this.title,
    required this.description,
    required this.control,
    this.trailingBadge,
    this.showDivider = true,
    this.alignment = CrossAxisAlignment.center,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 22),
      decoration: showDivider
          ? const BoxDecoration(
              border: Border(
                top: BorderSide(color: FamilyPalette.divider, width: 1),
              ),
            )
          : null,
      child: Row(
        crossAxisAlignment: alignment,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(title, style: FamilyType.sectionTitle()),
                    if (trailingBadge != null) ...[
                      const SizedBox(width: 10),
                      trailingBadge!,
                    ],
                  ],
                ),
                const SizedBox(height: 6),
                Text(description, style: FamilyType.sectionDescription()),
              ],
            ),
          ),
          const SizedBox(width: 24),
          control,
        ],
      ),
    );
  }
}
