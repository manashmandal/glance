import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:window_manager/window_manager.dart';

import '../data/api_diagnostics.dart';
import '../data/family_adapters.dart';
import '../data/family_placeholders.dart';
import '../data/layout_preset.dart';
import '../main.dart';
import '../models/journey.dart';
import '../models/route_stop.dart';
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
import 'offline_screen.dart';
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
  final FocusNode _keyFocus = FocusNode();

  Station _station = Station.defaultStation;
  Station? _destinationStation;
  TransportType _transportType = TransportType.regional;
  int _skipMinutes = 0;
  int _durationMinutes = 60;
  LayoutPreset _preset = LayoutPreset.editorial;
  bool _settingsLoaded = false;

  List<TrainDeparture> _departures = const [];
  WeatherData? _weather;
  Journey? _journey;

  String _version = 'v0.0.0';
  String? _updateVersion;
  String? _updateUrl;

  bool _isFullScreen = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _keyFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _updateCheckTimer?.cancel();
    _keyFocus.dispose();
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
    final stationId = await SettingsService.readDefaultStationId();
    final destinationId = await SettingsService.readDestinationStationId();
    final transportType = await SettingsService.readDefaultTransportType();
    final skipMinutes = await SettingsService.readSkipMinutes();
    final durationMinutes = await SettingsService.readDurationMinutes();
    final preset = await SettingsService.readLayoutPreset();
    if (!mounted) return;
    setState(() {
      if (stationId != null) {
        _station = Station.popularStations.firstWhere(
          (s) => s.id == stationId,
          orElse: () => Station.defaultStation,
        );
      }
      _destinationStation = destinationId == null
          ? null
          : Station.popularStations.firstWhere(
              (s) => s.id == destinationId,
              orElse: () => Station(id: destinationId, name: destinationId),
            );
      _transportType = transportType;
      _skipMinutes = skipMinutes;
      _durationMinutes = durationMinutes;
      _preset = preset;
      _settingsLoaded = true;
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _refreshDepartures(),
      _refreshWeather(),
      _refreshJourney(),
    ]);
  }

  Future<void> _refreshDepartures() async {
    try {
      final list = await BvgService.fetchDepartures(
        stationId: _station.id,
        duration: _durationMinutes,
        transportType: _transportType,
        skipMinutes: _skipMinutes,
      );
      if (!mounted) return;
      setState(() => _departures = list);
    } catch (e, st) {
      // Keep prior state on failure; service-level fallback already ran.
      debugPrint('refreshDepartures failed: $e\n$st');
    }
  }

  Future<void> _refreshWeather() async {
    try {
      final data = await WeatherService.fetchWeather();
      if (!mounted) return;
      setState(() => _weather = data);
    } catch (e, st) {
      // Placeholders remain visible.
      debugPrint('refreshWeather failed: $e\n$st');
    }
  }

  Future<void> _refreshJourney() async {
    final destination = _destinationStation;
    if (destination == null || destination.id == _station.id) {
      if (_journey != null && mounted) setState(() => _journey = null);
      return;
    }
    try {
      final journey = await BvgService.fetchJourney(
        fromStationId: _station.id,
        toStationId: destination.id,
      );
      if (!mounted) return;
      setState(() => _journey = journey);
    } catch (e, st) {
      debugPrint('refreshJourney failed: $e\n$st');
      if (!mounted) return;
      setState(() => _journey = null);
    }
  }

  Future<void> _checkForUpdate() async {
    final current = _version.startsWith('v') ? _version.substring(1) : _version;
    final info = await UpdateService.checkForUpdate(current);
    if (!mounted || info == null) return;
    setState(() {
      _updateVersion = 'v${info.latestVersion}';
      _updateUrl = info.downloadUrl;
    });
  }

  Future<void> _handleUpdateTap() async {
    final url = _updateUrl;
    if (url == null) return;
    try {
      final uri = Uri.parse(url);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('handleUpdateTap launch failed for $url: $e');
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
    final target = !_isFullScreen;
    try {
      await windowManager.setFullScreen(target);
    } catch (e) {
      debugPrint('setFullScreen failed: $e');
      return;
    }
    if (!mounted) return;
    setState(() => _isFullScreen = target);
  }

  void _showMenu() {
    final app = GlanceApp.of(context);
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
                  app?.toggleTheme();
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
    // The KeyboardListener lost focus while Settings was on top; restore it
    // so the Escape-to-exit-fullscreen shortcut keeps working.
    if (!_keyFocus.hasFocus) _keyFocus.requestFocus();
    await _loadSettings();
    if (!mounted) return;
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
    final platform = FamilyAdapters.displayPlatform(next) ??
        FamilyPlaceholders.nextPlatform;
    final lineCode = next?.line ?? FamilyPlaceholders.nextLineCode;

    if (ApiDiagnostics.bvgDegraded) {
      return OfflineScreen(
        city: 'Berlin',
        stationName: _station.name,
        now: DateTime.now(),
        silentFor: ApiDiagnostics.bvgSilentFor,
        lastSeenAt: ApiDiagnostics.lastBvgSuccess,
        countdownMinutes: countdown,
        destination: destination,
        lineCode: lineCode,
        attempts: ApiDiagnostics.recentBvg(),
        status: ApiDiagnostics.bvgStatus,
        uptime: ApiDiagnostics.bvgUptimeWindow(),
        onRetry: _refreshAll,
      );
    }

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

    final routeStops = FamilyAdapters.routeStops(_journey);
    final config = LayoutPresetConfig.of(_preset);

    final body = Scaffold(
      backgroundColor: FamilyPalette.background,
      body: KeyboardListener(
        focusNode: _keyFocus,
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
                        _topStrip(config),
                        if (config.heroOnly)
                          const Expanded(child: SizedBox.shrink()),
                        _middleSection(
                          countdown: countdown,
                          leaveBy: leaveBy,
                          lineCode: lineCode,
                          platform: platform,
                          destination: destination,
                          routeStops: routeStops,
                          config: config,
                        ),
                        if (config.heroOnly)
                          const Expanded(child: SizedBox.shrink())
                        else
                          Expanded(
                            child: _bottomRow(
                              upcomingRows: upcomingRows,
                              forecast: forecast,
                              condition: condition,
                              currentTemp: currentTemp,
                              config: config,
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

    if (config.densityScale == 1.0) return body;
    final base = MediaQuery.textScalerOf(context);
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(
        textScaler: base.clamp(
          minScaleFactor: config.densityScale,
          maxScaleFactor: config.densityScale,
        ),
      ),
      child: body,
    );
  }

  Widget _topStrip(LayoutPresetConfig config) {
    final hpad = _hpad(config);
    return Padding(
      padding: EdgeInsets.fromLTRB(hpad, 24, hpad, 0),
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

  double _hpad(LayoutPresetConfig config) => 40 * config.densityScale;

  Widget _middleSection({
    required int countdown,
    required String leaveBy,
    required String lineCode,
    required String platform,
    required String destination,
    required List<RouteStop>? routeStops,
    required LayoutPresetConfig config,
  }) {
    final hpad = _hpad(config);
    return Padding(
      padding: EdgeInsets.fromLTRB(hpad, 8, hpad, 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: routeStops == null
                    ? const SizedBox.shrink()
                    : RoutePreview(stops: routeStops),
              ),
              const SizedBox(width: 40),
              const UpNextBlock(event: FamilyPlaceholders.upNext),
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
    required LayoutPresetConfig config,
  }) {
    final hpad = _hpad(config);
    return Padding(
      padding: EdgeInsets.fromLTRB(hpad, 16, hpad, 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: config.upcomingFlex,
            child: UpcomingList(
              departures: upcomingRows,
              activeKind: _activeKind,
              onKindSelected: _selectKind,
            ),
          ),
          const SizedBox(width: 56),
          Expanded(
            flex: config.weatherFlex,
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

}
