import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/transport_type.dart';
import '../models/widget_layout.dart';
import '../services/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final double initialWeatherScale;
  final double initialDepartureScale;
  final String initialStationId;
  final TransportType initialTransportType;
  final int initialSkipMinutes;
  final int initialDurationMinutes;
  final bool initialShowWeatherActions;
  final Function(double, double, String, TransportType, int, int, bool) onSave;
  final Function(LayoutPreset)? onPresetSelected;

  const SettingsDialog({
    super.key,
    required this.initialWeatherScale,
    required this.initialDepartureScale,
    required this.initialStationId,
    required this.initialTransportType,
    required this.initialSkipMinutes,
    required this.initialDurationMinutes,
    required this.initialShowWeatherActions,
    required this.onSave,
    this.onPresetSelected,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _weatherScale;
  late double _departureScale;
  late String _selectedStationId;
  late TransportType _selectedTransportType;
  late int _skipMinutes;
  late int _durationMinutes;
  late bool _showWeatherActions;

  @override
  void initState() {
    super.initState();
    _weatherScale = widget.initialWeatherScale;
    _departureScale = widget.initialDepartureScale;
    _selectedStationId = widget.initialStationId;
    _selectedTransportType = widget.initialTransportType;
    _skipMinutes = widget.initialSkipMinutes;
    _durationMinutes = widget.initialDurationMinutes;
    _showWeatherActions = widget.initialShowWeatherActions;
  }

  Widget _buildLayoutPresetsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      childAspectRatio: 1.6,
      children: DashboardLayout.presets.map((preset) {
        return _buildPresetCard(preset);
      }).toList(),
    );
  }

  Widget _buildPresetCard(LayoutPreset preset) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          widget.onPresetSelected?.call(preset);
          Navigator.pop(context);
        },
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _buildPresetPreview(preset)),
              const SizedBox(height: 6),
              Text(
                preset.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                preset.description,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPresetPreview(LayoutPreset preset) {
    final layout = preset.landscapeLayout;
    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(4),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: layout.layouts.entries.map((entry) {
              final widgetLayout = entry.value;
              return Positioned(
                left: widgetLayout.x * constraints.maxWidth,
                top: widgetLayout.y * constraints.maxHeight,
                width: widgetLayout.width * constraints.maxWidth,
                height: widgetLayout.height * constraints.maxHeight,
                child: _buildSkeletonWidget(entry.key, constraints),
              );
            }).toList(),
          );
        },
      ),
    );
  }

  Widget _buildSkeletonWidget(
    String widgetId,
    BoxConstraints parentConstraints,
  ) {
    return Container(
      margin: const EdgeInsets.all(1),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(2),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.15),
          width: 0.5,
        ),
      ),
      clipBehavior: Clip.hardEdge,
      child: Center(child: _getSkeletonContent(widgetId)),
    );
  }

  Widget _getSkeletonContent(String widgetId) {
    switch (widgetId) {
      case 'clock':
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 28,
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 18,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ],
          ),
        );
      case 'logo':
        return Center(
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );
      case 'weather':
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 3),
              Column(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 12,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Container(
                    width: 8,
                    height: 3,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      case 'departures':
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Padding(
            padding: const EdgeInsets.all(4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (int i = 0; i < 4; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Container(
                      width: 60,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2 - (i * 0.04)),
                        borderRadius: BorderRadius.circular(1),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      default:
        return const SizedBox();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252931),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 600),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Settings',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Weather Font Size',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Row(
                  children: [
                    const Text(
                      'Normal',
                      style: TextStyle(color: Colors.white54),
                    ),
                    Expanded(
                      child: Slider(
                        value: _weatherScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: _weatherScale.toStringAsFixed(1),
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) {
                          setState(() => _weatherScale = value);
                        },
                      ),
                    ),
                    const Text(
                      'Large',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Departure Table Font Size',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Row(
                  children: [
                    const Text(
                      'Normal',
                      style: TextStyle(color: Colors.white54),
                    ),
                    Expanded(
                      child: Slider(
                        value: _departureScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: _departureScale.toStringAsFixed(1),
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) {
                          setState(() => _departureScale = value);
                        },
                      ),
                    ),
                    const Text(
                      'Large',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Default Station',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<String>(
                    value: _selectedStationId,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF252931),
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    items: Station.popularStations.map((station) {
                      return DropdownMenuItem(
                        value: station.id,
                        child: Text(station.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedStationId = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Default Transport Type',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: DropdownButton<TransportType>(
                    value: _selectedTransportType,
                    isExpanded: true,
                    dropdownColor: const Color(0xFF252931),
                    underline: const SizedBox(),
                    style: const TextStyle(color: Colors.white),
                    items: TransportType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Text(type.name),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedTransportType = value);
                      }
                    },
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Skip departures within ($_skipMinutes min)',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Row(
                  children: [
                    const Text('0', style: TextStyle(color: Colors.white54)),
                    Expanded(
                      child: Slider(
                        value: _skipMinutes.toDouble(),
                        min: 0,
                        max: 30,
                        divisions: 30,
                        label: '$_skipMinutes min',
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) {
                          setState(() => _skipMinutes = value.round());
                        },
                      ),
                    ),
                    const Text('30', style: TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 16),
                Text(
                  'Show departures within ($_durationMinutes min)',
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Row(
                  children: [
                    const Text('15', style: TextStyle(color: Colors.white54)),
                    Expanded(
                      child: Slider(
                        value: _durationMinutes.toDouble(),
                        min: 15,
                        max: 180,
                        divisions: 165,
                        label: '$_durationMinutes min',
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) {
                          setState(() => _durationMinutes = value.round());
                        },
                      ),
                    ),
                    const Text('180', style: TextStyle(color: Colors.white54)),
                  ],
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Weather Tips', style: TextStyle(color: Colors.white70)),
                  subtitle: const Text('Replace logo with AI weather recommendations', style: TextStyle(color: Colors.white54)),
                  value: _showWeatherActions,
                  onChanged: (value) {
                    setState(() {
                      _showWeatherActions = value;
                    });
                  },
                  contentPadding: EdgeInsets.zero,
                  activeColor: const Color(0xFF3B82F6),
                ),
                if (widget.onPresetSelected != null) ...[
                  const SizedBox(height: 24),
                  const Divider(color: Colors.white24),
                  const SizedBox(height: 16),
                  const Text(
                    'Layout Presets',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Quick-apply a layout style',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  _buildLayoutPresetsGrid(),
                ],
                const SizedBox(height: 32),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text(
                        'Cancel',
                        style: TextStyle(color: Colors.white54),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        await SettingsService.saveWeatherScale(_weatherScale);
                        await SettingsService.saveDepartureScale(
                          _departureScale,
                        );
                        await SettingsService.saveDefaultStationId(
                          _selectedStationId,
                        );
                        await SettingsService.saveDefaultTransportType(
                          _selectedTransportType,
                        );
                        await SettingsService.saveSkipMinutes(_skipMinutes);
                        await SettingsService.saveDurationMinutes(
                          _durationMinutes,
                        );
                        await SettingsService.saveShowWeatherActions(
                          _showWeatherActions,
                        );
                        widget.onSave(
                          _weatherScale,
                          _departureScale,
                          _selectedStationId,
                          _selectedTransportType,
                          _skipMinutes,
                          _durationMinutes,
                          _showWeatherActions,
                        );
                        if (context.mounted) Navigator.pop(context);
                      },
                      child: const Text('Save'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
