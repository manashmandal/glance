import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  static const String _keyThemeMode = 'theme_mode';

  static Future<ThemeMode> getThemeMode() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(_keyThemeMode);
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.dark; // Default to dark
    }
  }

  static Future<void> setThemeMode(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    final value = mode == ThemeMode.light ? 'light' : 'dark';
    await prefs.setString(_keyThemeMode, value);
  }
}

class AppTheme {
  // Dark theme colors
  static const darkBackground = Color(0xFF1A1D23);
  static const darkSurface = Color(0xFF252830);
  static const darkCard = Color(0xFF2A2D35);
  static const darkBorder = Color(0xFF3A3D45);
  static const darkTextPrimary = Colors.white;
  static const darkTextSecondary = Colors.white70;
  static const darkTextTertiary = Colors.white54;
  static const darkTextMuted = Colors.white24;

  // Light theme colors
  static const lightBackground = Color(0xFFF5F7FA);
  static const lightSurface = Color(0xFFFFFFFF);
  static const lightCard = Color(0xFFFFFFFF);
  static const lightBorder = Color(0xFFE0E4E8);
  static const lightTextPrimary = Color(0xFF1A1D23);
  static const lightTextSecondary = Color(0xFF4A5568);
  static const lightTextTertiary = Color(0xFF718096);
  static const lightTextMuted = Color(0xFFA0AEC0);

  // Accent colors (same for both themes)
  static const accentPink = Color(0xFFE91E63);
  static const accentPurple = Color(0xFF9C27B0);
  static const accentBlue = Color(0xFF3B82F6);
  static const accentGreen = Color(0xFF10B981);
  static const accentRed = Color(0xFFEF4444);
  static const accentOrange = Color(0xFFF59E0B);

  static ThemeData darkTheme = ThemeData(
    brightness: Brightness.dark,
    scaffoldBackgroundColor: darkBackground,
    cardColor: darkCard,
    dividerColor: darkBorder,
    colorScheme: const ColorScheme.dark(
      primary: accentBlue,
      secondary: accentPurple,
      surface: darkSurface,
      error: accentRed,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: darkTextPrimary),
      headlineMedium: TextStyle(color: darkTextPrimary),
      bodyLarge: TextStyle(color: darkTextSecondary),
      bodyMedium: TextStyle(color: darkTextSecondary),
      bodySmall: TextStyle(color: darkTextTertiary),
    ),
    iconTheme: const IconThemeData(color: darkTextTertiary),
  );

  static ThemeData lightTheme = ThemeData(
    brightness: Brightness.light,
    scaffoldBackgroundColor: lightBackground,
    cardColor: lightCard,
    dividerColor: lightBorder,
    colorScheme: const ColorScheme.light(
      primary: accentBlue,
      secondary: accentPurple,
      surface: lightSurface,
      error: accentRed,
    ),
    textTheme: const TextTheme(
      headlineLarge: TextStyle(color: lightTextPrimary),
      headlineMedium: TextStyle(color: lightTextPrimary),
      bodyLarge: TextStyle(color: lightTextSecondary),
      bodyMedium: TextStyle(color: lightTextSecondary),
      bodySmall: TextStyle(color: lightTextTertiary),
    ),
    iconTheme: const IconThemeData(color: lightTextTertiary),
  );
}

// Extension for easy access to theme-aware colors
extension ThemeColors on BuildContext {
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  Color get backgroundColor =>
      isDark ? AppTheme.darkBackground : AppTheme.lightBackground;
  Color get surfaceColor =>
      isDark ? AppTheme.darkSurface : AppTheme.lightSurface;
  Color get cardColor => isDark ? AppTheme.darkCard : AppTheme.lightCard;
  Color get borderColor => isDark ? AppTheme.darkBorder : AppTheme.lightBorder;
  Color get textPrimary =>
      isDark ? AppTheme.darkTextPrimary : AppTheme.lightTextPrimary;
  Color get textSecondary =>
      isDark ? AppTheme.darkTextSecondary : AppTheme.lightTextSecondary;
  Color get textTertiary =>
      isDark ? AppTheme.darkTextTertiary : AppTheme.lightTextTertiary;
  Color get textMuted =>
      isDark ? AppTheme.darkTextMuted : AppTheme.lightTextMuted;
}
