# Multi-Network Transit Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Expand transit support from Berlin-only to 10 German networks with GPS-based station detection.

**Architecture:** Provider pattern with configurable network endpoints. Single TransitProviderService handles all transport.rest APIs. LocationService for GPS. Settings stores network/station/categories.

**Tech Stack:** Flutter, geolocator package, transport.rest APIs, SharedPreferences

---

## Phase 1: Foundation Models

### Task 1: Create TransitNetwork Model

**Files:**
- Create: `lib/models/transit_network.dart`
- Test: `test/models/transit_network_test.dart`

**Step 1: Write the failing test**

```dart
// test/models/transit_network_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/transit_network.dart';

void main() {
  group('TransitNetwork', () {
    test('creates network with required fields', () {
      final network = TransitNetwork(
        id: 'vbb',
        name: 'Berlin-Brandenburg',
        city: 'Berlin',
        baseUrl: 'https://v6.vbb.transport.rest',
        latitude: 52.52,
        longitude: 13.405,
        searchTerms: ['Berlin', 'Potsdam', 'Brandenburg'],
      );

      expect(network.id, 'vbb');
      expect(network.name, 'Berlin-Brandenburg');
      expect(network.city, 'Berlin');
      expect(network.baseUrl, 'https://v6.vbb.transport.rest');
      expect(network.latitude, 52.52);
      expect(network.longitude, 13.405);
      expect(network.searchTerms, ['Berlin', 'Potsdam', 'Brandenburg']);
    });

    test('matchesSearch returns true for matching city', () {
      final network = TransitNetwork(
        id: 'vbb',
        name: 'Berlin-Brandenburg',
        city: 'Berlin',
        baseUrl: 'https://v6.vbb.transport.rest',
        latitude: 52.52,
        longitude: 13.405,
        searchTerms: ['Berlin', 'Potsdam'],
      );

      expect(network.matchesSearch('berlin'), true);
      expect(network.matchesSearch('BERLIN'), true);
      expect(network.matchesSearch('Ber'), true);
      expect(network.matchesSearch('potsdam'), true);
      expect(network.matchesSearch('hamburg'), false);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/transit_network_test.dart`
Expected: FAIL with "Target of URI hasn't been generated"

**Step 3: Write minimal implementation**

```dart
// lib/models/transit_network.dart
class TransitNetwork {
  final String id;
  final String name;
  final String city;
  final String baseUrl;
  final double latitude;
  final double longitude;
  final List<String> searchTerms;

  const TransitNetwork({
    required this.id,
    required this.name,
    required this.city,
    required this.baseUrl,
    required this.latitude,
    required this.longitude,
    required this.searchTerms,
  });

  bool matchesSearch(String query) {
    final lowerQuery = query.toLowerCase();
    if (city.toLowerCase().contains(lowerQuery)) return true;
    if (name.toLowerCase().contains(lowerQuery)) return true;
    for (final term in searchTerms) {
      if (term.toLowerCase().contains(lowerQuery)) return true;
    }
    return false;
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/transit_network_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/transit_network.dart test/models/transit_network_test.dart
git commit -m "feat: add TransitNetwork model"
```

---

### Task 2: Create TransportCategory Enum

**Files:**
- Create: `lib/models/transport_category.dart`
- Test: `test/models/transport_category_test.dart`

**Step 1: Write the failing test**

```dart
// test/models/transport_category_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/transport_category.dart';

void main() {
  group('TransportCategory', () {
    test('has three categories', () {
      expect(TransportCategory.values.length, 3);
      expect(TransportCategory.values, contains(TransportCategory.rail));
      expect(TransportCategory.values, contains(TransportCategory.metro));
      expect(TransportCategory.values, contains(TransportCategory.surface));
    });

    test('has correct display names', () {
      expect(TransportCategory.rail.displayName, 'Rail');
      expect(TransportCategory.metro.displayName, 'Metro');
      expect(TransportCategory.surface.displayName, 'Surface');
    });

    test('has correct descriptions', () {
      expect(TransportCategory.rail.description, 'Regional, S-Bahn, IC, ICE');
      expect(TransportCategory.metro.description, 'U-Bahn, Stadtbahn');
      expect(TransportCategory.surface.description, 'Bus, Tram, Ferry');
    });

    test('apiFilters returns correct filter string for rail', () {
      expect(
        TransportCategory.rail.apiFilters,
        '&regional=true&express=true&suburban=true&subway=false&bus=false&tram=false&ferry=false',
      );
    });

    test('apiFilters returns correct filter string for metro', () {
      expect(
        TransportCategory.metro.apiFilters,
        '&regional=false&express=false&suburban=false&subway=true&bus=false&tram=false&ferry=false',
      );
    });

    test('apiFilters returns correct filter string for surface', () {
      expect(
        TransportCategory.surface.apiFilters,
        '&regional=false&express=false&suburban=false&subway=false&bus=true&tram=true&ferry=true',
      );
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/transport_category_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

```dart
// lib/models/transport_category.dart
enum TransportCategory {
  rail(
    'Rail',
    'Regional, S-Bahn, IC, ICE',
    '&regional=true&express=true&suburban=true&subway=false&bus=false&tram=false&ferry=false',
  ),
  metro(
    'Metro',
    'U-Bahn, Stadtbahn',
    '&regional=false&express=false&suburban=false&subway=true&bus=false&tram=false&ferry=false',
  ),
  surface(
    'Surface',
    'Bus, Tram, Ferry',
    '&regional=false&express=false&suburban=false&subway=false&bus=true&tram=true&ferry=true',
  );

  final String displayName;
  final String description;
  final String apiFilters;

  const TransportCategory(this.displayName, this.description, this.apiFilters);
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/transport_category_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/transport_category.dart test/models/transport_category_test.dart
git commit -m "feat: add TransportCategory enum with Rail/Metro/Surface"
```

---

### Task 3: Create Networks Data File

**Files:**
- Create: `lib/data/networks.dart`
- Test: `test/data/networks_test.dart`

**Step 1: Write the failing test**

```dart
// test/data/networks_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/networks.dart';
import 'package:glance/models/transit_network.dart';

void main() {
  group('Networks', () {
    test('contains 10 German networks', () {
      expect(Networks.all.length, 10);
    });

    test('has VBB as default network', () {
      expect(Networks.defaultNetwork.id, 'vbb');
      expect(Networks.defaultNetwork.city, 'Berlin');
    });

    test('all networks have valid URLs', () {
      for (final network in Networks.all) {
        expect(network.baseUrl, startsWith('https://'));
        expect(network.baseUrl, contains('transport.rest'));
      }
    });

    test('findById returns correct network', () {
      final network = Networks.findById('hvv');
      expect(network?.city, 'Hamburg');
    });

    test('findById returns null for unknown id', () {
      expect(Networks.findById('unknown'), null);
    });

    test('search returns matching networks', () {
      final results = Networks.search('Berlin');
      expect(results.length, greaterThanOrEqualTo(1));
      expect(results.first.id, 'vbb');
    });

    test('search is case insensitive', () {
      final results = Networks.search('HAMBURG');
      expect(results.length, 1);
      expect(results.first.id, 'hvv');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/data/networks_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

```dart
// lib/data/networks.dart
import '../models/transit_network.dart';

class Networks {
  static const List<TransitNetwork> all = [
    TransitNetwork(
      id: 'vbb',
      name: 'Berlin-Brandenburg',
      city: 'Berlin',
      baseUrl: 'https://v6.vbb.transport.rest',
      latitude: 52.52,
      longitude: 13.405,
      searchTerms: ['Berlin', 'Potsdam', 'Brandenburg', 'Cottbus'],
    ),
    TransitNetwork(
      id: 'hvv',
      name: 'Hamburg',
      city: 'Hamburg',
      baseUrl: 'https://v6.hvv.transport.rest',
      latitude: 53.5511,
      longitude: 9.9937,
      searchTerms: ['Hamburg'],
    ),
    TransitNetwork(
      id: 'rmv',
      name: 'Rhine-Main',
      city: 'Frankfurt',
      baseUrl: 'https://v6.rmv.transport.rest',
      latitude: 50.1109,
      longitude: 8.6821,
      searchTerms: ['Frankfurt', 'Wiesbaden', 'Mainz', 'Darmstadt'],
    ),
    TransitNetwork(
      id: 'vvs',
      name: 'Stuttgart',
      city: 'Stuttgart',
      baseUrl: 'https://v6.vvs.transport.rest',
      latitude: 48.7758,
      longitude: 9.1829,
      searchTerms: ['Stuttgart', 'Esslingen', 'Ludwigsburg'],
    ),
    TransitNetwork(
      id: 'vrn',
      name: 'Rhine-Neckar',
      city: 'Mannheim',
      baseUrl: 'https://v6.vrn.transport.rest',
      latitude: 49.4875,
      longitude: 8.4660,
      searchTerms: ['Mannheim', 'Heidelberg', 'Ludwigshafen'],
    ),
    TransitNetwork(
      id: 'db',
      name: 'Deutsche Bahn',
      city: 'Nationwide',
      baseUrl: 'https://v6.db.transport.rest',
      latitude: 52.52,
      longitude: 13.405,
      searchTerms: ['DB', 'Deutsche Bahn', 'Germany', 'Nationwide'],
    ),
    TransitNetwork(
      id: 'insa',
      name: 'Saxony-Anhalt',
      city: 'Magdeburg',
      baseUrl: 'https://v6.insa.transport.rest',
      latitude: 52.1205,
      longitude: 11.6276,
      searchTerms: ['Magdeburg', 'Halle', 'Saxony-Anhalt'],
    ),
    TransitNetwork(
      id: 'nvv',
      name: 'North Hesse',
      city: 'Kassel',
      baseUrl: 'https://v6.nvv.transport.rest',
      latitude: 51.3127,
      longitude: 9.4797,
      searchTerms: ['Kassel', 'North Hesse', 'Nordhessen'],
    ),
    TransitNetwork(
      id: 'nasa',
      name: 'Saxony-Anhalt (NASA)',
      city: 'Halle',
      baseUrl: 'https://v6.nasa.transport.rest',
      latitude: 51.4969,
      longitude: 11.9688,
      searchTerms: ['Halle', 'Dessau'],
    ),
    TransitNetwork(
      id: 'bvg',
      name: 'Berlin (BVG)',
      city: 'Berlin',
      baseUrl: 'https://v6.bvg.transport.rest',
      latitude: 52.52,
      longitude: 13.405,
      searchTerms: ['Berlin', 'BVG'],
    ),
  ];

  static TransitNetwork get defaultNetwork => all.first;

  static TransitNetwork? findById(String id) {
    try {
      return all.firstWhere((n) => n.id == id);
    } catch (_) {
      return null;
    }
  }

  static List<TransitNetwork> search(String query) {
    if (query.isEmpty) return all;
    return all.where((n) => n.matchesSearch(query)).toList();
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/data/networks_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/data/networks.dart test/data/networks_test.dart
git commit -m "feat: add networks data with 10 German transit networks"
```

---

## Phase 2: Core Services

### Task 4: Add geolocator package

**Files:**
- Modify: `pubspec.yaml`

**Step 1: Add dependency**

Add to `pubspec.yaml` under dependencies:

```yaml
  geolocator: ^13.0.2
  permission_handler: ^11.3.1
```

**Step 2: Run pub get**

Run: `flutter pub get`
Expected: Dependencies resolved successfully

**Step 3: Commit**

```bash
git add pubspec.yaml pubspec.lock
git commit -m "chore: add geolocator and permission_handler packages"
```

---

### Task 5: Create LocationService

**Files:**
- Create: `lib/services/location_service.dart`
- Test: `test/services/location_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/services/location_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/services/location_service.dart';

void main() {
  group('LocationService', () {
    test('LocationResult has latitude and longitude', () {
      final result = LocationResult(latitude: 52.52, longitude: 13.405);
      expect(result.latitude, 52.52);
      expect(result.longitude, 13.405);
    });

    test('LocationError has message', () {
      final error = LocationError('Permission denied');
      expect(error.message, 'Permission denied');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/location_service_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

```dart
// lib/services/location_service.dart
import 'package:geolocator/geolocator.dart';

class LocationResult {
  final double latitude;
  final double longitude;

  const LocationResult({required this.latitude, required this.longitude});
}

class LocationError {
  final String message;

  const LocationError(this.message);
}

class LocationService {
  static Future<bool> isLocationEnabled() async {
    return await Geolocator.isLocationServiceEnabled();
  }

  static Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<bool> requestPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    return permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse;
  }

  static Future<LocationResult?> getCurrentPosition() async {
    try {
      final hasPerms = await hasPermission();
      if (!hasPerms) {
        final granted = await requestPermission();
        if (!granted) return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.medium,
          timeLimit: Duration(seconds: 10),
        ),
      );

      return LocationResult(
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (e) {
      return null;
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/location_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/location_service.dart test/services/location_service_test.dart
git commit -m "feat: add LocationService for GPS location"
```

---

### Task 6: Create TransitProviderService

**Files:**
- Create: `lib/services/transit_provider_service.dart`
- Test: `test/services/transit_provider_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/services/transit_provider_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/transit_network.dart';
import 'package:glance/services/transit_provider_service.dart';

void main() {
  group('TransitProviderService', () {
    test('creates service with network', () {
      final network = TransitNetwork(
        id: 'vbb',
        name: 'Berlin-Brandenburg',
        city: 'Berlin',
        baseUrl: 'https://v6.vbb.transport.rest',
        latitude: 52.52,
        longitude: 13.405,
        searchTerms: ['Berlin'],
      );

      final service = TransitProviderService(network: network);
      expect(service.network.id, 'vbb');
    });

    test('buildDeparturesUrl constructs correct URL', () {
      final network = TransitNetwork(
        id: 'vbb',
        name: 'Berlin-Brandenburg',
        city: 'Berlin',
        baseUrl: 'https://v6.vbb.transport.rest',
        latitude: 52.52,
        longitude: 13.405,
        searchTerms: ['Berlin'],
      );

      final service = TransitProviderService(network: network);
      final url = service.buildDeparturesUrl(
        stationId: '900100003',
        duration: 60,
        filters: '&regional=true',
      );

      expect(url, 'https://v6.vbb.transport.rest/stops/900100003/departures?duration=60&results=20&regional=true');
    });

    test('buildNearbyUrl constructs correct URL', () {
      final network = TransitNetwork(
        id: 'vbb',
        name: 'Berlin-Brandenburg',
        city: 'Berlin',
        baseUrl: 'https://v6.vbb.transport.rest',
        latitude: 52.52,
        longitude: 13.405,
        searchTerms: ['Berlin'],
      );

      final service = TransitProviderService(network: network);
      final url = service.buildNearbyUrl(latitude: 52.52, longitude: 13.405);

      expect(url, contains('/locations/nearby'));
      expect(url, contains('latitude=52.52'));
      expect(url, contains('longitude=13.405'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/transit_provider_service_test.dart`
Expected: FAIL

**Step 3: Write minimal implementation**

```dart
// lib/services/transit_provider_service.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../models/train_departure.dart';
import '../models/transit_network.dart';
import '../models/transport_category.dart';
import '../models/station.dart';

class TransitProviderService {
  final TransitNetwork network;

  TransitProviderService({required this.network});

  String buildDeparturesUrl({
    required String stationId,
    required int duration,
    required String filters,
  }) {
    return '${network.baseUrl}/stops/$stationId/departures?duration=$duration&results=20$filters';
  }

  String buildArrivalsUrl({
    required String stationId,
    required int duration,
    required String filters,
  }) {
    return '${network.baseUrl}/stops/$stationId/arrivals?duration=$duration&results=20$filters';
  }

  String buildNearbyUrl({
    required double latitude,
    required double longitude,
  }) {
    return '${network.baseUrl}/locations/nearby?latitude=$latitude&longitude=$longitude&results=5';
  }

  String buildSearchUrl(String query) {
    return '${network.baseUrl}/locations?query=$query&results=10&stops=true';
  }

  String _buildFilters(Set<TransportCategory> categories) {
    if (categories.isEmpty) {
      return '&regional=true&express=true&suburban=true&subway=true&bus=true&tram=true&ferry=true';
    }

    final hasRail = categories.contains(TransportCategory.rail);
    final hasMetro = categories.contains(TransportCategory.metro);
    final hasSurface = categories.contains(TransportCategory.surface);

    return '&regional=${hasRail}&express=${hasRail}&suburban=${hasRail}'
        '&subway=${hasMetro}'
        '&bus=${hasSurface}&tram=${hasSurface}&ferry=${hasSurface}';
  }

  Future<List<TrainDeparture>> getDepartures({
    required String stationId,
    int duration = 60,
    Set<TransportCategory> categories = const {},
    int skipMinutes = 0,
  }) async {
    try {
      final filters = _buildFilters(categories);
      final url = buildDeparturesUrl(
        stationId: stationId,
        duration: duration,
        filters: filters,
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final departures = data['departures'] as List?;

        if (departures == null || departures.isEmpty) {
          return _getFallbackData();
        }

        final trainDepartures = <TrainDeparture>[];
        final now = DateTime.now();
        final skipUntil = now.add(Duration(minutes: skipMinutes));

        for (var i = 0; i < departures.length && trainDepartures.length < 5; i++) {
          try {
            final dep = departures[i];
            final whenString = dep['when'] as String?;

            if (whenString == null) continue;

            final departureTime = DateTime.parse(whenString).toLocal();
            if (departureTime.isBefore(skipUntil)) continue;

            final departure = TrainDeparture.fromJson(dep);
            trainDepartures.add(departure);
          } catch (_) {}
        }

        return trainDepartures.isNotEmpty ? trainDepartures : _getFallbackData();
      }
      return _getFallbackData();
    } catch (_) {
      return _getFallbackData();
    }
  }

  Future<List<TrainDeparture>> getArrivals({
    required String stationId,
    int duration = 60,
    Set<TransportCategory> categories = const {},
    int skipMinutes = 0,
  }) async {
    try {
      final filters = _buildFilters(categories);
      final url = buildArrivalsUrl(
        stationId: stationId,
        duration: duration,
        filters: filters,
      );

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final arrivals = data['arrivals'] as List?;

        if (arrivals == null || arrivals.isEmpty) {
          return _getFallbackData();
        }

        final trainArrivals = <TrainDeparture>[];
        final now = DateTime.now();
        final skipUntil = now.add(Duration(minutes: skipMinutes));

        for (var i = 0; i < arrivals.length && trainArrivals.length < 5; i++) {
          try {
            final arr = arrivals[i];
            final whenString = arr['when'] as String?;

            if (whenString == null) continue;

            final arrivalTime = DateTime.parse(whenString).toLocal();
            if (arrivalTime.isBefore(skipUntil)) continue;

            final arrival = TrainDeparture.fromArrivalJson(arr);
            trainArrivals.add(arrival);
          } catch (_) {}
        }

        return trainArrivals.isNotEmpty ? trainArrivals : _getFallbackData();
      }
      return _getFallbackData();
    } catch (_) {
      return _getFallbackData();
    }
  }

  Future<Station?> findNearestStation(double latitude, double longitude) async {
    try {
      final url = buildNearbyUrl(latitude: latitude, longitude: longitude);

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        if (data.isEmpty) return null;

        final firstStop = data.first;
        return Station(
          id: firstStop['id']?.toString() ?? '',
          name: firstStop['name'] as String? ?? 'Unknown',
          networkId: network.id,
          latitude: (firstStop['location']?['latitude'] as num?)?.toDouble(),
          longitude: (firstStop['location']?['longitude'] as num?)?.toDouble(),
        );
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<List<Station>> searchStations(String query) async {
    try {
      final url = buildSearchUrl(query);

      final response = await http.get(
        Uri.parse(url),
        headers: {'Accept': 'application/json'},
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as List;
        return data
            .where((item) => item['type'] == 'stop' || item['type'] == 'station')
            .map((item) => Station(
                  id: item['id']?.toString() ?? '',
                  name: item['name'] as String? ?? 'Unknown',
                  networkId: network.id,
                  latitude: (item['location']?['latitude'] as num?)?.toDouble(),
                  longitude: (item['location']?['longitude'] as num?)?.toDouble(),
                ))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  List<TrainDeparture> _getFallbackData() {
    final now = DateTime.now();
    final hour12 = now.hour > 12 ? now.hour - 12 : (now.hour == 0 ? 12 : now.hour);
    final period = now.hour >= 12 ? 'PM' : 'AM';
    final currentTime = '${hour12}:${now.minute.toString().padLeft(2, '0')} $period';

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
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/transit_provider_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/transit_provider_service.dart test/services/transit_provider_service_test.dart
git commit -m "feat: add TransitProviderService for multi-network transit"
```

---

### Task 7: Update Station Model

**Files:**
- Modify: `lib/models/station.dart`
- Modify: `test/models/station_test.dart` (create if not exists)

**Step 1: Write the failing test**

```dart
// test/models/station_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/station.dart';

void main() {
  group('Station', () {
    test('creates station with all fields', () {
      final station = Station(
        id: '900100003',
        name: 'S+U Alexanderplatz',
        networkId: 'vbb',
        latitude: 52.5219,
        longitude: 13.4132,
      );

      expect(station.id, '900100003');
      expect(station.name, 'S+U Alexanderplatz');
      expect(station.networkId, 'vbb');
      expect(station.latitude, 52.5219);
      expect(station.longitude, 13.4132);
    });

    test('creates station with minimal fields', () {
      final station = Station(id: '123', name: 'Test Station');

      expect(station.id, '123');
      expect(station.name, 'Test Station');
      expect(station.networkId, null);
      expect(station.latitude, null);
      expect(station.longitude, null);
    });

    test('defaultStationId returns Alexanderplatz', () {
      expect(Station.defaultStationId, '900100003');
    });

    test('defaultStationName returns Alexanderplatz name', () {
      expect(Station.defaultStationName, 'S+U Alexanderplatz');
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/models/station_test.dart`
Expected: FAIL

**Step 3: Update implementation**

```dart
// lib/models/station.dart
class Station {
  final String id;
  final String name;
  final String? networkId;
  final double? latitude;
  final double? longitude;

  const Station({
    required this.id,
    required this.name,
    this.networkId,
    this.latitude,
    this.longitude,
  });

  static const String defaultStationId = '900100003';
  static const String defaultStationName = 'S+U Alexanderplatz';
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/models/station_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/models/station.dart test/models/station_test.dart
git commit -m "refactor: update Station model with network and location fields"
```

---

### Task 8: Update SettingsService

**Files:**
- Modify: `lib/services/settings_service.dart`
- Modify: `test/services/settings_service_test.dart` (create if not exists)

**Step 1: Write the failing test**

```dart
// test/services/settings_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/transport_category.dart';
import 'package:glance/services/settings_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  group('SettingsService', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('getSelectedNetworkId returns default vbb', () async {
      final networkId = await SettingsService.getSelectedNetworkId();
      expect(networkId, 'vbb');
    });

    test('saveSelectedNetworkId persists network', () async {
      await SettingsService.saveSelectedNetworkId('hvv');
      final networkId = await SettingsService.getSelectedNetworkId();
      expect(networkId, 'hvv');
    });

    test('getSelectedStationName returns saved name', () async {
      await SettingsService.saveSelectedStation('123', 'Test Station');
      final name = await SettingsService.getSelectedStationName();
      expect(name, 'Test Station');
    });

    test('clearStation removes station data', () async {
      await SettingsService.saveSelectedStation('123', 'Test');
      await SettingsService.clearStation();
      final id = await SettingsService.getDefaultStationId();
      expect(id, null);
    });

    test('getTransportCategories returns all by default', () async {
      final categories = await SettingsService.getTransportCategories();
      expect(categories, TransportCategory.values.toSet());
    });

    test('saveTransportCategories persists selection', () async {
      await SettingsService.saveTransportCategories({TransportCategory.rail});
      final categories = await SettingsService.getTransportCategories();
      expect(categories, {TransportCategory.rail});
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/settings_service_test.dart`
Expected: FAIL

**Step 3: Update implementation**

Add these methods to `lib/services/settings_service.dart`:

```dart
import 'package:shared_preferences/shared_preferences.dart';
import '../models/transport_category.dart';

class SettingsService {
  static const String _keyWeatherScale = 'weather_scale';
  static const String _keyDepartureScale = 'departure_scale';
  static const String _keyDefaultStationId = 'default_station_id';
  static const String _keyDefaultStationName = 'default_station_name';
  static const String _keySelectedNetworkId = 'selected_network_id';
  static const String _keyTransportCategories = 'transport_categories';
  static const String _keySkipMinutes = 'skip_minutes';
  static const String _keyDurationMinutes = 'duration_minutes';
  static const String _keyShowWeatherActions = 'show_weather_actions';

  // Existing methods remain unchanged...
  static Future<void> saveWeatherScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyWeatherScale, scale);
  }

  static Future<double> getWeatherScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyWeatherScale) ?? 1.0;
  }

  static Future<void> saveDepartureScale(double scale) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_keyDepartureScale, scale);
  }

  static Future<double> getDepartureScale() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getDouble(_keyDepartureScale) ?? 1.0;
  }

  static Future<void> saveDefaultStationId(String stationId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultStationId, stationId);
  }

  static Future<String?> getDefaultStationId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultStationId);
  }

  static Future<void> saveSkipMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keySkipMinutes, minutes);
  }

  static Future<int> getSkipMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keySkipMinutes) ?? 0;
  }

  static Future<void> saveDurationMinutes(int minutes) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyDurationMinutes, minutes);
  }

  static Future<int> getDurationMinutes() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyDurationMinutes) ?? 60;
  }

  static Future<void> saveShowWeatherActions(bool show) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyShowWeatherActions, show);
  }

  static Future<bool> getShowWeatherActions() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyShowWeatherActions) ?? false;
  }

  // New methods for multi-network support
  static Future<void> saveSelectedNetworkId(String networkId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keySelectedNetworkId, networkId);
  }

  static Future<String> getSelectedNetworkId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keySelectedNetworkId) ?? 'vbb';
  }

  static Future<void> saveSelectedStation(String stationId, String stationName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyDefaultStationId, stationId);
    await prefs.setString(_keyDefaultStationName, stationName);
  }

  static Future<String?> getSelectedStationName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyDefaultStationName);
  }

  static Future<void> clearStation() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyDefaultStationId);
    await prefs.remove(_keyDefaultStationName);
  }

  static Future<void> saveTransportCategories(Set<TransportCategory> categories) async {
    final prefs = await SharedPreferences.getInstance();
    final indices = categories.map((c) => c.index).toList();
    await prefs.setString(_keyTransportCategories, indices.join(','));
  }

  static Future<Set<TransportCategory>> getTransportCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final stored = prefs.getString(_keyTransportCategories);
    if (stored == null || stored.isEmpty) {
      return TransportCategory.values.toSet();
    }
    final indices = stored.split(',').map((s) => int.tryParse(s)).whereType<int>();
    return indices
        .where((i) => i >= 0 && i < TransportCategory.values.length)
        .map((i) => TransportCategory.values[i])
        .toSet();
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/settings_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/settings_service.dart test/services/settings_service_test.dart
git commit -m "feat: extend SettingsService with network and category settings"
```

---

### Task 9: Update WeatherService

**Files:**
- Modify: `lib/services/weather_service.dart`
- Test: `test/services/weather_service_test.dart`

**Step 1: Write the failing test**

```dart
// test/services/weather_service_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/services/weather_service.dart';

void main() {
  group('WeatherService', () {
    test('buildUrl constructs correct URL with coordinates', () {
      final url = WeatherService.buildUrl(52.52, 13.405);
      expect(url, contains('latitude=52.52'));
      expect(url, contains('longitude=13.405'));
      expect(url, contains('api.open-meteo.com'));
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/services/weather_service_test.dart`
Expected: FAIL

**Step 3: Update implementation**

```dart
// lib/services/weather_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/weather_data.dart';

class WeatherService {
  static const String _baseUrl = 'https://api.open-meteo.com/v1/forecast';

  // Default Berlin coordinates
  static const double _defaultLat = 52.52;
  static const double _defaultLng = 13.41;

  static String buildUrl(double lat, double lng) {
    return '$_baseUrl'
        '?latitude=$lat'
        '&longitude=$lng'
        '&current=temperature_2m,weather_code,precipitation_probability,wind_speed_10m,relative_humidity_2m'
        '&hourly=temperature_2m,weather_code,precipitation_probability'
        '&daily=temperature_2m_max,temperature_2m_min'
        '&timezone=auto'
        '&forecast_hours=12';
  }

  static Future<WeatherData> getWeather({
    double? latitude,
    double? longitude,
  }) async {
    try {
      final lat = latitude ?? _defaultLat;
      final lng = longitude ?? _defaultLng;
      final url = buildUrl(lat, lng);

      final response = await http.get(Uri.parse(url));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return WeatherData.fromJson(data);
      } else {
        throw Exception('Failed to load weather data');
      }
    } catch (e) {
      throw Exception('Error fetching weather: $e');
    }
  }
}
```

**Step 4: Run test to verify it passes**

Run: `flutter test test/services/weather_service_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/services/weather_service.dart test/services/weather_service_test.dart
git commit -m "refactor: update WeatherService to accept dynamic coordinates"
```

---

## Phase 3: UI Components

### Task 10: Create NetworkSearchDialog

**Files:**
- Create: `lib/widgets/network_search_dialog.dart`

**Step 1: Create the widget**

```dart
// lib/widgets/network_search_dialog.dart
import 'package:flutter/material.dart';
import '../data/networks.dart';
import '../models/transit_network.dart';

class NetworkSearchDialog extends StatefulWidget {
  final TransitNetwork currentNetwork;
  final Function(TransitNetwork) onNetworkSelected;

  const NetworkSearchDialog({
    super.key,
    required this.currentNetwork,
    required this.onNetworkSelected,
  });

  @override
  State<NetworkSearchDialog> createState() => _NetworkSearchDialogState();
}

class _NetworkSearchDialogState extends State<NetworkSearchDialog> {
  final _searchController = TextEditingController();
  List<TransitNetwork> _filteredNetworks = [];

  @override
  void initState() {
    super.initState();
    _filteredNetworks = Networks.all;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String query) {
    setState(() {
      _filteredNetworks = Networks.search(query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252931),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Select Transit Network',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search city...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _filteredNetworks.length,
                  itemBuilder: (context, index) {
                    final network = _filteredNetworks[index];
                    final isSelected = network.id == widget.currentNetwork.id;

                    return ListTile(
                      leading: Icon(
                        Icons.train,
                        color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
                      ),
                      title: Text(
                        network.city,
                        style: TextStyle(
                          color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                      subtitle: Text(
                        network.name,
                        style: const TextStyle(color: Colors.white54, fontSize: 12),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                          : null,
                      onTap: () {
                        widget.onNetworkSelected(network);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/network_search_dialog.dart
git commit -m "feat: add NetworkSearchDialog for city search"
```

---

### Task 11: Create StationSearchDialog

**Files:**
- Create: `lib/widgets/station_search_dialog.dart`

**Step 1: Create the widget**

```dart
// lib/widgets/station_search_dialog.dart
import 'package:flutter/material.dart';
import '../models/station.dart';
import '../models/transit_network.dart';
import '../services/transit_provider_service.dart';
import '../services/location_service.dart';

class StationSearchDialog extends StatefulWidget {
  final TransitNetwork network;
  final Station? currentStation;
  final Function(Station) onStationSelected;

  const StationSearchDialog({
    super.key,
    required this.network,
    this.currentStation,
    required this.onStationSelected,
  });

  @override
  State<StationSearchDialog> createState() => _StationSearchDialogState();
}

class _StationSearchDialogState extends State<StationSearchDialog> {
  final _searchController = TextEditingController();
  List<Station> _searchResults = [];
  bool _isSearching = false;
  bool _isDetecting = false;
  String? _errorMessage;
  Station? _detectedStation;

  late final TransitProviderService _transitService;

  @override
  void initState() {
    super.initState();
    _transitService = TransitProviderService(network: widget.network);
    _detectNearestStation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _detectNearestStation() async {
    setState(() {
      _isDetecting = true;
      _errorMessage = null;
    });

    final location = await LocationService.getCurrentPosition();
    if (location == null) {
      setState(() {
        _isDetecting = false;
        _errorMessage = 'Location unavailable. Search for a station below.';
      });
      return;
    }

    final station = await _transitService.findNearestStation(
      location.latitude,
      location.longitude,
    );

    setState(() {
      _isDetecting = false;
      _detectedStation = station;
      if (station == null) {
        _errorMessage = 'No stations found nearby. Search below.';
      }
    });
  }

  Future<void> _onSearchChanged(String query) async {
    if (query.length < 2) {
      setState(() => _searchResults = []);
      return;
    }

    setState(() => _isSearching = true);

    final results = await _transitService.searchStations(query);

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF252931),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 500),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Station (${widget.network.city})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Location detection section
              if (_isDetecting)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      SizedBox(width: 12),
                      Text(
                        'Finding nearest station...',
                        style: TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                )
              else if (_detectedStation != null)
                Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFF3B82F6).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF3B82F6).withValues(alpha: 0.5)),
                  ),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.my_location, color: Color(0xFF3B82F6)),
                    title: Text(
                      _detectedStation!.name,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
                    ),
                    subtitle: const Text(
                      'Nearest station',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    trailing: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3B82F6),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () {
                        widget.onStationSelected(_detectedStation!);
                        Navigator.pop(context);
                      },
                      child: const Text('Use'),
                    ),
                  ),
                )
              else if (_errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.white54),
                  ),
                ),

              // Search section
              TextField(
                controller: _searchController,
                onChanged: _onSearchChanged,
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Search station...',
                  hintStyle: const TextStyle(color: Colors.white54),
                  prefixIcon: const Icon(Icons.search, color: Colors.white54),
                  suffixIcon: _isSearching
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        )
                      : null,
                  filled: true,
                  fillColor: Colors.white.withValues(alpha: 0.1),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Results
              Flexible(
                child: _searchResults.isEmpty
                    ? const Center(
                        child: Text(
                          'Type to search for stations',
                          style: TextStyle(color: Colors.white54),
                        ),
                      )
                    : ListView.builder(
                        shrinkWrap: true,
                        itemCount: _searchResults.length,
                        itemBuilder: (context, index) {
                          final station = _searchResults[index];
                          final isSelected = station.id == widget.currentStation?.id;

                          return ListTile(
                            leading: Icon(
                              Icons.train,
                              color: isSelected ? const Color(0xFF3B82F6) : Colors.white54,
                            ),
                            title: Text(
                              station.name,
                              style: TextStyle(
                                color: isSelected ? const Color(0xFF3B82F6) : Colors.white,
                              ),
                            ),
                            trailing: isSelected
                                ? const Icon(Icons.check, color: Color(0xFF3B82F6))
                                : null,
                            onTap: () {
                              widget.onStationSelected(station);
                              Navigator.pop(context);
                            },
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
```

**Step 2: Commit**

```bash
git add lib/widgets/station_search_dialog.dart
git commit -m "feat: add StationSearchDialog with GPS detection"
```

---

### Task 12: Update SettingsDialog

**Files:**
- Modify: `lib/widgets/settings_dialog.dart`

**Step 1: Update the widget**

Replace the entire file with the updated version that includes network selection:

```dart
// lib/widgets/settings_dialog.dart
import 'package:flutter/material.dart';
import '../data/networks.dart';
import '../models/station.dart';
import '../models/transit_network.dart';
import '../models/transport_category.dart';
import '../models/widget_layout.dart';
import '../services/settings_service.dart';
import 'network_search_dialog.dart';
import 'station_search_dialog.dart';

class SettingsDialog extends StatefulWidget {
  final double initialWeatherScale;
  final double initialDepartureScale;
  final String initialStationId;
  final String? initialStationName;
  final String initialNetworkId;
  final Set<TransportCategory> initialCategories;
  final int initialSkipMinutes;
  final int initialDurationMinutes;
  final bool initialShowWeatherActions;
  final Function(
    double weatherScale,
    double departureScale,
    String stationId,
    String? stationName,
    String networkId,
    Set<TransportCategory> categories,
    int skipMinutes,
    int durationMinutes,
    bool showWeatherActions,
  ) onSave;
  final Function(LayoutPreset)? onPresetSelected;

  const SettingsDialog({
    super.key,
    required this.initialWeatherScale,
    required this.initialDepartureScale,
    required this.initialStationId,
    this.initialStationName,
    required this.initialNetworkId,
    required this.initialCategories,
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
  late String? _selectedStationName;
  late TransitNetwork _selectedNetwork;
  late Set<TransportCategory> _selectedCategories;
  late int _skipMinutes;
  late int _durationMinutes;
  late bool _showWeatherActions;

  @override
  void initState() {
    super.initState();
    _weatherScale = widget.initialWeatherScale;
    _departureScale = widget.initialDepartureScale;
    _selectedStationId = widget.initialStationId;
    _selectedStationName = widget.initialStationName;
    _selectedNetwork = Networks.findById(widget.initialNetworkId) ?? Networks.defaultNetwork;
    _selectedCategories = widget.initialCategories;
    _skipMinutes = widget.initialSkipMinutes;
    _durationMinutes = widget.initialDurationMinutes;
    _showWeatherActions = widget.initialShowWeatherActions;
  }

  void _showNetworkSearch() {
    showDialog(
      context: context,
      builder: (context) => NetworkSearchDialog(
        currentNetwork: _selectedNetwork,
        onNetworkSelected: (network) {
          setState(() {
            _selectedNetwork = network;
            // Clear station when network changes
            _selectedStationId = Station.defaultStationId;
            _selectedStationName = null;
          });
        },
      ),
    );
  }

  void _showStationSearch() {
    showDialog(
      context: context,
      builder: (context) => StationSearchDialog(
        network: _selectedNetwork,
        currentStation: Station(id: _selectedStationId, name: _selectedStationName ?? ''),
        onStationSelected: (station) {
          setState(() {
            _selectedStationId = station.id;
            _selectedStationName = station.name;
          });
        },
      ),
    );
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

  Widget _buildSkeletonWidget(String widgetId, BoxConstraints parentConstraints) {
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
          constraints: const BoxConstraints(maxWidth: 400, maxHeight: 700),
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

                // Transit Network Section
                const Text(
                  'Transit Network',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showNetworkSearch,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.train, color: Colors.white54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _selectedNetwork.city,
                                style: const TextStyle(color: Colors.white),
                              ),
                              Text(
                                _selectedNetwork.name,
                                style: const TextStyle(color: Colors.white54, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Station Section
                const Text(
                  'Station',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _showStationSearch,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.location_on, color: Colors.white54),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _selectedStationName ?? 'Select station...',
                            style: TextStyle(
                              color: _selectedStationName != null
                                  ? Colors.white
                                  : Colors.white54,
                            ),
                          ),
                        ),
                        const Icon(Icons.chevron_right, color: Colors.white54),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 16),

                // Transport Categories
                const Text(
                  'Transport Types',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 8),
                ...TransportCategory.values.map((category) {
                  return CheckboxListTile(
                    title: Text(
                      category.displayName,
                      style: const TextStyle(color: Colors.white),
                    ),
                    subtitle: Text(
                      category.description,
                      style: const TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    value: _selectedCategories.contains(category),
                    onChanged: (value) {
                      setState(() {
                        if (value == true) {
                          _selectedCategories.add(category);
                        } else {
                          _selectedCategories.remove(category);
                        }
                      });
                    },
                    activeColor: const Color(0xFF3B82F6),
                    contentPadding: EdgeInsets.zero,
                  );
                }),

                const SizedBox(height: 16),
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
                        onChanged: (value) => setState(() => _weatherScale = value),
                      ),
                    ),
                    const Text('Large', style: TextStyle(color: Colors.white54)),
                  ],
                ),

                const SizedBox(height: 16),
                const Text(
                  'Departure Table Font Size',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                Row(
                  children: [
                    const Text('Normal', style: TextStyle(color: Colors.white54)),
                    Expanded(
                      child: Slider(
                        value: _departureScale,
                        min: 0.8,
                        max: 2.0,
                        divisions: 12,
                        label: _departureScale.toStringAsFixed(1),
                        activeColor: const Color(0xFF3B82F6),
                        onChanged: (value) => setState(() => _departureScale = value),
                      ),
                    ),
                    const Text('Large', style: TextStyle(color: Colors.white54)),
                  ],
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
                        onChanged: (value) => setState(() => _skipMinutes = value.round()),
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
                        onChanged: (value) => setState(() => _durationMinutes = value.round()),
                      ),
                    ),
                    const Text('180', style: TextStyle(color: Colors.white54)),
                  ],
                ),

                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text(
                    'Show Weather Tips',
                    style: TextStyle(color: Colors.white70),
                  ),
                  subtitle: const Text(
                    'Replace logo with AI weather recommendations',
                    style: TextStyle(color: Colors.white54),
                  ),
                  value: _showWeatherActions,
                  onChanged: (value) => setState(() => _showWeatherActions = value),
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
                        await SettingsService.saveDepartureScale(_departureScale);
                        await SettingsService.saveSelectedStation(
                          _selectedStationId,
                          _selectedStationName ?? '',
                        );
                        await SettingsService.saveSelectedNetworkId(_selectedNetwork.id);
                        await SettingsService.saveTransportCategories(_selectedCategories);
                        await SettingsService.saveSkipMinutes(_skipMinutes);
                        await SettingsService.saveDurationMinutes(_durationMinutes);
                        await SettingsService.saveShowWeatherActions(_showWeatherActions);

                        widget.onSave(
                          _weatherScale,
                          _departureScale,
                          _selectedStationId,
                          _selectedStationName,
                          _selectedNetwork.id,
                          _selectedCategories,
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
```

**Step 2: Commit**

```bash
git add lib/widgets/settings_dialog.dart
git commit -m "refactor: update SettingsDialog with network and category selection"
```

---

## Phase 4: Integration

### Task 13: Update TrainDeparturesWidget

**Files:**
- Modify: `lib/widgets/train_departures_widget.dart`

**Step 1: Update to use TransitProviderService**

Key changes needed:
1. Replace BvgService with TransitProviderService
2. Replace TransportType with TransportCategory
3. Use API-provided line colors with fallback
4. Remove hardcoded Berlin station list

The widget should accept:
- `networkId` parameter
- `categories` instead of `transportType`

**Step 2: Commit**

```bash
git add lib/widgets/train_departures_widget.dart
git commit -m "refactor: update TrainDeparturesWidget for multi-network support"
```

---

### Task 14: Update Dashboard Integration

**Files:**
- Modify: `lib/screens/dashboard_screen.dart` (or main dashboard file)

**Step 1: Update dashboard to:**
1. Load selected network from settings
2. Pass network to TransitProviderService
3. Update weather with network coordinates
4. Handle network changes

**Step 2: Commit**

```bash
git add lib/screens/dashboard_screen.dart
git commit -m "feat: integrate multi-network transit into dashboard"
```

---

### Task 15: Cleanup Old Files

**Files:**
- Delete: `lib/services/bvg_service.dart`
- Delete: `lib/services/bvg_search_service.dart`
- Delete: `lib/models/transport_type.dart`

**Step 1: Remove old files**

```bash
rm lib/services/bvg_service.dart
rm lib/services/bvg_search_service.dart
rm lib/models/transport_type.dart
```

**Step 2: Update any remaining imports**

Search for and update any files still importing the old files.

**Step 3: Run tests to verify nothing is broken**

Run: `flutter test`
Expected: All tests pass

**Step 4: Commit**

```bash
git add -A
git commit -m "chore: remove deprecated BVG-specific files"
```

---

### Task 16: Final Integration Test

**Step 1: Run the app**

```bash
flutter run
```

**Step 2: Manual testing checklist:**
- [ ] App launches with Berlin (VBB) as default
- [ ] Settings shows network selection
- [ ] Can search and select Hamburg
- [ ] Station detection works (if location available)
- [ ] Can manually search stations
- [ ] Transport category filters work
- [ ] Departures load for selected network
- [ ] Weather updates when network changes
- [ ] Settings persist after restart

**Step 3: Run all tests**

```bash
flutter test
```

**Step 4: Final commit**

```bash
git add -A
git commit -m "feat: complete multi-network transit support for Germany"
```

---

## Summary

This plan implements multi-network German transit support with:
- 10 transport.rest networks
- GPS-based station detection
- City search with autocomplete
- Simplified transport categories (Rail/Metro/Surface)
- Dynamic weather based on selected city
- Backward compatible settings migration
