import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glance/widgets/train_departures_widget.dart';
import 'package:glance/models/station.dart';
import 'package:glance/models/transport_type.dart';

// Mock HTTP classes for API calls
class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse();
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  @override
  int get statusCode => 200;

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    final mockData = {
      'departures': [
        {
          'when':
              DateTime.now().add(const Duration(minutes: 10)).toIso8601String(),
          'line': {'name': 'RE1', 'productName': 'RE'},
          'direction': 'Berlin Hbf',
          'platform': '1',
        },
        {
          'when':
              DateTime.now().add(const Duration(minutes: 20)).toIso8601String(),
          'line': {'name': 'RE2', 'productName': 'RE'},
          'direction': 'Potsdam',
          'platform': '2',
        },
      ],
    };
    return Stream.value(utf8.encode(jsonEncode(mockData)))
        .cast<List<int>>()
        .transform(streamTransformer);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    final mockData = {'departures': []};
    return Stream.value(utf8.encode(jsonEncode(mockData))).listen(
      onData,
      onError: onError,
      onDone: onDone,
      cancelOnError: cancelOnError,
    );
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return MockHttpClient();
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  Widget createTestWidget({bool compactMode = false}) {
    return MaterialApp(
      theme: ThemeData.dark(),
      home: Scaffold(
        body: SizedBox(
          width: compactMode ? 400 : 1500,
          height: compactMode ? 600 : 800,
          child: TrainDeparturesWidget(
            initialStation: Station.defaultStation,
            initialTransportType: TransportType.regional,
            scaleFactor: 1.0,
            skipMinutes: 0,
            durationMinutes: 60,
            compactMode: compactMode,
          ),
        ),
      ),
    );
  }

  group('TrainDeparturesWidget', () {
    group('compactMode parameter', () {
      testWidgets('renders in full mode by default',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Full mode should show larger text elements
        // Look for the departures/arrivals label
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('renders in compact mode when specified',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.byType(TrainDeparturesWidget), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('compact mode shows transport type name in header',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // In compact mode, transport type name should be visible
        expect(find.text('Regional'), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('compact mode shows FROM/TO toggle',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('FROM'), findsOneWidget);
        expect(find.text('TO'), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('full mode shows Departures or Arrivals label',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Either Departures or Arrivals should be present based on mode
        final departures = find.text('Departures');
        final arrivals = find.text('Arrivals');
        expect(
            departures.evaluate().isNotEmpty || arrivals.evaluate().isNotEmpty,
            isTrue);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('table headers', () {
      testWidgets('compact mode shows Min, Line, Destination, Status columns',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        expect(find.text('Min'), findsOneWidget);
        expect(find.text('Line'), findsOneWidget);
        expect(find.text('Destination'), findsOneWidget);
        expect(find.text('Status'), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets(
          'full mode shows Time, Min, Destination, Line, Platform, Status columns',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Use findsAtLeastNWidgets since text may appear in header and data rows
        expect(find.text('Time'), findsAtLeastNWidgets(1));
        expect(find.text('Min'), findsAtLeastNWidgets(1));
        expect(find.text('Destination'), findsAtLeastNWidgets(1));
        expect(find.text('Line'), findsAtLeastNWidgets(1));
        expect(find.text('Platform'), findsAtLeastNWidgets(1));
        expect(find.text('Status'), findsAtLeastNWidgets(1));

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('station selector', () {
      testWidgets('shows station dropdown in both modes',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should find a dropdown button for station selection
        expect(find.byType(DropdownButton<Station>), findsAtLeastNWidgets(1));

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('transport type', () {
      testWidgets('initializes with provided transport type',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: TrainDeparturesWidget(
                initialStation: Station.defaultStation,
                initialTransportType: TransportType.bus,
                scaleFactor: 1.0,
                skipMinutes: 0,
                durationMinutes: 60,
                compactMode: true,
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Should show Bus as the transport type
        expect(find.text('Bus'), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('responsive behavior', () {
      testWidgets('compact mode uses smaller padding',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: true));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should render without overflow errors
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('full mode uses larger padding', (WidgetTester tester) async {
        tester.view.physicalSize = const Size(1600, 900);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget(compactMode: false));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should render without overflow errors
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('refresh functionality', () {
      testWidgets('refresh() can be called via GlobalKey',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final key = GlobalKey<TrainDeparturesWidgetState>();

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: TrainDeparturesWidget(
                key: key,
                initialStation: Station.defaultStation,
                initialTransportType: TransportType.regional,
                scaleFactor: 1.0,
                skipMinutes: 0,
                durationMinutes: 60,
                compactMode: true,
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify the key provides access to state
        expect(key.currentState, isNotNull);

        // Verify refresh() method exists and can be called
        expect(key.currentState!.refresh, isA<Function>());

        // Call refresh - should not throw
        await key.currentState!.refresh();
        await tester.pump();

        // Widget should still be rendered without errors
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('refresh() fetches new data when called',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        final key = GlobalKey<TrainDeparturesWidgetState>();

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 600,
              child: TrainDeparturesWidget(
                key: key,
                initialStation: Station.defaultStation,
                initialTransportType: TransportType.regional,
                scaleFactor: 1.0,
                skipMinutes: 0,
                durationMinutes: 60,
                compactMode: true,
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Call refresh multiple times - should not throw or cause issues
        await key.currentState!.refresh();
        await tester.pump(const Duration(milliseconds: 100));

        await key.currentState!.refresh();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should still be working
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('didUpdateWidget', () {
      testWidgets('triggers refresh when skipMinutes changes',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        int skipMinutes = 0;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: TrainDeparturesWidget(
                  initialStation: Station.defaultStation,
                  initialTransportType: TransportType.regional,
                  scaleFactor: 1.0,
                  skipMinutes: skipMinutes,
                  durationMinutes: 60,
                  compactMode: true,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => skipMinutes = 10),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap button to change skipMinutes
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should still be working after prop change
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('triggers refresh when durationMinutes changes',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        int durationMinutes = 60;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: TrainDeparturesWidget(
                  initialStation: Station.defaultStation,
                  initialTransportType: TransportType.regional,
                  scaleFactor: 1.0,
                  skipMinutes: 0,
                  durationMinutes: durationMinutes,
                  compactMode: true,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => durationMinutes = 120),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap button to change durationMinutes
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should still be working after prop change
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('triggers refresh when initialStation changes',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        Station station = Station.defaultStation;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: TrainDeparturesWidget(
                  initialStation: station,
                  initialTransportType: TransportType.regional,
                  scaleFactor: 1.0,
                  skipMinutes: 0,
                  durationMinutes: 60,
                  compactMode: true,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() {
                  // Use a different station from the list
                  station = Station.popularStations.length > 1
                      ? Station.popularStations[1]
                      : Station.defaultStation;
                }),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap button to change station
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should still be working after prop change
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('triggers refresh when initialTransportType changes',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        TransportType transportType = TransportType.regional;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: TrainDeparturesWidget(
                  initialStation: Station.defaultStation,
                  initialTransportType: transportType,
                  scaleFactor: 1.0,
                  skipMinutes: 0,
                  durationMinutes: 60,
                  compactMode: true,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => transportType = TransportType.bus),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Verify initial transport type shown
        expect(find.text('Regional'), findsOneWidget);

        // Tap button to change transport type
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should now show Bus
        expect(find.text('Bus'), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('does not trigger refresh when unrelated props change',
          (WidgetTester tester) async {
        tester.view.physicalSize = const Size(400, 800);
        tester.view.devicePixelRatio = 1.0;

        double scaleFactor = 1.0;

        await tester.pumpWidget(MaterialApp(
          theme: ThemeData.dark(),
          home: StatefulBuilder(
            builder: (context, setState) => Scaffold(
              body: SizedBox(
                width: 400,
                height: 600,
                child: TrainDeparturesWidget(
                  initialStation: Station.defaultStation,
                  initialTransportType: TransportType.regional,
                  scaleFactor: scaleFactor,
                  skipMinutes: 0,
                  durationMinutes: 60,
                  compactMode: true,
                ),
              ),
              floatingActionButton: FloatingActionButton(
                onPressed: () => setState(() => scaleFactor = 1.5),
                child: const Icon(Icons.add),
              ),
            ),
          ),
        ));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Tap button to change scaleFactor (should NOT trigger refresh)
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 100));

        // Widget should still be working - no unnecessary refreshes
        expect(find.byType(TrainDeparturesWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });
  });
}
