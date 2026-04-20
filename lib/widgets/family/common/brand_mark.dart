import 'package:flutter/material.dart';
import '../../../theme/family_palette.dart';

/// The small horizontal line with a red dot sitting at the start of the
/// "glance." wordmark. Just a purely decorative mark.
class BrandMark extends StatelessWidget {
  const BrandMark({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 36,
      height: 10,
      child: Stack(
        children: [
          Positioned(
            left: 0,
            right: 0,
            top: 4,
            child: Container(height: 1, color: FamilyPalette.railInactive),
          ),
          Positioned(
            left: 11,
            top: 2,
            child: Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: FamilyPalette.crimson,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
