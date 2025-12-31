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
  final GlobalKey<TrainDeparturesWidgetState> _busKey = GlobalKey();
  Timer? _refreshTimer;
  DateTime? _lastUpdated;
  bool _isFullScreen = false;

  // Transport mode toggle: 0 = Regional, 1 = Bus
  int _selectedTransportMode = 0;

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
    final activeTransportKey = _selectedTransportMode == 0 ? _trainKey : _busKey;
    await Future.wait([
      _weatherKey.currentState?.refresh() ?? Future.value(),
      activeTransportKey.currentState?.refresh() ?? Future.value(),
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

  Widget _buildTransportModeToggle() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildToggleButton(
            index: 0,
            icon: Icons.train,
            label: 'Regional',
            color: const Color(0xFFE91E63),
          ),
          const SizedBox(width: 4),
          _buildToggleButton(
            index: 1,
            icon: Icons.directions_bus,
            label: 'Bus',
            color: const Color(0xFF9C27B0),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton({
    required int index,
    required IconData icon,
    required String label,
    required Color color,
  }) {
    final isSelected = _selectedTransportMode == index;
    return GestureDetector(
      onTap: () {
        if (_selectedTransportMode != index) {
          setState(() => _selectedTransportMode = index);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? color.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 20,
              color: isSelected ? color : Colors.white38,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : Colors.white38,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
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
                  // Transport mode toggle
                  _buildTransportModeToggle(),
                  const SizedBox(height: 16),
                  // Bottom section with departures (switched by toggle)
                  Expanded(
                    flex: 2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.05, 0),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: _selectedTransportMode == 0
                          ? TrainDeparturesWidget(
                              key: const ValueKey('regional'),
                              initialStation: _defaultStation,
                              initialTransportType: _defaultTransportType ?? TransportType.regional,
                              scaleFactor: _departureScale,
                              skipMinutes: _skipMinutes,
                              durationMinutes: _durationMinutes,
                              compactMode: false,
                            )
                          : TrainDeparturesWidget(
                              key: const ValueKey('bus'),
                              initialStation: _defaultStation,
                              initialTransportType: TransportType.bus,
                              scaleFactor: _departureScale,
                              skipMinutes: _skipMinutes,
                              durationMinutes: _durationMinutes,
                              compactMode: false,
                            ),
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
