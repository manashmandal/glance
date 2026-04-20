import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../data/api_diagnostics.dart';
import '../../../theme/family_palette.dart';

/// Card summarizing the BVG feed's recent health. Headline phrase + a
/// short editorial sentence + a simplified uptime bar seeded from the
/// most recent attempts.
class BvgStatusCard extends StatelessWidget {
  final BvgStatus status;
  final List<bool> uptime;

  const BvgStatusCard({
    super.key,
    required this.status,
    required this.uptime,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'BVG STATUS',
          style: GoogleFonts.inter(
            color: FamilyPalette.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 11,
            height: 14 / 11,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: FamilyPalette.panel,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: FamilyPalette.divider, width: 1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  _headline(status),
                  style: GoogleFonts.interTight(
                    color: _headlineColor(status),
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    height: 1.0,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  _blurb(status),
                  style: GoogleFonts.instrumentSerif(
                    color: FamilyPalette.textSecondary,
                    fontSize: 16,
                    fontStyle: FontStyle.italic,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    for (var i = 0; i < uptime.length; i++) ...[
                      Expanded(child: _UptimeBar(ok: uptime[i])),
                      if (i < uptime.length - 1) const SizedBox(width: 4),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('-${uptime.length}×', style: _axisStyle()),
                    Text('now', style: _axisStyle()),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static TextStyle _axisStyle() => GoogleFonts.geistMono(
        color: FamilyPalette.textTertiary,
        fontSize: 10,
        height: 12 / 10,
      );

  static String _headline(BvgStatus s) => switch (s) {
        BvgStatus.operational => 'Operational',
        BvgStatus.degraded => 'Degraded',
        BvgStatus.outage => 'Outage',
      };

  static Color _headlineColor(BvgStatus s) => switch (s) {
        BvgStatus.operational => FamilyPalette.sage,
        BvgStatus.degraded => FamilyPalette.amber,
        BvgStatus.outage => FamilyPalette.crimson,
      };

  static String _blurb(BvgStatus s) => switch (s) {
        BvgStatus.operational =>
          'Their realtime feed is humming. You should see fresh data shortly.',
        BvgStatus.degraded =>
          'Their realtime feed is having a moment. It usually returns within ten minutes.',
        BvgStatus.outage =>
          'Their realtime feed is down. Hang tight — we\'ll retry on a backoff.',
      };
}

class _UptimeBar extends StatelessWidget {
  final bool ok;
  const _UptimeBar({required this.ok});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 24,
      decoration: BoxDecoration(
        color: ok ? FamilyPalette.sage : FamilyPalette.amber,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
