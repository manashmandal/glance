import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/family_palette.dart';

/// Dimmed last-known-good hero: a "last seen" meta row, a struck-
/// through countdown to signal staleness, a line-code pill, and the
/// destination name in muted text.
class StaleHero extends StatelessWidget {
  final DateTime? lastSeenAt;
  final int countdownMinutes;
  final String destination;
  final String lineCode;

  const StaleHero({
    super.key,
    required this.lastSeenAt,
    required this.countdownMinutes,
    required this.destination,
    required this.lineCode,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: 0.55,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _MetaRow(lastSeenAt: lastSeenAt),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _Countdown(minutes: countdownMinutes),
              const Spacer(),
              _LinePill(code: lineCode),
            ],
          ),
          const SizedBox(height: 18),
          Text(
            destination,
            style: GoogleFonts.interTight(
              color: FamilyPalette.textTertiary,
              fontSize: 52,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.035 * 52,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaRow extends StatelessWidget {
  final DateTime? lastSeenAt;
  const _MetaRow({required this.lastSeenAt});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 3,
          height: 14,
          color: FamilyPalette.textTertiary,
        ),
        const SizedBox(width: 10),
        Text(
          'LAST SEEN · ${_timeLabel(lastSeenAt)}',
          style: GoogleFonts.inter(
            color: FamilyPalette.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.18 * 11,
            height: 14 / 11,
          ),
        ),
        const Spacer(),
        Text(
          'STALE DATA',
          style: GoogleFonts.inter(
            color: FamilyPalette.amber,
            fontSize: 11,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.18 * 11,
            height: 14 / 11,
          ),
        ),
      ],
    );
  }

  String _timeLabel(DateTime? when) {
    if (when == null) return '—';
    final h = when.hour.toString().padLeft(2, '0');
    final m = when.minute.toString().padLeft(2, '0');
    return '$h:$m';
  }
}

class _Countdown extends StatelessWidget {
  final int minutes;
  const _Countdown({required this.minutes});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Text(
          'in',
          style: GoogleFonts.interTight(
            color: FamilyPalette.textTertiary,
            fontSize: 28,
            height: 34 / 28,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          '$minutes',
          style: GoogleFonts.geistMono(
            color: FamilyPalette.textTertiary,
            fontSize: 144,
            fontWeight: FontWeight.w500,
            letterSpacing: -0.06 * 144,
            height: 0.85,
            decoration: TextDecoration.lineThrough,
            decorationColor: FamilyPalette.amber,
            decorationThickness: 3,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const SizedBox(width: 16),
        Text(
          'min',
          style: GoogleFonts.interTight(
            color: FamilyPalette.textTertiary,
            fontSize: 28,
            height: 34 / 28,
          ),
        ),
      ],
    );
  }
}

class _LinePill extends StatelessWidget {
  final String code;
  const _LinePill({required this.code});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: FamilyPalette.panel,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: FamilyPalette.textTertiary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            code,
            style: GoogleFonts.geistMono(
              color: FamilyPalette.textSecondary,
              fontSize: 13,
              height: 16 / 13,
            ),
          ),
        ],
      ),
    );
  }
}
