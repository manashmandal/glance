import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/family_palette.dart';

/// Slim header strip ("Berlin · S+U Alexanderplatz   14:32   THU, APR 19")
/// used on the offline screen. Mirrors the Paper design's top row.
class OfflineTopStrip extends StatelessWidget {
  final String city;
  final String stationName;
  final DateTime now;

  const OfflineTopStrip({
    super.key,
    required this.city,
    required this.stationName,
    required this.now,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 6,
          height: 6,
          decoration: const BoxDecoration(
            color: FamilyPalette.amber,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          city,
          style: GoogleFonts.inter(
            color: FamilyPalette.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            height: 16 / 13,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '·',
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 13,
            height: 16 / 13,
          ),
        ),
        const SizedBox(width: 10),
        Flexible(
          child: Text(
            stationName,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              color: FamilyPalette.textSecondary,
              fontSize: 13,
              height: 16 / 13,
            ),
          ),
        ),
        const Spacer(),
        Text(
          _timeLabel(now),
          style: GoogleFonts.geistMono(
            color: FamilyPalette.textSecondary,
            fontSize: 13,
            height: 16 / 13,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        Text(
          _dateLabel(now),
          style: GoogleFonts.inter(
            color: FamilyPalette.textTertiary,
            fontSize: 12,
            letterSpacing: 0.06 * 12,
            height: 16 / 12,
          ),
        ),
      ],
    );
  }

  String _timeLabel(DateTime d) {
    final h = d.hour.toString().padLeft(2, '0');
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }

  String _dateLabel(DateTime d) {
    const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];
    const months = [
      'JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN',
      'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC',
    ];
    return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
  }
}
