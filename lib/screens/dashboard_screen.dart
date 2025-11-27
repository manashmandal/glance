import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/clock_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/train_departures_widget.dart';
import '../widgets/settings_dialog.dart';
import '../services/settings_service.dart';
import '../models/station.dart';
import '../models/transport_type.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<WeatherWidgetState> _weatherKey = GlobalKey();
  final GlobalKey<TrainDeparturesWidgetState> _trainKey = GlobalKey();
  Timer? _refreshTimer;
  DateTime? _lastUpdated;
  bool _isFullScreen = false;

  // Settings
  double _weatherScale = 1.0;
  double _departureScale = 1.0;
  Station? _defaultStation;
  TransportType? _defaultTransportType;
  int _skipMinutes = 0;
  int _durationMinutes = 60;
  bool _settingsLoaded = false;
  String _version = '';

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _loadVersion();
    _startRefreshTimer();
  }

  Future<void> _loadVersion() async {
    final packageInfo = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _version = 'v${packageInfo.version}';
      });
    }
  }

  Future<void> _loadSettings() async {
    _weatherScale = await SettingsService.getWeatherScale();
    _departureScale = await SettingsService.getDepartureScale();
    final stationId = await SettingsService.getDefaultStationId();
    if (stationId != null) {
      _defaultStation = Station.popularStations.firstWhere(
        (s) => s.id == stationId,
        orElse: () => Station.defaultStation,
      );
    }
    _defaultTransportType = await SettingsService.getDefaultTransportType();
    _skipMinutes = await SettingsService.getSkipMinutes();
    _durationMinutes = await SettingsService.getDurationMinutes();
    setState(() => _settingsLoaded = true);
  }

  void _startRefreshTimer() {
    _refreshAll();
    _refreshTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _refreshAll();
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _weatherKey.currentState?.refresh() ?? Future.value(),
      _trainKey.currentState?.refresh() ?? Future.value(),
    ]);
    if (mounted) {
      setState(() => _lastUpdated = DateTime.now());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _toggleFullScreen() async {
    try {
      if (_isFullScreen) {
        await windowManager.setFullScreen(false);
      } else {
        await windowManager.setFullScreen(true);
      }
      setState(() => _isFullScreen = !_isFullScreen);
    } catch (e) {
      print('Failed to toggle full screen: $e');
    }
  }

  void _showSettings() {
    showDialog(
      context: context,
      builder: (context) => SettingsDialog(
        initialWeatherScale: _weatherScale,
        initialDepartureScale: _departureScale,
        initialStationId: _defaultStation?.id ?? Station.defaultStation.id,
        initialTransportType: _defaultTransportType ?? TransportType.regional,
        initialSkipMinutes: _skipMinutes,
        initialDurationMinutes: _durationMinutes,
        onSave: (weatherScale, departureScale, stationId, type, skipMinutes, durationMinutes) {
          setState(() {
            _weatherScale = weatherScale;
            _departureScale = departureScale;
            _defaultStation = Station.popularStations.firstWhere(
              (s) => s.id == stationId,
              orElse: () => Station.defaultStation,
            );
            _defaultTransportType = type;
            _skipMinutes = skipMinutes;
            _durationMinutes = durationMinutes;
            // Trigger rebuild with new settings
          });
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_settingsLoaded) {
      return const Scaffold(
        backgroundColor: Color(0xFF1A1D23),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFF1A1D23),
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  // Header with controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Hidden dummy to balance row if needed, or just alignment
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: Colors.white54,
                            ),
                            onPressed: _toggleFullScreen,
                            tooltip: 'Toggle Full Screen',
                          ),
                          IconButton(
                            icon: const Icon(Icons.settings,
                                color: Colors.white54),
                            onPressed: _showSettings,
                            tooltip: 'Settings',
                          ),
                        ],
                      ),
                      if (_lastUpdated != null)
                        Text(
                          'Last updated at: ${DateFormat('HH:mm').format(_lastUpdated!)}',
                          style: const TextStyle(
                            color: Colors.white24,
                            fontSize: 12,
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.refresh, color: Colors.white54),
                        onPressed: _refreshAll,
                        tooltip: 'Force Refresh',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Top row with clock and weather
                  Expanded(
                    flex: 1,
                    child: Row(
                      children: [
                        // Clock module
                        const Expanded(
                          flex: 1,
                          child: ClockWidget(),
                        ),
                        const SizedBox(width: 16),
                        // Branding
                        Expanded(
                          flex: 1,
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo.png',
                                height: 80,
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Glance',
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: 1.0,
                                ),
                              ),
                              Text(
                                _version,
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        // Weather module
                        Expanded(
                          flex: 1,
                          child: WeatherWidget(
                            key: _weatherKey,
                            scaleFactor: _weatherScale,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bottom section with train departures
                  Expanded(
                    flex: 2,
                    child: TrainDeparturesWidget(
                      key: _trainKey,
                      initialStation: _defaultStation,
                      initialTransportType: _defaultTransportType,
                      scaleFactor: _departureScale,
                      skipMinutes: _skipMinutes,
                      durationMinutes: _durationMinutes,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
