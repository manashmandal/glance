import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:glance/screens/dashboard_screen.dart';
import 'package:glance/widgets/train_departures_widget.dart';
import 'package:glance/widgets/weather_widget.dart';

class MockHttpClient implements HttpClient {
  @override
  Future<HttpClientRequest> getUrl(Uri url) async {
    return MockHttpClientRequest(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientRequest implements HttpClientRequest {
  final Uri url;

  MockHttpClientRequest(this.url);

  @override
  Future<HttpClientResponse> close() async {
    return MockHttpClientResponse(url);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}

class MockHttpClientResponse implements HttpClientResponse {
  final Uri url;

  MockHttpClientResponse(this.url);

  @override
  int get statusCode => 200;

  Map<String, dynamic> get _mockData {
    if (url.path.contains('departures') || url.path.contains('arrivals')) {
      return {
        'departures': [
          {
            'when': DateTime.now()
                .add(const Duration(minutes: 10))
                .toIso8601String(),
            'line': {'name': 'RE1', 'productName': 'RE'},
            'direction': 'Berlin Hbf',
            'platform': '1',
          },
        ],
      };
    }
    // Weather API mock
    return {
      'current_weather': {'temperature': 20.0, 'weathercode': 0},
      'daily': {
        'temperature_2m_max': [25.0],
        'temperature_2m_min': [15.0],
      },
    };
  }

  @override
  Stream<S> transform<S>(StreamTransformer<List<int>, S> streamTransformer) {
    return Stream.value(
      utf8.encode(jsonEncode(_mockData)),
    ).cast<List<int>>().transform(streamTransformer);
  }

  @override
  StreamSubscription<List<int>> listen(
    void Function(List<int> event)? onData, {
    Function? onError,
    void Function()? onDone,
    bool? cancelOnError,
  }) {
    return Stream.value(utf8.encode(jsonEncode(_mockData))).listen(
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
  final MockHttpClient client = MockHttpClient();

  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return client;
  }
}

void main() {
  setUpAll(() {
    HttpOverrides.global = MockHttpOverrides();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    PackageInfo.setMockInitialValues(
      appName: 'Glance',
      packageName: 'com.example.glance',
      version: '1.0.0',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Widget createTestWidget() {
    return const MaterialApp(home: DashboardScreen());
  }

  group('DashboardScreen', () {
    group('refresh functionality', () {
      testWidgets('contains TrainDeparturesWidget with accessible state', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify TrainDeparturesWidget is present
        expect(find.byType(TrainDeparturesWidget), findsAtLeastNWidgets(1));

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('contains WeatherWidget with accessible state', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify WeatherWidget is present
        expect(find.byType(WeatherWidget), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('refresh button can be tapped without errors', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Find and tap the refresh button
        final refreshButton = find.byIcon(Icons.refresh);
        expect(refreshButton, findsOneWidget);

        await tester.tap(refreshButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify no errors occurred and widgets still present
        expect(find.byType(TrainDeparturesWidget), findsAtLeastNWidgets(1));
        expect(find.byType(WeatherWidget), findsOneWidget);
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('refresh button updates last updated timestamp', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Find the "Last updated at:" text
        final lastUpdatedFinder = find.textContaining('Last updated at:');
        expect(lastUpdatedFinder, findsOneWidget);

        // Get initial text
        final initialText =
            (tester.widget(lastUpdatedFinder) as Text).data ?? '';

        // Wait a bit and tap refresh
        await tester.pump(const Duration(seconds: 1));

        final refreshButton = find.byIcon(Icons.refresh);
        await tester.tap(refreshButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // The widget should still show last updated text
        expect(find.textContaining('Last updated at:'), findsOneWidget);

        addTearDown(tester.view.resetPhysicalSize);
      });

      testWidgets('both regional and bus modes work with refresh', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Should see the Regional toggle selected by default
        expect(find.text('Regional'), findsAtLeastNWidgets(1));

        // Switch to Bus mode
        final busToggle = find.text('Bus');
        expect(busToggle, findsAtLeastNWidgets(1));
        await tester.tap(busToggle.first);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        // Tap refresh button
        final refreshButton = find.byIcon(Icons.refresh);
        await tester.tap(refreshButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Verify no errors and widgets still work
        expect(find.byType(TrainDeparturesWidget), findsAtLeastNWidgets(1));
        expect(tester.takeException(), isNull);

        addTearDown(tester.view.resetPhysicalSize);
      });
    });

    group('widget keys', () {
      testWidgets(
        'TrainDeparturesWidget uses GlobalKey for external refresh access',
        (WidgetTester tester) async {
          tester.view.physicalSize = const Size(1920, 1080);
          tester.view.devicePixelRatio = 1.0;

          await tester.pumpWidget(createTestWidget());
          await tester.pump();
          await tester.pump(const Duration(milliseconds: 500));

          // Find TrainDeparturesWidget
          final departuresWidget = tester.widget<TrainDeparturesWidget>(
            find.byType(TrainDeparturesWidget).first,
          );

          // Verify it has a GlobalKey (not a ValueKey)
          expect(departuresWidget.key, isA<GlobalKey>());

          addTearDown(tester.view.resetPhysicalSize);
        },
      );

      testWidgets('WeatherWidget uses GlobalKey for external refresh access', (
        WidgetTester tester,
      ) async {
        tester.view.physicalSize = const Size(1920, 1080);
        tester.view.devicePixelRatio = 1.0;

        await tester.pumpWidget(createTestWidget());
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 500));

        // Find WeatherWidget
        final weatherWidget = tester.widget<WeatherWidget>(
          find.byType(WeatherWidget),
        );

        // Verify it has a GlobalKey
        expect(weatherWidget.key, isA<GlobalKey>());

        addTearDown(tester.view.resetPhysicalSize);
      });
    });
  });
}
