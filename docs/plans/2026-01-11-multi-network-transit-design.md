# Multi-Network Transit Support for Germany

## Overview

Expand the Glance Dashboard from Berlin-only (BVG) to support all German transit networks available via the transport.rest API ecosystem.

## Goals

- Support 10 German transit networks via transport.rest APIs
- City search with autocomplete for network selection
- Auto-detect nearest station using GPS
- Weather updates based on selected city
- Simplified transport categories (Rail, Metro, Surface)
- Default to Berlin (VBB)

## Supported Networks

| Network | City/Region | API Endpoint |
|---------|-------------|--------------|
| VBB | Berlin-Brandenburg | v6.vbb.transport.rest |
| HVV | Hamburg | v6.hvv.transport.rest |
| RMV | Frankfurt/Rhine-Main | v6.rmv.transport.rest |
| VVS | Stuttgart | v6.vvs.transport.rest |
| VRN | Mannheim/Heidelberg | v6.vrn.transport.rest |
| DB | Nationwide rail | v6.db.transport.rest |
| INSA | Saxony-Anhalt | v6.insa.transport.rest |
| NVV | North Hesse | v6.nvv.transport.rest |
| NASA | Saxony-Anhalt (alt) | v6.nasa.transport.rest |
| BVG | Berlin (legacy) | v6.bvg.transport.rest |

## Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    Settings Service                      │
│  - selectedNetwork (default: VBB Berlin)                │
│  - selectedStation (auto-detected or searched)          │
│  - transportFilters (Rail, Metro, Surface)              │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│              Transit Provider Factory                    │
│  Creates correct provider based on selectedNetwork       │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│           Abstract TransitProvider Interface             │
│  - getDepartures(stationId, filters)                    │
│  - getArrivals(stationId, filters)                      │
│  - searchStations(query)                                │
│  - findNearestStation(lat, lng)                         │
└────────────────────────┬────────────────────────────────┘
                         │
┌────────────────────────▼────────────────────────────────┐
│         TransportRestProvider (single impl)              │
│  - Configured with network-specific baseUrl              │
│  - Same parsing logic for all transport.rest APIs        │
└─────────────────────────────────────────────────────────┘
```

Since all transport.rest APIs use the same response format, only ONE provider implementation is needed, configured with different base URLs per network.

## Data Models

### New Models

```dart
// Network configuration
class TransitNetwork {
  final String id;           // e.g., "vbb", "hvv"
  final String name;         // e.g., "Berlin-Brandenburg"
  final String city;         // e.g., "Berlin" (for search)
  final String baseUrl;      // e.g., "https://v6.vbb.transport.rest"
  final double latitude;     // City center for weather
  final double longitude;
  final List<String> searchTerms; // ["Berlin", "Potsdam", "Brandenburg"]
}

// Simplified transport categories
enum TransportCategory {
  rail,    // Regional, S-Bahn, IC, ICE
  metro,   // U-Bahn, Stadtbahn
  surface, // Bus, Tram, Ferry
}
```

### Modified Models

```dart
// TrainDeparture - add lineColor from API
class TrainDeparture {
  // ... existing fields ...
  final Color? apiLineColor;  // from API response if available
}

// Station - remove hardcoded popularStations
class Station {
  final String id;
  final String name;
  final String? networkId;    // which network this belongs to
  final double? latitude;     // for distance calculation
  final double? longitude;
}
```

## Services

### New Services

```dart
// TransitProviderService - replaces BvgService and BvgSearchService
class TransitProviderService {
  final TransitNetwork network;

  Future<List<TrainDeparture>> getDepartures(String stationId, {
    Set<TransportCategory> categories,
    int durationMinutes,
  });

  Future<List<TrainDeparture>> getArrivals(String stationId, {...});
  Future<List<Station>> searchStations(String query);
  Future<Station?> findNearestStation(double lat, double lng);
}

// LocationService - handles GPS and permissions
class LocationService {
  Future<Position?> getCurrentPosition();
  Future<bool> requestPermission();
  bool get hasPermission;
}

// NetworkSelectionService - manages network switching
class NetworkSelectionService {
  TransitNetwork get currentNetwork;
  Future<void> setNetwork(TransitNetwork network);
  List<TransitNetwork> searchNetworks(String query);
}
```

### Modified Services

```dart
// WeatherService - now location-aware
class WeatherService {
  Future<WeatherData> getWeather(double lat, double lng);
  Future<WeatherData> getWeatherForNetwork(TransitNetwork network);
}

// SettingsService - new keys
class SettingsService {
  String? get selectedNetworkId;      // default: 'vbb'
  String? get selectedStationId;
  String? get selectedStationName;
  Set<TransportCategory> get transportCategories;
}
```

## Settings UI

```
┌─────────────────────────────────────────┐
│ Settings Screen                         │
├─────────────────────────────────────────┤
│                                         │
│ Transit Network                         │
│ ┌─────────────────────────────────────┐ │
│ │ Search city...                      │ │
│ └─────────────────────────────────────┘ │
│                                         │
│ Current: Berlin-Brandenburg (VBB)       │
│                                         │
│ Station                                 │
│ ┌─────────────────────────────────────┐ │
│ │ Auto-detect from location           │ │
│ │    S+U Alexanderplatz (detected)    │ │
│ └─────────────────────────────────────┘ │
│ [ Search manually instead ]             │
│                                         │
│ Transport Types                         │
│ ┌─────────────────────────────────────┐ │
│ │ ☑ Rail (Regional, S-Bahn)          │ │
│ │ ☑ Metro (U-Bahn, Stadtbahn)        │ │
│ │ ☑ Surface (Bus, Tram, Ferry)       │ │
│ └─────────────────────────────────────┘ │
│                                         │
└─────────────────────────────────────────┘
```

### Station Detection States

1. **Detecting** - "Finding nearest station..."
2. **Detected** - "S+U Alexanderplatz (500m away)"
3. **Permission denied** - "Location unavailable" + search fallback
4. **No station nearby** - "No stations found nearby" + search fallback

## Line Colors

Use API-provided colors when available, fall back to generic:

```dart
Color _getLineColor(String lineName, Color? apiColor) {
  if (apiColor != null) return apiColor;

  // Generic fallback by transport category
  if (lineName.startsWith('S')) return Colors.green;
  if (lineName.startsWith('U')) return Colors.blue;
  if (RegExp(r'^(RE|RB|IC|EC)').hasMatch(lineName)) return Colors.red;
  return Colors.amber;  // Bus/Tram/other
}
```

## Error Handling

| Scenario | Handling |
|----------|----------|
| Network API unreachable | Show cached data if available, else "Service unavailable" |
| Invalid station ID after network switch | Clear saved station, trigger re-detection |
| Location permission denied | Show search UI immediately |
| No stations found near location | "No stations within 2km. Search manually?" |
| API returns no departures | "No departures in next [X] minutes" |

### Network Switching Logic

```dart
Future<void> onNetworkChanged(TransitNetwork newNetwork) async {
  // 1. Save new network preference
  await settings.setNetworkId(newNetwork.id);

  // 2. Clear old station (different network = invalid station)
  await settings.clearStation();

  // 3. Update weather location
  await weatherService.updateLocation(newNetwork.latitude, newNetwork.longitude);

  // 4. Attempt auto-detection for new network
  if (locationService.hasPermission) {
    final position = await locationService.getCurrentPosition();
    if (position != null) {
      final station = await transitProvider.findNearestStation(
        position.latitude,
        position.longitude,
      );
      if (station != null) {
        await settings.setStation(station);
      }
    }
  }

  // 5. Refresh dashboard
  dashboardKey.currentState?.refresh();
}
```

### First Launch Flow

1. Default to VBB (Berlin)
2. Request location permission
3. If granted: auto-detect station
4. If denied: show network selection + station search

## File Changes

### New Files

| File | Purpose |
|------|---------|
| `lib/models/transit_network.dart` | Network configuration model |
| `lib/models/transport_category.dart` | Simplified Rail/Metro/Surface enum |
| `lib/services/transit_provider_service.dart` | Replaces BvgService + BvgSearchService |
| `lib/services/location_service.dart` | GPS and permission handling |
| `lib/services/network_selection_service.dart` | Network switching logic |
| `lib/data/networks.dart` | Static list of 10 German networks |
| `lib/widgets/network_search_dialog.dart` | Autocomplete network picker |
| `lib/widgets/station_detector_widget.dart` | Location detection UI component |

### Modified Files

| File | Changes |
|------|---------|
| `lib/models/train_departure.dart` | Add `apiLineColor` field |
| `lib/models/station.dart` | Add `networkId`, `latitude`, `longitude`; remove `popularStations` |
| `lib/services/settings_service.dart` | Add network/station persistence, new transport categories |
| `lib/services/weather_service.dart` | Accept dynamic coordinates |
| `lib/widgets/train_departures_widget.dart` | Use new provider, simplified color logic |
| `lib/screens/settings_screen.dart` | New network/station selection UI |
| `lib/screens/dashboard_screen.dart` | Initialize with selected network |
| `pubspec.yaml` | Add `geolocator` package for GPS |

### Deleted Files

| File | Reason |
|------|--------|
| `lib/services/bvg_service.dart` | Replaced by transit_provider_service |
| `lib/services/bvg_search_service.dart` | Replaced by transit_provider_service |
| `lib/models/transport_type.dart` | Replaced by transport_category |

## Future Expansion

This design allows easy addition of:
- HAFAS-based networks (for Munich MVV, etc.) via new provider implementation
- Additional transport.rest endpoints as they become available
- User-contributed network configurations
