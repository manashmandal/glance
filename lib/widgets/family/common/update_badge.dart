import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// Amber "update available" pill shown in the brand signature.
class UpdateBadge extends StatelessWidget {
  final String version;
  final VoidCallback? onTap;

  const UpdateBadge({super.key, required this.version, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(999),
        child: Container(
          height: 18,
          padding: const EdgeInsets.symmetric(horizontal: 7.5, vertical: 2),
          decoration: BoxDecoration(
            color: FamilyPalette.amberTint,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: FamilyPalette.amberBorder, width: 1),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.arrow_upward_rounded,
                size: 9,
                color: FamilyPalette.amberBright,
              ),
              const SizedBox(width: 5),
              Text(
                version,
                style:
                    FamilyType.metaMono(color: FamilyPalette.amberBright),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
