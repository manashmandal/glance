import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// Amber-accented banner shown when the BVG API hasn't responded for a
/// while. Reassures the user that the last good data is still on screen
/// and offers a manual retry.
class OfflineBanner extends StatelessWidget {
  final Duration silentFor;
  final VoidCallback onRetry;

  const OfflineBanner({
    super.key,
    required this.silentFor,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: FamilyPalette.amber, width: 1),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: FamilyPalette.amber,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "BVG hasn't responded in ${_silentLabel(silentFor)}.",
                  style: GoogleFonts.interTight(
                    color: FamilyPalette.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    height: 20 / 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "Showing the last data we received. We'll keep trying.",
                  style: FamilyType.sectionDescription().copyWith(fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          _RetryButton(onTap: onRetry),
        ],
      ),
    );
  }

  String _silentLabel(Duration d) {
    if (d.inMinutes < 1) return '${d.inSeconds} seconds';
    if (d.inMinutes == 1) return '1 minute';
    if (d.inHours < 1) return '${d.inMinutes} minutes';
    return '${d.inHours}h';
  }
}

class _RetryButton extends StatelessWidget {
  final VoidCallback onTap;
  const _RetryButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: FamilyPalette.amber, width: 1),
          ),
          child: Text(
            'Retry now',
            style: GoogleFonts.interTight(
              color: FamilyPalette.amber,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              height: 16 / 13,
            ),
          ),
        ),
      ),
    );
  }
}
