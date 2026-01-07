import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:window_manager/window_manager.dart';
import '../widgets/clock_widget.dart';
import '../widgets/weather_widget.dart';
import '../widgets/train_departures_widget.dart';
import '../widgets/settings_dialog.dart';
import '../widgets/draggable_resizable_container.dart';
import '../widgets/edit_mode_toolbar.dart';
import '../services/settings_service.dart';
import '../services/layout_service.dart';
import '../models/station.dart';
import '../models/transport_type.dart';
import '../models/widget_layout.dart';
import '../main.dart';
import '../services/theme_service.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<WeatherWidgetState> _weatherKey = GlobalKey();
  final GlobalKey<TrainDeparturesWidgetState> _regionalDeparturesKey =
      GlobalKey();
  final GlobalKey<TrainDeparturesWidgetState> _busDeparturesKey = GlobalKey();
  Timer? _refreshTimer;
  Timer? _saveDebounceTimer;
  DateTime? _lastUpdated;
  bool _isFullScreen = false;
  bool _isEditMode = false;

  // Transport mode toggle: 0 = Regional, 1 = Bus
  int _selectedTransportMode = 0;

  // Layout
  DashboardLayout _dashboardLayout = DashboardLayout.defaultLayout;
  Orientation? _lastOrientation;

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

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final orientation = MediaQuery.of(context).orientation;
    if (_lastOrientation != orientation) {
      _lastOrientation = orientation;
      _loadLayoutForOrientation();
    }
  }

  bool get _isPortrait =>
      MediaQuery.of(context).orientation == Orientation.portrait;
  bool get _isSmallScreen => MediaQuery.of(context).size.shortestSide < 600;

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

  Future<void> _loadLayoutForOrientation() async {
    final layout = await LayoutService.getLayout(isPortrait: _isPortrait);
    if (mounted) {
      setState(() => _dashboardLayout = layout);
    }
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
      _regionalDeparturesKey.currentState?.refresh() ?? Future.value(),
      _busDeparturesKey.currentState?.refresh() ?? Future.value(),
    ]);
    if (mounted) {
      setState(() => _lastUpdated = DateTime.now());
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _saveDebounceTimer?.cancel();
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

  void _toggleEditMode() {
    setState(() => _isEditMode = !_isEditMode);
    if (!_isEditMode) {
      _saveLayout();
    }
  }

  void _updateWidgetLayout(String widgetId, WidgetLayout layout) {
    setState(() {
      _dashboardLayout = _dashboardLayout.updateWidget(widgetId, layout);
    });
    _debounceSaveLayout();
  }

  void _debounceSaveLayout() {
    _saveDebounceTimer?.cancel();
    _saveDebounceTimer = Timer(const Duration(milliseconds: 500), () {
      _saveLayout();
    });
  }

  Future<void> _saveLayout() async {
    await LayoutService.saveLayout(_dashboardLayout, isPortrait: _isPortrait);
  }

  Future<void> _resetLayout() async {
    await LayoutService.resetToDefault(isPortrait: _isPortrait);
    final defaultLayout = _isPortrait
        ? DashboardLayout.defaultPortraitLayout
        : DashboardLayout.defaultLandscapeLayout;
    setState(() => _dashboardLayout = defaultLayout);
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
        onSave:
            (
              weatherScale,
              departureScale,
              stationId,
              type,
              skipMinutes,
              durationMinutes,
            ) {
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
              });
            },
        onPresetSelected: _applyLayoutPreset,
      ),
    );
  }

  Future<void> _applyLayoutPreset(LayoutPreset preset) async {
    final layout = _isPortrait ? preset.portraitLayout : preset.landscapeLayout;
    setState(() => _dashboardLayout = layout);
    await _saveLayout();
  }

  Widget _buildWidget(String widgetId) {
    switch (widgetId) {
      case 'clock':
        return const ClockWidget();
      case 'logo':
        return _buildLogoWidget();
      case 'weather':
        return WeatherWidget(key: _weatherKey, scaleFactor: _weatherScale);
      case 'departures':
        return _buildDeparturesWidget();
      default:
        return const SizedBox();
    }
  }

  Widget _buildLogoWidget() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      decoration: BoxDecoration(
        color: context.cardColor,
        borderRadius: BorderRadius.circular(16),
        border: isDark ? null : Border.all(color: context.borderColor),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Flexible(child: Image.asset('assets/images/logo.png', height: 80)),
          const SizedBox(height: 8),
          Text(
            'Glance',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: context.textPrimary,
              letterSpacing: 1.0,
            ),
          ),
          Text(
            _version,
            style: TextStyle(fontSize: 12, color: context.textTertiary),
          ),
        ],
      ),
    );
  }

  Widget _buildDeparturesWidget() {
    final useCompactMode = _isSmallScreen || _isPortrait;

    return Column(
      children: [
        _buildTransportModeToggle(),
        const SizedBox(height: 12),
        Expanded(
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
                    key: _regionalDeparturesKey,
                    initialStation: _defaultStation,
                    initialTransportType:
                        _defaultTransportType ?? TransportType.regional,
                    scaleFactor: _departureScale,
                    skipMinutes: _skipMinutes,
                    durationMinutes: _durationMinutes,
                    compactMode: useCompactMode,
                  )
                : TrainDeparturesWidget(
                    key: _busDeparturesKey,
                    initialStation: _defaultStation,
                    initialTransportType: TransportType.bus,
                    scaleFactor: _departureScale,
                    skipMinutes: _skipMinutes,
                    durationMinutes: _durationMinutes,
                    compactMode: useCompactMode,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildTransportModeToggle() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.05),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final unselectedColor = isDark ? Colors.white38 : Colors.black38;
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
            Icon(icon, size: 20, color: isSelected ? color : unselectedColor),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : unselectedColor,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final iconColor = isDark ? Colors.white54 : Colors.black54;
    final mutedTextColor = isDark ? Colors.white24 : Colors.black26;
    final screenWidth = MediaQuery.of(context).size.width;
    final padding = screenWidth < 600 ? 12.0 : 24.0;
    final canEdit = !_isSmallScreen;

    if (!_settingsLoaded) {
      return Scaffold(
        backgroundColor: context.backgroundColor,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: context.backgroundColor,
      body: KeyboardListener(
        focusNode: FocusNode()..requestFocus(),
        onKeyEvent: (event) {
          if (event is KeyDownEvent &&
              event.logicalKey == LogicalKeyboardKey.escape &&
              _isEditMode) {
            _toggleEditMode();
          }
        },
        child: SafeArea(
          child: Column(
            children: [
              // Header with controls
              Padding(
                padding: EdgeInsets.fromLTRB(
                  padding,
                  _isSmallScreen ? 8 : 16,
                  padding,
                  8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        if (!_isSmallScreen)
                          IconButton(
                            icon: Icon(
                              _isFullScreen
                                  ? Icons.fullscreen_exit
                                  : Icons.fullscreen,
                              color: iconColor,
                            ),
                            onPressed: _toggleFullScreen,
                            tooltip: 'Toggle Full Screen',
                          ),
                        IconButton(
                          icon: Icon(Icons.settings, color: iconColor),
                          onPressed: _showSettings,
                          tooltip: 'Settings',
                        ),
                        if (canEdit)
                          IconButton(
                            icon: Icon(
                              Icons.dashboard_customize,
                              color: _isEditMode
                                  ? const Color(0xFF3B82F6)
                                  : iconColor,
                            ),
                            onPressed: _toggleEditMode,
                            tooltip: 'Edit Layout',
                          ),
                        IconButton(
                          icon: Icon(
                            isDark ? Icons.light_mode : Icons.dark_mode,
                            color: iconColor,
                          ),
                          onPressed: () => GlanceApp.of(context)?.toggleTheme(),
                          tooltip: isDark
                              ? 'Switch to Light Mode'
                              : 'Switch to Dark Mode',
                        ),
                      ],
                    ),
                    if (_lastUpdated != null && !_isSmallScreen)
                      Text(
                        'Last updated at: ${DateFormat('HH:mm').format(_lastUpdated!)}',
                        style: TextStyle(color: mutedTextColor, fontSize: 12),
                      ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: iconColor),
                      onPressed: _refreshAll,
                      tooltip: 'Force Refresh',
                    ),
                  ],
                ),
              ),
              // Main content area with Stack layout
              Expanded(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(padding, 0, padding, padding),
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      final containerSize = Size(
                        constraints.maxWidth,
                        constraints.maxHeight,
                      );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          // Render widgets based on layout
                          for (final entry in _dashboardLayout.layouts.entries)
                            Positioned(
                              left: entry.value.x * containerSize.width,
                              top: entry.value.y * containerSize.height,
                              width: entry.value.width * containerSize.width,
                              height: entry.value.height * containerSize.height,
                              child: DraggableResizableContainer(
                                isEditMode: _isEditMode,
                                layout: entry.value,
                                containerSize: containerSize,
                                onLayoutUpdate: (newLayout) =>
                                    _updateWidgetLayout(entry.key, newLayout),
                                minWidth: _getMinWidth(entry.key),
                                minHeight: _getMinHeight(entry.key),
                                child: _buildWidget(entry.key),
                              ),
                            ),
                          // Edit mode toolbar
                          if (_isEditMode)
                            Positioned(
                              bottom: 20,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: EditModeToolbar(
                                  onDone: _toggleEditMode,
                                  onReset: _resetLayout,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  double _getMinWidth(String widgetId) {
    if (_isSmallScreen) {
      switch (widgetId) {
        case 'clock':
          return 120;
        case 'logo':
          return 100;
        case 'weather':
          return 120;
        case 'departures':
          return 200;
        default:
          return 100;
      }
    }
    switch (widgetId) {
      case 'clock':
        return 180;
      case 'logo':
        return 150;
      case 'weather':
        return 200;
      case 'departures':
        return 350;
      default:
        return 150;
    }
  }

  double _getMinHeight(String widgetId) {
    if (_isSmallScreen) {
      switch (widgetId) {
        case 'clock':
          return 80;
        case 'logo':
          return 80;
        case 'weather':
          return 100;
        case 'departures':
          return 150;
        default:
          return 80;
      }
    }
    switch (widgetId) {
      case 'clock':
        return 120;
      case 'logo':
        return 120;
      case 'weather':
        return 150;
      case 'departures':
        return 200;
      default:
        return 100;
    }
  }
}
