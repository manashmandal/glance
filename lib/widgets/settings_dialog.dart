import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/transport_type.dart';
import '../services/settings_service.dart';

class SettingsDialog extends StatefulWidget {
  final double initialWeatherScale;
  final String initialStationId;
  final TransportType initialTransportType;
  final Function(double, String, TransportType) onSave;

  const SettingsDialog({
    super.key,
    required this.initialWeatherScale,
    required this.initialStationId,
    required this.initialTransportType,
    required this.onSave,
  });

  @override
  State<SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<SettingsDialog> {
  late double _weatherScale;
  late String _selectedStationId;
  late TransportType _selectedTransportType;

  @override
  void initState() {
    super.initState();
    _weatherScale = widget.initialWeatherScale;
    _selectedStationId = widget.initialStationId;
    _selectedTransportType = widget.initialTransportType;
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252931),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
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
                  const Text('Normal', style: TextStyle(color: Colors.white54)),
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
                  const Text('Large', style: TextStyle(color: Colors.white54)),
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
                      await SettingsService.saveDefaultStationId(
                          _selectedStationId);
                      await SettingsService.saveDefaultTransportType(
                          _selectedTransportType);
                      widget.onSave(
                        _weatherScale,
                        _selectedStationId,
                        _selectedTransportType,
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
    );
  }
}
