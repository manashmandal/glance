import 'package:flutter/material.dart';
import '../../theme/family_palette.dart';
import '../../theme/family_typography.dart';
import 'common/brand_mark.dart';
import 'common/tiny_dot_separator.dart';
import 'common/update_badge.dart';

/// Top-left signature: brand mark, "glance." wordmark, version meta,
/// and an optional update badge.
class BrandSignature extends StatelessWidget {
  final String version;
  final String commit;
  final String? availableVersion;
  final VoidCallback? onUpdateTap;

  const BrandSignature({
    super.key,
    required this.version,
    required this.commit,
    this.availableVersion,
    this.onUpdateTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        const BrandMark(),
        const SizedBox(width: 14),
        _Wordmark(),
        const SizedBox(width: 20),
        Text(version, style: FamilyType.metaMono()),
        const SizedBox(width: 8),
        const TinyDotSeparator(color: FamilyPalette.divider),
        const SizedBox(width: 8),
        Text(commit, style: FamilyType.metaMono()),
        if (availableVersion != null) ...[
          const SizedBox(width: 10),
          UpdateBadge(version: availableVersion!, onTap: onUpdateTap),
        ],
      ],
    );
  }
}

class _Wordmark extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('glance', style: FamilyType.brandWordmark()),
        const SizedBox(width: 3),
        Container(
          width: 8,
          height: 8,
          margin: const EdgeInsets.only(bottom: 3),
          decoration: const BoxDecoration(
            color: FamilyPalette.crimson,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(color: FamilyPalette.crimsonGlow, blurRadius: 12),
            ],
          ),
        ),
      ],
    );
  }
}
