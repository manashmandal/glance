import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:window_manager/window_manager.dart';
import 'screens/dashboard_screen.dart';
import 'services/theme_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Allow all orientations for mobile support
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize window manager for desktop
  try {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(800, 600),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.normal,
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  } catch (e) {
    // Ignore errors on non-desktop platforms
    print('Window Manager init failed (expected on mobile/web): $e');
  }

  runApp(const GlanceApp());
}

class GlanceApp extends StatefulWidget {
  const GlanceApp({super.key});

  static _GlanceAppState? of(BuildContext context) {
    return context.findAncestorStateOfType<_GlanceAppState>();
  }

  @override
  State<GlanceApp> createState() => _GlanceAppState();
}

class _GlanceAppState extends State<GlanceApp> {
  ThemeMode _themeMode = ThemeMode.dark;

  @override
  void initState() {
    super.initState();
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final mode = await ThemeService.getThemeMode();
    if (mounted) {
      setState(() => _themeMode = mode);
    }
  }

  void toggleTheme() {
    final newMode =
        _themeMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    setState(() => _themeMode = newMode);
    ThemeService.setThemeMode(newMode);
  }

  bool get isDarkMode => _themeMode == ThemeMode.dark;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Glance Dashboard',
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppTheme.lightBackground,
        cardColor: AppTheme.lightCard,
        dividerColor: AppTheme.lightBorder,
        colorScheme: const ColorScheme.light(
          surface: AppTheme.lightSurface,
          primary: AppTheme.accentBlue,
          secondary: AppTheme.accentPurple,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: AppTheme.lightTextPrimary,
            letterSpacing: -2,
          ),
          displayMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: AppTheme.lightTextPrimary,
          ),
          bodyLarge: TextStyle(
            fontSize: 18,
            color: AppTheme.lightTextSecondary,
          ),
          bodyMedium: TextStyle(
            fontSize: 16,
            color: AppTheme.lightTextTertiary,
          ),
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppTheme.darkBackground,
        cardColor: AppTheme.darkCard,
        dividerColor: AppTheme.darkBorder,
        colorScheme: const ColorScheme.dark(
          surface: AppTheme.darkSurface,
          primary: AppTheme.accentBlue,
          secondary: AppTheme.accentPurple,
        ),
        fontFamily: 'Inter',
        textTheme: const TextTheme(
          displayLarge: TextStyle(
            fontSize: 96,
            fontWeight: FontWeight.bold,
            color: AppTheme.darkTextPrimary,
            letterSpacing: -2,
          ),
          displayMedium: TextStyle(
            fontSize: 48,
            fontWeight: FontWeight.w600,
            color: AppTheme.darkTextPrimary,
          ),
          bodyLarge: TextStyle(fontSize: 18, color: AppTheme.darkTextSecondary),
          bodyMedium: TextStyle(fontSize: 16, color: AppTheme.darkTextTertiary),
        ),
      ),
      home: const DashboardScreen(),
    );
  }
}
