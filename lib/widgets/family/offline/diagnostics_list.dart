import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/api_diagnostics.dart';
import '../../../theme/family_palette.dart';
import '../../../theme/family_typography.dart';

/// "What we tried" — a list of the most recent API attempts with a
/// red/green dot, endpoint, and compact status label.
class DiagnosticsList extends StatelessWidget {
  final List<ApiAttempt> attempts;

  const DiagnosticsList({super.key, required this.attempts});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'WHAT WE TRIED',
          style: GoogleFonts.inter(
            color: FamilyPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 11,
            height: 14 / 11,
          ),
        ),
        const SizedBox(height: 14),
        if (attempts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24),
            child: Text(
              'Nothing logged yet.',
              style: FamilyType.sectionDescription(),
            ),
          )
        else
          for (final attempt in attempts) _DiagnosticsRow(attempt: attempt),
      ],
    );
  }
}

class _DiagnosticsRow extends StatelessWidget {
  final ApiAttempt attempt;
  const _DiagnosticsRow({required this.attempt});

  @override
  Widget build(BuildContext context) {
    final dotColor =
        attempt.success ? FamilyPalette.sage : FamilyPalette.crimson;
    final labelColor =
        attempt.success ? FamilyPalette.sage : FamilyPalette.amber;
    final endpointColor = attempt.success
        ? FamilyPalette.textPrimary
        : FamilyPalette.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(
        border: Border(
          top: BorderSide(color: FamilyPalette.divider, width: 1),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              attempt.endpoint.isEmpty ? '—' : attempt.endpoint,
              style: GoogleFonts.geistMono(
                color: endpointColor,
                fontSize: 13,
                height: 16 / 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 14),
          Text(
            attempt.statusLabel,
            style: GoogleFonts.geistMono(
              color: labelColor,
              fontSize: 12,
              height: 16 / 12,
            ),
          ),
        ],
      ),
    );
  }
}
