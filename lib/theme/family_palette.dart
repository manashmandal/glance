import 'package:flutter/material.dart';

/// Color tokens for the Family Dashboard (night variant).
///
/// Palette mood: nocturnal — inky blue-black ground, warm bone text,
/// crimson accent for departures, sage green for "good" states, amber
/// for warnings/updates.
class FamilyPalette {
  const FamilyPalette._();

  // Surfaces
  static const Color background = Color(0xFF0A0A12);
  static const Color panel = Color(0xFF14141F);
  static const Color divider = Color(0xFF2C2D44);
  static const Color dividerDim = Color(0xFF3C3547);
  static const Color railInactive = Color(0xFF4A4E69);

  // Text
  static const Color textPrimary = Color(0xFFF2E9E4);
  static const Color textSecondary = Color(0xFF9A8C98);
  static const Color textTertiary = Color(0xFF6A6076);
  static const Color textMuted = Color(0xFF6B6475);
  static const Color textEventRange = Color(0xFFC9C2BC);

  // Accents
  static const Color crimson = Color(0xFFD4525E);
  static const Color crimsonWarm = Color(0xFFE87668);
  static const Color crimsonTint = Color(0x17E87668);
  static const Color sage = Color(0xFF7AB58D);
  static const Color amber = Color(0xFFD4A35F);
  static const Color amberBright = Color(0xFFE0B86F);
  static const Color amberTint = Color(0x1FD4A05E);
  static const Color amberBorder = Color(0x59D4A05E);

  // Halos (used with BoxShadow for soft rings around dots)
  static const Color sageHalo = Color(0x2E7AB58D);
  static const Color crimsonHalo = Color(0x2ED4525E);
  static const Color crimsonGlow = Color(0x99D4525E);
}
