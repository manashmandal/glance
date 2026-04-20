import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../theme/family_palette.dart';

/// Little uppercase pill used for inline labels like "OLED" or "BETA".
class TinyPill extends StatelessWidget {
  final String label;
  final Color color;

  const TinyPill({
    super.key,
    required this.label,
    this.color = FamilyPalette.crimson,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.45), width: 1),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.inter(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.14 * 10,
          height: 12 / 10,
        ),
      ),
    );
  }
}
