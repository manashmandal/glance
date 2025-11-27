import 'package:flutter/material.dart';

class TrainDeparture {
  final String time;
  final String destination;
  final String line;
  final Color lineColor;
  final String platform;
  final String status;
  final Color statusColor;
  final int? delay;
  final DateTime? departureTime;

  TrainDeparture({
    required this.time,
    required this.destination,
    required this.line,
    required this.lineColor,
    required this.platform,
    required this.status,
    required this.statusColor,
    this.delay,
    this.departureTime,
  });

  factory TrainDeparture.fromJson(Map<String, dynamic> json) {
    final when = json['when'] as String?;
    final plannedWhen = json['plannedWhen'] as String?;
    final destination = json['destination']?['name'] as String? ?? 'Unknown';
    final line = json['line']?['name'] as String? ?? 'N/A';
    final platform = json['platform'] as String? ?? '-';
    final delay = json['delay'] as int?;

    final timeString = when ?? plannedWhen ?? '';
    String time = 'N/A';
    DateTime? parsedDateTime;
    if (timeString.isNotEmpty) {
      try {
        parsedDateTime = DateTime.parse(timeString).toLocal();
        final hour = parsedDateTime.hour;
        final minute = parsedDateTime.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        time = '${hour12}:${minute.toString().padLeft(2, '0')} $period';
        print(
            'Time conversion: $timeString -> ${parsedDateTime.toString()} -> $time');
      } catch (e) {
        time = 'N/A';
      }
    }

    String status;
    Color statusColor;
    if (delay != null && delay > 0) {
      status = '+${(delay / 60).round()} min Delay';
      statusColor = const Color(0xFFFBBF24);
    } else if (json['cancelled'] == true) {
      status = 'Cancelled';
      statusColor = const Color(0xFFEF4444);
    } else {
      status = 'On Time';
      statusColor = const Color(0xFF10B981);
    }

    Color lineColor = _getLineColor(line);

    return TrainDeparture(
      time: time,
      destination: destination,
      line: line,
      lineColor: lineColor,
      platform: platform.isEmpty ? '-' : 'Pl. $platform',
      status: status,
      statusColor: statusColor,
      delay: delay,
      departureTime: parsedDateTime,
    );
  }

  factory TrainDeparture.fromArrivalJson(Map<String, dynamic> json) {
    final when = json['when'] as String?;
    final plannedWhen = json['plannedWhen'] as String?;
    // For arrivals, 'provenance' is the origin station (where the train is coming FROM)
    final origin = json['provenance'] as String? ?? 'Unknown';
    final line = json['line']?['name'] as String? ?? 'N/A';
    final platform = json['platform'] as String? ?? '-';
    final delay = json['delay'] as int?;

    final timeString = when ?? plannedWhen ?? '';
    String time = 'N/A';
    DateTime? parsedDateTime;
    if (timeString.isNotEmpty) {
      try {
        parsedDateTime = DateTime.parse(timeString).toLocal();
        final hour = parsedDateTime.hour;
        final minute = parsedDateTime.minute;
        final period = hour >= 12 ? 'PM' : 'AM';
        final hour12 = hour > 12 ? hour - 12 : (hour == 0 ? 12 : hour);
        time = '${hour12}:${minute.toString().padLeft(2, '0')} $period';
        print(
            'Arrival time conversion: $timeString -> ${parsedDateTime.toString()} -> $time');
      } catch (e) {
        time = 'N/A';
      }
    }

    String status;
    Color statusColor;
    if (delay != null && delay > 0) {
      status = '+${(delay / 60).round()} min Delay';
      statusColor = const Color(0xFFFBBF24);
    } else if (json['cancelled'] == true) {
      status = 'Cancelled';
      statusColor = const Color(0xFFEF4444);
    } else {
      status = 'On Time';
      statusColor = const Color(0xFF10B981);
    }

    Color lineColor = _getLineColor(line);

    return TrainDeparture(
      time: time,
      destination: origin, // For arrivals, we show the origin as "destination" (where it's coming FROM)
      line: line,
      lineColor: lineColor,
      platform: platform.isEmpty ? '-' : 'Pl. $platform',
      status: status,
      statusColor: statusColor,
      delay: delay,
      departureTime: parsedDateTime,
    );
  }

  static Color _getLineColor(String line) {
    final upperLine = line.toUpperCase();
    if (upperLine.contains('RE1') || upperLine.contains('RE ')) {
      return const Color(0xFFEF4444);
    } else if (upperLine.contains('FEX') ||
        upperLine.contains('RB') && upperLine.contains('10')) {
      return const Color(0xFF3B82F6);
    } else if (upperLine.contains('RB')) {
      return const Color(0xFF10B981);
    } else if (upperLine.contains('S')) {
      return const Color(0xFF8B5CF6);
    }
    return const Color(0xFF6B7280);
  }
}
