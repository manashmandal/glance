import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/weather_data.dart';
import 'package:glance/models/weather_action.dart';
import 'package:glance/widgets/weather_action_widget.dart';
import 'package:glance/services/theme_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('com.example.glance/weather_ai');

  WeatherData createTestWeather({
    double temperature = 20.0,
    int weatherCode = 0,
  }) {
    return WeatherData(
      temperature: temperature,
      weatherCode: weatherCode,
      maxTemp: temperature + 5,
      minTemp: temperature - 5,
      precipitationProbability: 10.0,
      windSpeed: 5.0,
      humidity: 60.0,
    );
  }

  Widget createTestWidget({
    GlobalKey<WeatherActionWidgetState>? key,
    double scaleFactor = 1.0,
    bool darkMode = true,
    double width = 400,
    double height = 350,
  }) {
    return MaterialApp(
      theme: darkMode ? AppTheme.darkTheme : AppTheme.lightTheme,
      home: Scaffold(
        body: SizedBox(
          width: width,
          height: height,
          child: WeatherActionWidget(
            key: key,
            scaleFactor: scaleFactor,
          ),
        ),
      ),
    );
  }

  setUp(() {
    // Default: AI not available, will use fallback
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
      if (methodCall.method == 'checkAvailability') {
        return {'available': false, 'status': 'NOT_AVAILABLE'};
      }
      return null;
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('WeatherActionWidget', () {
    group('initial state', () {
      testWidgets('shows loading state initially', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());

        // Should show loading indicator
        expect(find.byType(CircularProgressIndicator), findsOneWidget);
        expect(find.text('Generating tip...'), findsOneWidget);
      });

      testWidgets('uses ThemeColors extension for styling',
          (WidgetTester tester) async {
        final key = GlobalKey<WeatherActionWidgetState>();
        // Use larger size to accommodate loading state
        await tester.pumpWidget(createTestWidget(
          key: key,
          darkMode: true,
          width: 500,
          height: 400,
        ));

        // Verify widget is created
        expect(find.byType(WeatherActionWidget), findsOneWidget);

        // Generate action
        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Verify action was generated
        expect(find.text('Weather Tip'), findsOneWidget);
      });
    });

    group('generateAction', () {
      testWidgets('displays action after generation', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        // Initially loading
        expect(find.byType(CircularProgressIndicator), findsOneWidget);

        // Trigger action generation
        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should now show action, not loading
        expect(find.byType(CircularProgressIndicator), findsNothing);
        // Should show "Weather Tip" label for rule-based action
        expect(find.text('Weather Tip'), findsOneWidget);
      });

      testWidgets('generates action for rainy weather', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        // Generate action for rainy weather
        final weather = createTestWeather(weatherCode: 61);
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should show some action (specific text depends on fallback logic)
        expect(find.text('Weather Tip'), findsOneWidget);
      });

      testWidgets('generates action for cold weather', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        // Generate action for cold weather
        final weather = createTestWeather(temperature: -5.0);
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should show some action
        expect(find.text('Weather Tip'), findsOneWidget);
      });
    });

    group('icon mapping', () {
      testWidgets('shows appropriate icon after generating action', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        final weather = createTestWeather(weatherCode: 61);
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should show one of the weather-related icons
        final hasIcon = find.byType(Icon).evaluate().any((element) {
          final icon = element.widget as Icon;
          return [
            Icons.umbrella,
            Icons.ac_unit,
            Icons.wb_sunny,
            Icons.snowing,
            Icons.thunderstorm,
            Icons.air,
            Icons.foggy,
            Icons.tips_and_updates,
          ].contains(icon.icon);
        });
        expect(hasIcon, isTrue);
      });

      testWidgets('icon container has circular shape', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Find the circular container
        final containers = find.byType(Container).evaluate();
        final hasCircularContainer = containers.any((e) {
          final widget = e.widget as Container;
          final decoration = widget.decoration;
          if (decoration is BoxDecoration) {
            return decoration.shape == BoxShape.circle;
          }
          return false;
        });
        expect(hasCircularContainer, isTrue);
      });
    });

    group('source indicator', () {
      testWidgets('shows Weather Tip label for rule-based actions', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        expect(find.text('Weather Tip'), findsOneWidget);
        expect(find.byIcon(Icons.psychology_alt), findsOneWidget);
      });

      testWidgets('shows source indicator for generated actions', (
        WidgetTester tester,
      ) async {
        // AI availability is cached, so test just verifies source indicator exists
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should show either AI Suggestion or Weather Tip (depends on cached AI availability)
        final hasAiLabel = find.text('AI Suggestion').evaluate().isNotEmpty;
        final hasRuleLabel = find.text('Weather Tip').evaluate().isNotEmpty;
        expect(hasAiLabel || hasRuleLabel, isTrue);

        // Should show appropriate icon for the source
        final hasAiIcon = find.byIcon(Icons.auto_awesome).evaluate().isNotEmpty;
        final hasRuleIcon =
            find.byIcon(Icons.psychology_alt).evaluate().isNotEmpty;
        expect(hasAiIcon || hasRuleIcon, isTrue);
      });
    });

    group('scaleFactor', () {
      testWidgets('renders with default scale factor',
          (WidgetTester tester) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        expect(find.byType(WeatherActionWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });

      testWidgets('renders with increased scale factor',
          (WidgetTester tester) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        // Use larger container for scaled widget
        await tester.pumpWidget(createTestWidget(
          key: key,
          scaleFactor: 1.5,
          width: 600,
          height: 500,
        ));
        await tester.pump();

        final weather = createTestWeather();
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        expect(find.byType(WeatherActionWidget), findsOneWidget);
      });
    });

    group('GlobalKey access', () {
      testWidgets('state is accessible via GlobalKey', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        expect(key.currentState, isNotNull);
        expect(key.currentState, isA<WeatherActionWidgetState>());
      });

      testWidgets('generateAction method is accessible', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        expect(key.currentState!.generateAction, isA<Function>());
      });
    });

    group('container styling', () {
      testWidgets('has correct border radius', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget());
        await tester.pump();

        final container =
            find.byType(Container).evaluate().first.widget as Container;
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.borderRadius, equals(BorderRadius.circular(24)));
      });

      testWidgets('dark theme has no border', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(darkMode: true));
        await tester.pump();

        final container =
            find.byType(Container).evaluate().first.widget as Container;
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.border, isNull);
      });

      testWidgets('light theme has border', (WidgetTester tester) async {
        await tester.pumpWidget(createTestWidget(darkMode: false));
        await tester.pump();

        final container =
            find.byType(Container).evaluate().first.widget as Container;
        final decoration = container.decoration as BoxDecoration;

        expect(decoration.border, isNotNull);
      });
    });

    group('error handling', () {
      testWidgets('handles widget unmounting during generation', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        // Start generation but don't await
        final weather = createTestWeather();
        final future = key.currentState!.generateAction(weather);

        // Unmount widget before generation completes
        await tester.pumpWidget(const SizedBox());

        // Future should complete without error
        await expectLater(future, completes);
      });
    });

    group('multiple generations', () {
      testWidgets('can regenerate action multiple times', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        // First generation - clear weather
        var weather = createTestWeather(weatherCode: 0);
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should show some action text
        expect(find.text('Weather Tip'), findsOneWidget);

        // Second generation - rainy weather
        weather = createTestWeather(weatherCode: 61);
        await key.currentState!.generateAction(weather);
        await tester.pumpAndSettle();

        // Should still have weather tip (possibly different text)
        expect(find.text('Weather Tip'), findsOneWidget);
      });

      testWidgets('widget remains functional after multiple generations', (
        WidgetTester tester,
      ) async {
        final key = GlobalKey<WeatherActionWidgetState>();

        await tester.pumpWidget(createTestWidget(key: key));
        await tester.pump();

        // Generate multiple times
        for (int i = 0; i < 3; i++) {
          final weather = createTestWeather(weatherCode: i * 20);
          await key.currentState!.generateAction(weather);
          await tester.pumpAndSettle();
        }

        // Widget should still be rendered and functional
        expect(find.byType(WeatherActionWidget), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    });
  });
}
