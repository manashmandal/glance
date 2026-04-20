import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../data/api_diagnostics.dart';
import '../models/journey.dart';
import '../models/train_departure.dart';
import '../models/transport_type.dart';

class BvgService {
  static const String baseUrl = 'https://v6.bvg.transport.rest';

  static Future<List<TrainDeparture>> fetchArrivals({
    required String stationId,
    int duration = 60,
    TransportType transportType = TransportType.regional,
    int skipMinutes = 0,
  }) async {
    try {
      final filters = _transportFilters(transportType);
      final url =
          '$baseUrl/stops/$stationId/arrivals?duration=$duration&results=20$filters';
      print('\n========== BVG API CALL (ARRIVALS) ==========');
      print('URL: $url');
      print('Station ID: $stationId');
      print('Skip minutes: $skipMinutes');
      print('Timestamp: ${DateTime.now()}');

      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        print('✅ API SUCCESS - Parsing JSON...');
        final data = json.decode(response.body);
        print('JSON Keys: ${data.keys.join(", ")}');

        final arrivals = data['arrivals'] as List?;
        print('Arrivals in response: ${arrivals?.length ?? 0}');

        if (arrivals == null || arrivals.isEmpty) {
          print('❌ ERROR: No arrivals in API response');
          print(
            'First 500 chars of response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          return _fallbackData();
        }

        print('\n--- Processing Arrivals ---');
        final trainArrivals = <TrainDeparture>[];
        final now = DateTime.now();
        final skipUntil = now.add(Duration(minutes: skipMinutes));

        for (var i = 0; i < arrivals.length && trainArrivals.length < 5; i++) {
          try {
            final arr = arrivals[i];
            final whenString = arr['when'] as String?;

            if (whenString == null) {
              print('\nArrival #$i skipped (missing arrival time)');
              continue;
            }

            final arrivalTime = DateTime.parse(whenString).toLocal();

            // Skip arrivals that are before the skip threshold
            if (arrivalTime.isBefore(skipUntil)) {
              print(
                '\nArrival #$i skipped (within skip window of $skipMinutes min)',
              );
              continue;
            }

            final lineName = arr['line']?['name'] as String? ?? '';
            if (!_matchesTransportType(lineName, transportType)) {
              print(
                '\nArrival #$i skipped (line $lineName not matching ${transportType.name})',
              );
              continue;
            }

            final originName = arr['provenance'] as String? ?? 'Unknown';
            print('\nArrival #$i raw data:');
            print('  when: ${arr['when']}');
            print('  line: $lineName');
            print('  origin: $originName');
            print('  platform: ${arr['platform']}');

            final arrival = TrainDeparture.fromArrivalJson(arr);
            trainArrivals.add(arrival);
            print(
              '  ✅ Parsed: ${arrival.time} - ${arrival.line} from ${arrival.destination}',
            );
          } catch (e, stack) {
            print('  ❌ Error parsing arrival $i: $e');
            print(
              '  Stack: ${stack.toString().split('\n').take(3).join('\n')}',
            );
          }
        }

        return trainArrivals.isNotEmpty ? trainArrivals : _fallbackData();
      } else {
        return _fallbackData();
      }
    } catch (e) {
      return _fallbackData();
    }
  }

  static Future<List<TrainDeparture>> fetchDepartures({
    required String stationId,
    int duration = 60,
    TransportType transportType = TransportType.regional,
    int skipMinutes = 0,
  }) async {
    final sw = Stopwatch()..start();
    final endpoint =
        'v6.bvg.transport.rest/stops/$stationId/departures';
    try {
      final filters = _transportFilters(transportType);
      final url =
          '$baseUrl/stops/$stationId/departures?duration=$duration&results=20$filters';
      print('\n========== BVG API CALL ==========');
      print('URL: $url');
      print('Station ID: $stationId');
      print('Skip minutes: $skipMinutes');
      print('Timestamp: ${DateTime.now()}');

      final response = await http.get(Uri.parse(url), headers: {
        'Accept': 'application/json'
      }).timeout(const Duration(seconds: 10));

      print('Response Status Code: ${response.statusCode}');
      print('Response Body Length: ${response.body.length} bytes');

      if (response.statusCode == 200) {
        print('✅ API SUCCESS - Parsing JSON...');
        final data = json.decode(response.body);
        print('JSON Keys: ${data.keys.join(", ")}');

        final departures = data['departures'] as List?;
        print('Departures in response: ${departures?.length ?? 0}');

        if (departures == null || departures.isEmpty) {
          print('❌ ERROR: No departures in API response');
          print(
            'First 500 chars of response: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}',
          );
          sw.stop();
          _recordBvg(endpoint, sw,
              success: false, code: response.statusCode, label: '200 · empty');
          return _fallbackData();
        }

        print('\n--- Processing Departures ---');
        final trainDepartures = <TrainDeparture>[];
        final now = DateTime.now();
        final skipUntil = now.add(Duration(minutes: skipMinutes));

        for (var i = 0;
            i < departures.length && trainDepartures.length < 5;
            i++) {
          try {
            final dep = departures[i];
            final whenString = dep['when'] as String?;

            final destinationName = dep['destination']?['name'] as String?;

            if (whenString == null) {
              print('\nDeparture #$i skipped (missing departure time)');
              continue;
            }

            final departureTime = DateTime.parse(whenString).toLocal();

            // Skip departures that are before the skip threshold
            if (departureTime.isBefore(skipUntil)) {
              print(
                '\nDeparture #$i skipped (within skip window of $skipMinutes min)',
              );
              continue;
            }

            if (destinationName != null) {
              final destLower = destinationName.toLowerCase();
              if ((stationId.contains('29101') &&
                      destLower.contains('spandau')) ||
                  (stationId.contains('3201') &&
                      destLower.contains('hauptbahnhof')) ||
                  (stationId.contains('100003') &&
                      destLower.contains('alexanderplatz'))) {
                continue;
              }
            }

            final lineName = dep['line']?['name'] as String? ?? '';
            if (!_matchesTransportType(lineName, transportType)) {
              print(
                '\nDeparture #$i skipped (line $lineName not matching ${transportType.name})',
              );
              continue;
            }

            print('\nDeparture #$i raw data:');
            print('  when: ${dep['when']}');
            print('  line: $lineName');
            print('  destination: $destinationName');
            print('  platform: ${dep['platform']}');

            final departure = TrainDeparture.fromJson(dep);
            trainDepartures.add(departure);
            print(
              '  ✅ Parsed: ${departure.time} - ${departure.line} to ${departure.destination}',
            );
          } catch (e, stack) {
            print('  ❌ Error parsing departure $i: $e');
            print(
              '  Stack: ${stack.toString().split('\n').take(3).join('\n')}',
            );
          }
        }

        sw.stop();
        if (trainDepartures.isEmpty) {
          _recordBvg(endpoint, sw,
              success: false,
              code: response.statusCode,
              label: '200 · 0 items');
          return _fallbackData();
        }
        _recordBvg(endpoint, sw, success: true, code: response.statusCode);
        return trainDepartures;
      } else {
        sw.stop();
        _recordBvg(endpoint, sw, success: false, code: response.statusCode);
        return _fallbackData();
      }
    } catch (e) {
      sw.stop();
      _recordBvg(endpoint, sw, success: false, error: e);
      debugPrint('❌ BVG outer catch (departures): $e');
      return _fallbackData();
    }
  }

  static Future<Journey?> fetchJourney({
    required String fromStationId,
    required String toStationId,
  }) async {
    final sw = Stopwatch()..start();
    final endpoint = 'v6.bvg.transport.rest/journeys';
    try {
      final url =
          '$baseUrl/journeys?from=$fromStationId&to=$toStationId&results=3&stopovers=false';
      print('\n========== BVG API CALL (JOURNEYS) ==========');
      print('URL: $url');

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200) {
        sw.stop();
        _recordBvg(endpoint, sw, success: false, code: response.statusCode);
        print('❌ Journeys API returned ${response.statusCode}');
        return null;
      }

      final data = json.decode(response.body);
      final journeys = data['journeys'] as List?;
      if (journeys == null || journeys.isEmpty) {
        sw.stop();
        _recordBvg(endpoint, sw,
            success: false, code: 200, label: '200 · empty');
        return null;
      }

      final now = DateTime.now();
      Map<String, dynamic>? picked;
      for (final j in journeys.whereType<Map<String, dynamic>>()) {
        final legs = j['legs'] as List?;
        if (legs == null || legs.isEmpty) continue;
        final first = legs.first as Map<String, dynamic>;
        final dep = first['departure'] as String? ??
            first['plannedDeparture'] as String?;
        if (dep == null) continue;
        final depTime = DateTime.tryParse(dep)?.toLocal();
        if (depTime == null) continue;
        if (depTime.isBefore(now)) continue;
        picked = j;
        break;
      }
      picked ??= journeys.first as Map<String, dynamic>;
      sw.stop();
      _recordBvg(endpoint, sw, success: true, code: 200);
      return Journey.fromJson(picked);
    } catch (e) {
      sw.stop();
      _recordBvg(endpoint, sw, success: false, error: e);
      print('❌ Journeys API error: $e');
      return null;
    }
  }

  static void _recordBvg(
    String endpoint,
    Stopwatch sw, {
    required bool success,
    int? code,
    Object? error,
    String? label,
  }) {
    final duration = sw.elapsed;
    String resolved;
    if (label != null) {
      resolved = label;
    } else if (error != null) {
      if (error is TimeoutException) {
        resolved = 'timeout · ${duration.inSeconds}s';
      } else {
        resolved = 'error · ${error.runtimeType}';
      }
    } else if (code == 200) {
      final ms = duration.inMilliseconds;
      resolved = ms >= 1000
          ? '200 · ${(ms / 1000).toStringAsFixed(1)}s'
          : '200 · ${ms}ms';
    } else {
      resolved = '${code ?? 'fail'} · ${duration.inSeconds}s';
    }
    ApiDiagnostics.record(ApiAttempt(
      endpoint: endpoint,
      statusLabel: resolved,
      success: success,
      at: DateTime.now(),
      source: ApiSource.bvg,
    ));
  }

  static List<TrainDeparture> _fallbackData() {
    final now = DateTime.now();
    final hour12 =
        now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final currentTime =
        '${hour12}:${now.minute.toString().padLeft(2, '0')} $period';

    return [
      TrainDeparture(
        time: currentTime,
        destination: 'No live data available',
        line: 'N/A',
        lineColor: const Color(0xFF6B7280),
        platform: '-',
        status: 'Check connection',
        statusColor: const Color(0xFFEF4444),
      ),
    ];
  }

  static String _transportFilters(TransportType type) {
    switch (type) {
      case TransportType.regional:
        return '&regional=true&express=true&suburban=false&subway=false&bus=false&tram=false&ferry=false';
      case TransportType.sBahn:
        return '&suburban=true&regional=false&express=false&subway=false&bus=false&tram=false&ferry=false';
      case TransportType.uBahn:
        return '&subway=true&suburban=false&regional=false&express=false&bus=false&tram=false&ferry=false';
      case TransportType.bus:
        return '&bus=true&tram=true&suburban=false&subway=false&regional=false&express=false&ferry=false';
    }
  }

  static bool _matchesTransportType(String lineName, TransportType type) {
    final line = lineName.toUpperCase();
    switch (type) {
      case TransportType.regional:
        return line.startsWith('RE') ||
            line.startsWith('RB') ||
            line.startsWith('IC') ||
            line.startsWith('ICE') ||
            line.startsWith('EC') ||
            line.startsWith('FEX');
      case TransportType.sBahn:
        return line.startsWith('S') && !line.startsWith('SB');
      case TransportType.uBahn:
        return line.startsWith('U') && line.length <= 3;
      case TransportType.bus:
        return !line.startsWith('RE') &&
            !line.startsWith('RB') &&
            !line.startsWith('S') &&
            !line.startsWith('U') &&
            !line.startsWith('IC');
    }
  }
}
