import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../data/family_adapters.dart';
import '../data/family_placeholders.dart';
import '../main.dart';
import '../models/station.dart';
import '../models/train_departure.dart';
import '../models/transport_type.dart';
import '../models/weather_data.dart';
import '../services/bvg_service.dart';
import '../services/settings_service.dart';
import '../services/update_service.dart';
import '../services/weather_service.dart';
import '../theme/family_palette.dart';
import '../widgets/family/brand_signature.dart';
import '../widgets/family/clock_block.dart';
import '../widgets/family/countdown_hero.dart';
import '../widgets/family/destination_banner.dart';
import '../widgets/family/platform_card.dart';
import '../widgets/family/route_preview.dart';
import '../widgets/family/station_label.dart';
import '../widgets/family/up_next_block.dart';
import '../widgets/family/upcoming_list.dart';
import '../widgets/family/weather_column.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const int _walkMinutes = 4;

  Timer? _refreshTimer;
  Timer? _updateCheckTimer;

  Station _station = Station.defaultStation;
  TransportType _transportType = TransportType.regional;
  int _skipMinutes = 0;
  int _durationMinutes = 60;
  bool _settingsLoaded = false;

  List<TrainDeparture> _departures = const [];
  WeatherData? _weather;

  String _version = 'v0.0.0';
  String? _updateVersion;
  String? _updateUrl;

  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _updateCheckTimer?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadVersion();
    await _loadSettings();
    await _refreshAll();
    _refreshTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _refreshAll());
    _updateCheckTimer =
        Timer.periodic(const Duration(hours: 24), (_) => _checkForUpdate());
    await _checkForUpdate();
  }

  Future<void> _loadVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (!mounted) return;
    setState(() => _version = 'v${info.version}');
  }

  Future<void> _loadSettings() async {
    final stationId = await SettingsService.getDefaultStationId();
    final transportType = await SettingsService.getDefaultTransportType();
    final skipMinutes = await SettingsService.getSkipMinutes();
    final durationMinutes = await SettingsService.getDurationMinutes();
    if (!mounted) return;
    setState(() {
      if (stationId != null) {
        _station = Station.popularStations.firstWhere(
          (s) => s.id == stationId,
          orElse: () => Station.defaultStation,
        );
      }
      _transportType = transportType;
      _skipMinutes = skipMinutes;
      _durationMinutes = durationMinutes;
      _settingsLoaded = true;
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([_refreshDepartures(), _refreshWeather()]);
  }

  Future<void> _refreshDepartures() async {
    try {
      final list = await BvgService.getDepartures(
        stationId: _station.id,
        duration: _durationMinutes,
        transportType: _transportType,
        skipMinutes: _skipMinutes,
      );
      if (!mounted) return;
      setState(() => _departures = list);
    } catch (_) {
      // Keep prior state on failure; fallback is handled inside BvgService.
    }
  }

  Future<void> _refreshWeather() async {
    try {
      final data = await WeatherService.getWeather();
      if (!mounted) return;
      setState(() => _weather = data);
    } catch (_) {
      // Swallow – placeholders remain visible.
    }
  }

  Future<void> _checkForUpdate() async {
    final current = _version.startsWith('v') ? _version.substring(1) : _version;
    final info = await UpdateService.checkForUpdate(current);
    if (!mounted || info == null) return;
    setState(() {
      _updateVersion = info.updateAvailable ? 'v${info.latestVersion}' : null;
      _updateUrl = info.downloadUrl;
    });
  }

  Future<void> _handleUpdateTap() async {
    if (_updateUrl == null) return;
    final uri = Uri.parse(_updateUrl!);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _selectKind(TransitKind kind) async {
    final mapped = switch (kind) {
      TransitKind.regional => TransportType.regional,
      TransitKind.sBahn => TransportType.sBahn,
      TransitKind.uBahn => TransportType.uBahn,
      TransitKind.bus => TransportType.bus,
    };
    if (mapped == _transportType) return;
    setState(() => _transportType = mapped);
    await SettingsService.saveDefaultTransportType(mapped);
    await _refreshDepartures();
  }

  TransitKind get _activeKind => switch (_transportType) {
        TransportType.regional => TransitKind.regional,
        TransportType.sBahn => TransitKind.sBahn,
        TransportType.uBahn => TransitKind.uBahn,
        TransportType.bus => TransitKind.bus,
      };

  Future<void> _toggleFullScreen() async {
    try {
      await windowManager.setFullScreen(!_isFullScreen);
      setState(() => _isFullScreen = !_isFullScreen);
    } catch (_) {}
  }

  void _showMenu() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: FamilyPalette.panel,
      builder: (sheetContext) {
        final isDark = Theme.of(sheetContext).brightness == Brightness.dark;
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: Icon(
                  _isFullScreen ? Icons.fullscreen_exit : Icons.fullscreen,
                  color: FamilyPalette.textPrimary,
                ),
                title: const Text(
                  'Toggle full screen',
                  style: TextStyle(color: FamilyPalette.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _toggleFullScreen();
                },
              ),
              ListTile(
                leading: Icon(
                  isDark ? Icons.light_mode : Icons.dark_mode,
                  color: FamilyPalette.textPrimary,
                ),
                title: Text(
                  isDark ? 'Switch to light mode' : 'Switch to dark mode',
                  style: const TextStyle(color: FamilyPalette.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  GlanceApp.of(context)?.toggleTheme();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.settings,
                  color: FamilyPalette.textPrimary,
                ),
                title: const Text(
                  'Settings',
                  style: TextStyle(color: FamilyPalette.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _openSettings();
                },
              ),
              ListTile(
                leading: const Icon(
                  Icons.refresh,
                  color: FamilyPalette.textPrimary,
                ),
                title: const Text(
                  'Refresh now',
                  style: TextStyle(color: FamilyPalette.textPrimary),
                ),
                onTap: () {
                  Navigator.of(sheetContext).pop();
                  _refreshAll();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSettings() async {
    await Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const SettingsScreen(),
        transitionDuration: const Duration(milliseconds: 220),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
    if (!mounted) return;
    await _loadSettings();
    await _refreshAll();
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return const Scaffold(
        backgroundColor: FamilyPalette.background,
        body: Center(
          child: CircularProgressIndicator(color: FamilyPalette.crimson),
        ),
      );
    }

    final next = _departures.isNotEmpty ? _departures.first : null;
    final countdown = FamilyAdapters.countdownMinutes(next) ??
        FamilyPlaceholders.countdownMinutes;
    final leaveBy = FamilyAdapters.leaveByTime(next, _walkMinutes) ??
        FamilyPlaceholders.leaveByTime;
    final destination = next?.destination ?? FamilyPlaceholders.destinationName;
    final platform = _cleanPlatform(next?.platform) ??
        FamilyPlaceholders.nextPlatform;
    final lineCode = next?.line ?? FamilyPlaceholders.nextLineCode;

    final upcomingRows = _departures.length > 1
        ? FamilyAdapters.departureItems(
            _departures.sublist(1),
            highlightLine: lineCode,
          )
        : FamilyPlaceholders.upcoming;

    final forecast = FamilyAdapters.forecastPoints(_weather);
    final condition = FamilyAdapters.weatherCondition(_weather);
    final currentTemp = _weather != null
        ? '${_weather!.temperature.round()}'
        : FamilyPlaceholders.currentTemp;

    return Scaffold(
      backgroundColor: FamilyPalette.background,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _isFullScreen) {
            _toggleFullScreen();
          }
        },
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: constraints.maxHeight < 820
                    ? const ClampingScrollPhysics()
                    : const NeverScrollableScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    minHeight: constraints.maxHeight,
                  ),
                  child: IntrinsicHeight(
                    child: Column(
                      children: [
                        _topStrip(),
                        _middleSection(
                          countdown: countdown,
                          leaveBy: leaveBy,
                          lineCode: lineCode,
                          platform: platform,
                          destination: destination,
                        ),
                        Expanded(
                          child: _bottomRow(
                            upcomingRows: upcomingRows,
                            forecast: forecast,
                            condition: condition,
                            currentTemp: currentTemp,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _topStrip() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 24, 40, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 420,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandSignature(
                  version: _version,
                  commit: FamilyPlaceholders.commit,
                  availableVersion: _updateVersion,
                  onUpdateTap: _handleUpdateTap,
                ),
                const SizedBox(height: 10),
                StationLabel(stationName: _station.name),
              ],
            ),
          ),
          const Spacer(),
          ClockBlock(onMenuTap: _showMenu),
        ],
      ),
    );
  }

  Widget _middleSection({
    required int countdown,
    required String leaveBy,
    required String lineCode,
    required String platform,
    required String destination,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 8, 40, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: RoutePreview(
                  hint: FamilyPlaceholders.routeHint,
                  stops: FamilyPlaceholders.routeStops,
                ),
              ),
              SizedBox(width: 40),
              UpNextBlock(event: FamilyPlaceholders.upNext),
            ],
          ),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              CountdownHero(
                minutes: countdown,
                leaveByTime: leaveBy,
                walkDuration: FamilyPlaceholders.walkDuration,
              ),
              const Spacer(),
              PlatformCard(
                lineCode: lineCode,
                category: FamilyPlaceholders.nextLineCategory,
                platform: platform,
              ),
            ],
          ),
          const SizedBox(height: 10),
          DestinationBanner(destination: destination),
        ],
      ),
    );
  }

  Widget _bottomRow({
    required List<DepartureItem> upcomingRows,
    required List<ForecastPoint> forecast,
    required String condition,
    required String currentTemp,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(40, 16, 40, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 6,
            child: UpcomingList(
              departures: upcomingRows,
              activeKind: _activeKind,
              onKindSelected: _selectKind,
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: 4,
            child: WeatherColumn(
              location: FamilyPlaceholders.weatherLocation,
              currentTemp: currentTemp,
              condition: condition,
              tip: FamilyPlaceholders.weatherTip,
              forecast: forecast,
            ),
          ),
        ],
      ),
    );
  }

  String? _cleanPlatform(String? raw) {
    if (raw == null) return null;
    return raw.replaceFirst('Pl. ', '').replaceFirst('Pl.', '').trim();
  }
}
