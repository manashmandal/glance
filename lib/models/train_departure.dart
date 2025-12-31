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

    // Regional trains
    if (upperLine.contains('RE1') || upperLine.contains('RE ')) {
      return const Color(0xFFEF4444); // Red
    } else if (upperLine.contains('FEX') ||
        upperLine.contains('RB') && upperLine.contains('10')) {
      return const Color(0xFF3B82F6); // Blue
    } else if (upperLine.startsWith('RE')) {
      return const Color(0xFFEF4444); // Red for all RE
    } else if (upperLine.startsWith('RB')) {
      return const Color(0xFF10B981); // Green for RB
    }

    // S-Bahn
    if (upperLine.startsWith('S') && !upperLine.startsWith('SB')) {
      return const Color(0xFF8B5CF6); // Purple
    }

    // U-Bahn
    if (upperLine.startsWith('U')) {
      return const Color(0xFF3B82F6); // Blue
    }

    // Tram/Straßenbahn (typically M lines or numbered lines in Berlin)
    if (upperLine.startsWith('M') || upperLine.startsWith('TRAM')) {
      return const Color(0xFFF59E0B); // Amber/Yellow
    }

    // Bus lines - different colors by type
    // MetroBus (M lines without tram)
    if (upperLine.contains('BUS')) {
      return const Color(0xFFA855F7); // Purple
    }

    // Express buses (X lines)
    if (upperLine.startsWith('X')) {
      return const Color(0xFF14B8A6); // Teal
    }

    // Night buses (N lines)
    if (upperLine.startsWith('N')) {
      return const Color(0xFF6366F1); // Indigo
    }

    // Regular buses (numbered, often 100-300 range in Berlin)
    if (RegExp(r'^\d+$').hasMatch(upperLine)) {
      final num = int.tryParse(upperLine) ?? 0;
      if (num >= 100 && num < 200) {
        return const Color(0xFFA855F7); // Purple for 100s
      } else if (num >= 200 && num < 300) {
        return const Color(0xFFEC4899); // Pink for 200s
      } else if (num >= 300) {
        return const Color(0xFF06B6D4); // Cyan for 300+
      }
    }

    // Default for other buses/transport
    return const Color(0xFFA855F7); // Purple default for buses
  }
}
