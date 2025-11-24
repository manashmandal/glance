import 'package:flutter/material.dart';
import 'dart:ui';
import 'dart:async';
import '../models/train_departure.dart';
import '../models/station.dart';
import '../models/transport_type.dart';
import '../services/bvg_service.dart';

class TrainDeparturesWidget extends StatefulWidget {
  const TrainDeparturesWidget({super.key});

  @override
  State<TrainDeparturesWidget> createState() => _TrainDeparturesWidgetState();
}

class _TrainDeparturesWidgetState extends State<TrainDeparturesWidget> {
  List<TrainDeparture> _departures = [];
  bool _isLoading = true;
  Timer? _refreshTimer;
  Station _selectedStation = Station.defaultStation;
  TransportType _selectedTransportType = TransportType.regional;

  @override
  void initState() {
    super.initState();
    _loadDepartures();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      _loadDepartures();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadDepartures() async {
    setState(() => _isLoading = true);
    final departures = await BvgService.getDepartures(
      stationId: _selectedStation.id,
      transportType: _selectedTransportType,
    );
    if (mounted) {
      setState(() {
        _departures = departures;
        _isLoading = false;
      });
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
                    const Text(
                      'Regional Train Departures',
                      style: TextStyle(
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
                        Text(
                          'DEPARTING FROM',
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
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Time',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 4,
                        child: Text(
                          'Destination',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 160,
                        child: Padding(
                          padding: const EdgeInsets.only(left: 20),
                          child: Text(
                            'Line',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.7),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 120,
                        child: Text(
                          'Platform',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.7),
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 140,
                        child: Text(
                          'Status',
                          style: TextStyle(
                            fontSize: 16,
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
                              destination: departure.destination,
                              line: departure.line,
                              lineColor: departure.lineColor,
                              platform: departure.platform,
                              status: departure.status,
                              statusColor: departure.statusColor,
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
  final String destination;
  final String line;
  final Color lineColor;
  final String platform;
  final String status;
  final Color statusColor;

  const TrainRow({
    super.key,
    required this.time,
    required this.destination,
    required this.line,
    required this.lineColor,
    required this.platform,
    required this.status,
    required this.statusColor,
  });

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
            width: 100,
            child: Text(
              time,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ),
          Expanded(
            flex: 4,
            child: Text(
              destination,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          SizedBox(
            width: 160,
            child: Padding(
              padding: const EdgeInsets.only(left: 20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 120),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: lineColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
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
                      width: 8,
                      height: 8,
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
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        line,
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: lineColor,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: 120,
            child: Text(
              platform,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
          ),
          SizedBox(
            width: 140,
            child: Text(
              status,
              style: TextStyle(
                fontSize: 16,
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
