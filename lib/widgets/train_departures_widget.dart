import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../models/train_departure.dart';
import '../models/station.dart';
import '../models/transport_type.dart';
import '../services/bvg_service.dart';
import '../services/theme_service.dart';

class TrainDeparturesWidget extends StatefulWidget {
  final Station? initialStation;
  final TransportType? initialTransportType;
  final double scaleFactor;
  final int skipMinutes;
  final int durationMinutes;
  final bool compactMode;

  const TrainDeparturesWidget({
    super.key,
    this.initialStation,
    this.initialTransportType,
    this.scaleFactor = 1.0,
    this.skipMinutes = 0,
    this.durationMinutes = 60,
    this.compactMode = false,
  });

  @override
  State<TrainDeparturesWidget> createState() => TrainDeparturesWidgetState();
}

class TrainDeparturesWidgetState extends State<TrainDeparturesWidget> {
  List<TrainDeparture> _departures = [];
  bool _isLoading = true;
  late Station _selectedStation;
  late TransportType _selectedTransportType;
  bool _isArrivalsMode =
      false; // false = departures (FROM), true = arrivals (TO)

  @override
  void initState() {
    super.initState();
    _selectedStation = widget.initialStation ?? Station.defaultStation;
    _selectedTransportType =
        widget.initialTransportType ?? TransportType.regional;
    refresh();
  }

  Future<void> refresh() async {
    if (!mounted) return;
    // Only show loading if empty
    if (_departures.isEmpty) {
      setState(() => _isLoading = true);
    }

    try {
      final List<TrainDeparture> results;
      if (_isArrivalsMode) {
        results = await BvgService.getArrivals(
          stationId: _selectedStation.id,
          transportType: _selectedTransportType,
          duration: widget.durationMinutes,
          skipMinutes: widget.skipMinutes,
        );
      } else {
        results = await BvgService.getDepartures(
          stationId: _selectedStation.id,
          transportType: _selectedTransportType,
          duration: widget.durationMinutes,
          skipMinutes: widget.skipMinutes,
        );
      }
      if (mounted) {
        setState(() {
          _departures = results;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading departures: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _loadDepartures() => refresh();

  void _onDirectionChanged(bool isArrivals) {
    if (isArrivals != _isArrivalsMode) {
      setState(() {
        _isArrivalsMode = isArrivals;
        _isLoading = true;
      });
      _loadDepartures();
    }
  }

  void _onStationChanged(Station? station) {
    if (station != null && station.id != _selectedStation.id) {
      setState(() {
        _selectedStation = station;
        _isLoading = true;
      });
      _loadDepartures();
    }
  }

  void _onTransportTypeChanged(TransportType? type) {
    if (type != null && type != _selectedTransportType) {
      setState(() {
        _selectedTransportType = type;
        _isLoading = true;
      });
      _loadDepartures();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF252931).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.1)
              : Colors.black.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: EdgeInsets.all(widget.compactMode ? 20 : 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                widget.compactMode ? _buildCompactHeader() : _buildFullHeader(),
                SizedBox(height: widget.compactMode ? 16 : 24),
                widget.compactMode
                    ? _buildCompactTableHeader()
                    : _buildFullTableHeader(),
                const SizedBox(height: 12),
                Expanded(
                  child: _departures.isEmpty && !_isLoading
                      ? Center(
                          child: Text(
                            'No ${_selectedTransportType == TransportType.bus ? 'bus' : 'train'} departures available',
                            style: TextStyle(color: context.textTertiary),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _departures.length,
                          itemBuilder: (context, index) {
                            final departure = _departures[index];
                            return widget.compactMode
                                ? CompactTrainRow(
                                    time: departure.time,
                                    departureTime: departure.departureTime,
                                    destination: departure.destination,
                                    line: departure.line,
                                    lineColor: departure.lineColor,
                                    status: departure.status,
                                    statusColor: departure.statusColor,
                                    scaleFactor: widget.scaleFactor,
                                  )
                                : TrainRow(
                                    time: departure.time,
                                    departureTime: departure.departureTime,
                                    destination: departure.destination,
                                    line: departure.line,
                                    lineColor: departure.lineColor,
                                    platform: departure.platform,
                                    status: departure.status,
                                    statusColor: departure.statusColor,
                                    scaleFactor: widget.scaleFactor,
                                  );
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textPrimary;
    final mutedColor = context.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // First row: title and FROM/TO toggle
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _selectedTransportType == TransportType.bus
                      ? Icons.directions_bus
                      : Icons.train,
                  color: textColor,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedTransportType.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    letterSpacing: -0.5,
                  ),
                ),
                if (_isLoading) ...[
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(mutedColor),
                    ),
                  ),
                ],
              ],
            ),
            // FROM/TO Toggle
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _onDirectionChanged(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: !_isArrivalsMode
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'FROM',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: !_isArrivalsMode ? Colors.white : mutedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onDirectionChanged(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _isArrivalsMode
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'TO',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: _isArrivalsMode ? Colors.white : mutedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Second row: Station dropdown (full width)
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.1)
                : Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.2)
                  : Colors.black.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: DropdownButton<Station>(
            value: _selectedStation,
            dropdownColor: isDark ? const Color(0xFF1A1D23) : Colors.white,
            underline: const SizedBox(),
            isDense: true,
            isExpanded: true,
            icon: Icon(
              Icons.keyboard_arrow_down,
              color: textColor,
              size: 18,
            ),
            selectedItemBuilder: (BuildContext context) {
              return Station.popularStations.map((Station station) {
                return Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    station.name,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }).toList();
            },
            items: Station.popularStations.map((Station station) {
              return DropdownMenuItem<Station>(
                value: station,
                child: Text(
                  station.name,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                  ),
                ),
              );
            }).toList(),
            onChanged: _onStationChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildFullHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textPrimary;
    final mutedColor = context.textTertiary;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          _isArrivalsMode ? 'Arrivals' : 'Departures',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: textColor,
            letterSpacing: -0.5,
          ),
        ),
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF3B82F6).withValues(alpha: 0.3),
                    const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                  ],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: const Color(0xFF3B82F6).withValues(alpha: 0.5),
                  width: 2,
                ),
              ),
              child: DropdownButton<TransportType>(
                value: _selectedTransportType,
                dropdownColor: isDark ? const Color(0xFF1A1D23) : Colors.white,
                underline: const SizedBox(),
                isDense: true,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: textColor,
                  size: 20,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return TransportType.values.map((TransportType type) {
                    return Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.filter_list, color: textColor, size: 16),
                        const SizedBox(width: 8),
                        Text(
                          type.shortName,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                      ],
                    );
                  }).toList();
                },
                items: TransportType.values.map((TransportType type) {
                  return DropdownMenuItem<TransportType>(
                    value: type,
                    child: Text(
                      type.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onTransportTypeChanged,
              ),
            ),
            const SizedBox(width: 16),
            Container(
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.1)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  GestureDetector(
                    onTap: () => _onDirectionChanged(false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: !_isArrivalsMode
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'FROM',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: !_isArrivalsMode ? Colors.white : mutedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onDirectionChanged(true),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: _isArrivalsMode
                            ? const Color(0xFF3B82F6)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'TO',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _isArrivalsMode ? Colors.white : mutedColor,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              _isArrivalsMode ? 'ARRIVING AT' : 'DEPARTING FROM',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: mutedColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.15)
                    : Colors.black.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.15),
                  width: 1.5,
                ),
              ),
              child: DropdownButton<Station>(
                value: _selectedStation,
                dropdownColor: isDark ? const Color(0xFF1A1D23) : Colors.white,
                underline: const SizedBox(),
                isDense: false,
                icon: Icon(
                  Icons.keyboard_arrow_down,
                  color: textColor,
                  size: 20,
                ),
                selectedItemBuilder: (BuildContext context) {
                  return Station.popularStations.map((Station station) {
                    return Center(
                      child: Text(
                        station.name,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                    );
                  }).toList();
                },
                items: Station.popularStations.map((Station station) {
                  return DropdownMenuItem<Station>(
                    value: station,
                    child: Text(
                      station.name,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                      ),
                    ),
                  );
                }).toList(),
                onChanged: _onStationChanged,
              ),
            ),
            const SizedBox(width: 12),
            if (_isLoading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(mutedColor),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactTableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = context.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 12 * widget.scaleFactor,
        vertical: 10 * widget.scaleFactor,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50 * widget.scaleFactor,
            child: Text(
              'Min',
              style: TextStyle(
                fontSize: 13 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          SizedBox(
            width: 70 * widget.scaleFactor,
            child: Text(
              'Line',
              style: TextStyle(
                fontSize: 13 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          Expanded(
            child: Text(
              _isArrivalsMode ? 'Origin' : 'Destination',
              style: TextStyle(
                fontSize: 13 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          SizedBox(
            width: 70 * widget.scaleFactor,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 13 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFullTableHeader() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColor = context.textSecondary;

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: 20 * widget.scaleFactor,
        vertical: 16 * widget.scaleFactor,
      ),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100 * widget.scaleFactor,
            child: Text(
              'Time',
              style: TextStyle(
                fontSize: 16 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          SizedBox(
            width: 80 * widget.scaleFactor,
            child: Text(
              'Min',
              style: TextStyle(
                fontSize: 16 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              _isArrivalsMode ? 'Origin' : 'Destination',
              style: TextStyle(
                fontSize: 16 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          SizedBox(
            width: 160 * widget.scaleFactor,
            child: Padding(
              padding: EdgeInsets.only(left: 20 * widget.scaleFactor),
              child: Text(
                'Line',
                style: TextStyle(
                  fontSize: 16 * widget.scaleFactor,
                  fontWeight: FontWeight.w600,
                  color: headerColor,
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120 * widget.scaleFactor,
            child: Text(
              'Platform',
              style: TextStyle(
                fontSize: 16 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
          SizedBox(
            width: 140 * widget.scaleFactor,
            child: Text(
              'Status',
              style: TextStyle(
                fontSize: 16 * widget.scaleFactor,
                fontWeight: FontWeight.w600,
                color: headerColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TrainRow extends StatelessWidget {
  final String time;
  final DateTime? departureTime;
  final String destination;
  final String line;
  final Color lineColor;
  final String platform;
  final String status;
  final Color statusColor;
  final double scaleFactor;

  const TrainRow({
    super.key,
    required this.time,
    this.departureTime,
    required this.destination,
    required this.line,
    required this.lineColor,
    required this.platform,
    required this.status,
    required this.statusColor,
    this.scaleFactor = 1.0,
  });

  String get _formattedMinutes {
    if (departureTime == null) return '';
    final diff = departureTime!.difference(DateTime.now());
    final minutes = diff.inMinutes;
    if (minutes < 0) return 'Dep.';
    if (minutes == 0) return 'Now';
    return '$minutes\'';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textPrimary;
    final mutedColor = context.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 100 * scaleFactor,
            child: Text(
              time,
              style: TextStyle(
                fontSize: 20 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: textColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 80 * scaleFactor,
            child: Text(
              _formattedMinutes,
              style: TextStyle(
                fontSize: 20 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: mutedColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              destination,
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 160 * scaleFactor,
            child: Padding(
              padding: EdgeInsets.only(left: 20 * scaleFactor),
              child: UnconstrainedBox(
                alignment: Alignment.centerLeft,
                child: Container(
                  constraints: BoxConstraints(
                      minWidth: 60 * scaleFactor, maxWidth: 140 * scaleFactor),
                  padding: EdgeInsets.symmetric(
                      horizontal: 12 * scaleFactor, vertical: 6 * scaleFactor),
                  decoration: BoxDecoration(
                    color: lineColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: lineColor.withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 6 * scaleFactor,
                        height: 6 * scaleFactor,
                        decoration: BoxDecoration(
                          color: lineColor,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: lineColor.withValues(alpha: 0.5),
                              blurRadius: 4,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                      ),
                      SizedBox(width: 8 * scaleFactor),
                      Flexible(
                        child: Text(
                          line,
                          style: TextStyle(
                            fontSize: 14 * scaleFactor,
                            fontWeight: FontWeight.w700,
                            color: lineColor,
                            letterSpacing: 0.5,
                            height: 1.1,
                          ),
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120 * scaleFactor,
            child: Text(
              platform,
              style: TextStyle(
                fontSize: 18 * scaleFactor,
                fontWeight: FontWeight.w500,
                color: mutedColor,
              ),
            ),
          ),
          SizedBox(
            width: 140 * scaleFactor,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CompactTrainRow extends StatelessWidget {
  final String time;
  final DateTime? departureTime;
  final String destination;
  final String line;
  final Color lineColor;
  final String status;
  final Color statusColor;
  final double scaleFactor;

  const CompactTrainRow({
    super.key,
    required this.time,
    this.departureTime,
    required this.destination,
    required this.line,
    required this.lineColor,
    required this.status,
    required this.statusColor,
    this.scaleFactor = 1.0,
  });

  String get _formattedMinutes {
    if (departureTime == null) return '';
    final diff = departureTime!.difference(DateTime.now());
    final minutes = diff.inMinutes;
    if (minutes < 0) return 'Dep.';
    if (minutes == 0) return 'Now';
    return '$minutes\'';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = context.textPrimary;
    final mutedColor = context.textSecondary;

    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      decoration: BoxDecoration(
        color: isDark
            ? Colors.white.withValues(alpha: 0.03)
            : Colors.black.withValues(alpha: 0.02),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.05)
              : Colors.black.withValues(alpha: 0.05),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 50 * scaleFactor,
            child: Text(
              _formattedMinutes,
              style: TextStyle(
                fontSize: 16 * scaleFactor,
                fontWeight: FontWeight.bold,
                color: mutedColor,
                fontFeatures: const [FontFeature.tabularFigures()],
              ),
            ),
          ),
          SizedBox(
            width: 70 * scaleFactor,
            child: Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8 * scaleFactor, vertical: 4 * scaleFactor),
              decoration: BoxDecoration(
                color: lineColor.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: lineColor.withValues(alpha: 0.4),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5 * scaleFactor,
                    height: 5 * scaleFactor,
                    decoration: BoxDecoration(
                      color: lineColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  SizedBox(width: 4 * scaleFactor),
                  Flexible(
                    child: Text(
                      line.length > 5 ? line.substring(0, 5) : line,
                      style: TextStyle(
                        fontSize: 11 * scaleFactor,
                        fontWeight: FontWeight.w700,
                        color: lineColor,
                        letterSpacing: 0.3,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text(
                destination,
                style: TextStyle(
                  fontSize: 14 * scaleFactor,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          SizedBox(
            width: 70 * scaleFactor,
            child: Text(
              status == 'On Time' ? '✓' : status,
              style: TextStyle(
                fontSize: 12 * scaleFactor,
                fontWeight: FontWeight.w600,
                color: statusColor,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
