import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../models/train_departure.dart';
import '../models/station.dart';
import '../models/transport_type.dart';
import '../services/bvg_service.dart';

class TrainDeparturesWidget extends StatefulWidget {
  final Station? initialStation;
  final TransportType? initialTransportType;
  final double scaleFactor;
  final int skipMinutes;
  final int durationMinutes;

  const TrainDeparturesWidget({
    super.key,
    this.initialStation,
    this.initialTransportType,
    this.scaleFactor = 1.0,
    this.skipMinutes = 0,
    this.durationMinutes = 60,
  });

  @override
  State<TrainDeparturesWidget> createState() => TrainDeparturesWidgetState();
}

class TrainDeparturesWidgetState extends State<TrainDeparturesWidget> {
  List<TrainDeparture> _departures = [];
  bool _isLoading = true;
  late Station _selectedStation;
  late TransportType _selectedTransportType;
  bool _isArrivalsMode = false; // false = departures (FROM), true = arrivals (TO)

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
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF252931).withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
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
            padding: const EdgeInsets.all(32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _isArrivalsMode ? 'Arrivals' : 'Departures',
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color(0xFF3B82F6).withValues(alpha: 0.3),
                                const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                              ],
                            ),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF3B82F6)
                                  .withValues(alpha: 0.5),
                              width: 2,
                            ),
                          ),
                          child: DropdownButton<TransportType>(
                            value: _selectedTransportType,
                            dropdownColor: const Color(0xFF1A1D23),
                            underline: const SizedBox(),
                            isDense: true,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return TransportType.values
                                  .map((TransportType type) {
                                return Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.filter_list,
                                        color: Colors.white, size: 16),
                                    const SizedBox(width: 8),
                                    Text(
                                      type.shortName,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                );
                              }).toList();
                            },
                            items:
                                TransportType.values.map((TransportType type) {
                              return DropdownMenuItem<TransportType>(
                                value: type,
                                child: Text(
                                  type.name,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: _onTransportTypeChanged,
                          ),
                        ),
                        const SizedBox(width: 16),
                        // FROM/TO Toggle
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.2),
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
                                      color: !_isArrivalsMode
                                          ? Colors.white
                                          : Colors.white54,
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
                                      color: _isArrivalsMode
                                          ? Colors.white
                                          : Colors.white54,
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
                            color: Colors.white.withValues(alpha: 0.5),
                            letterSpacing: 1.0,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.3),
                              width: 1.5,
                            ),
                          ),
                          child: DropdownButton<Station>(
                            value: _selectedStation,
                            dropdownColor: const Color(0xFF1A1D23),
                            underline: const SizedBox(),
                            isDense: false,
                            icon: const Icon(
                              Icons.keyboard_arrow_down,
                              color: Colors.white,
                              size: 20,
                            ),
                            selectedItemBuilder: (BuildContext context) {
                              return Station.popularStations
                                  .map((Station station) {
                                return Center(
                                  child: Text(
                                    station.name,
                                    style: const TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                );
                              }).toList();
                            },
                            items:
                                Station.popularStations.map((Station station) {
                              return DropdownMenuItem<Station>(
                                value: station,
                                child: Text(
                                  station.name,
                                  style: const TextStyle(
                                    color: Colors.white,
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
                          const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white54),
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 20 * widget.scaleFactor,
                    vertical: 16 * widget.scaleFactor,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                              color: Colors.white.withValues(alpha: 0.7),
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
                            color: Colors.white.withValues(alpha: 0.7),
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
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: _departures.isEmpty && !_isLoading
                      ? const Center(
                          child: Text(
                            'No departures available',
                            style: TextStyle(color: Colors.white54),
                          ),
                        )
                      : ListView.builder(
                          itemCount: _departures.length,
                          itemBuilder: (context, index) {
                            final departure = _departures[index];
                            return TrainRow(
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
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.05),
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
                color: Colors.white,
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
                color: Colors.white70,
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
                color: Colors.white,
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
                color: Colors.white.withValues(alpha: 0.8),
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
