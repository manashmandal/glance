import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/weather_action.dart';

void main() {
  group('WeatherAction', () {
    test('creates with required parameters', () {
      final now = DateTime.now();
      final action = WeatherAction(
        action: 'Take an umbrella',
        generatedAt: now,
        source: WeatherActionSource.aiGenerated,
      );

      expect(action.action, equals('Take an umbrella'));
      expect(action.generatedAt, equals(now));
      expect(action.source, equals(WeatherActionSource.aiGenerated));
      expect(action.icon, isNull);
    });

    test('creates with optional icon', () {
      final action = WeatherAction(
        action: 'Stay warm',
        icon: 'cold',
        generatedAt: DateTime.now(),
        source: WeatherActionSource.ruleBased,
      );

      expect(action.icon, equals('cold'));
    });

    group('factory constructors', () {
      test('fallback creates rule-based action', () {
        final action = WeatherAction.fallback('Wear a jacket');

        expect(action.action, equals('Wear a jacket'));
        expect(action.source, equals(WeatherActionSource.ruleBased));
        expect(action.icon, isNull);
      });

      test('fallback with icon', () {
        final action =
            WeatherAction.fallback('Bring umbrella', icon: 'umbrella');

        expect(action.action, equals('Bring umbrella'));
        expect(action.icon, equals('umbrella'));
        expect(action.source, equals(WeatherActionSource.ruleBased));
      });

      test('fromAi creates AI-generated action', () {
        final action = WeatherAction.fromAi('Consider bringing a light jacket');

        expect(action.action, equals('Consider bringing a light jacket'));
        expect(action.source, equals(WeatherActionSource.aiGenerated));
      });

      test('fromAi with icon', () {
        final action = WeatherAction.fromAi('Stay hydrated', icon: 'hot');

        expect(action.icon, equals('hot'));
        expect(action.source, equals(WeatherActionSource.aiGenerated));
      });
    });

    group('isStale', () {
      test('returns false for recent action', () {
        final action = WeatherAction(
          action: 'Test',
          generatedAt: DateTime.now(),
          source: WeatherActionSource.ruleBased,
        );

        expect(action.isStale, isFalse);
      });

      test('returns false for action under 30 minutes old', () {
        final action = WeatherAction(
          action: 'Test',
          generatedAt: DateTime.now().subtract(const Duration(minutes: 29)),
          source: WeatherActionSource.ruleBased,
        );

        expect(action.isStale, isFalse);
      });

      test('returns true for action over 30 minutes old', () {
        final action = WeatherAction(
          action: 'Test',
          generatedAt: DateTime.now().subtract(const Duration(minutes: 31)),
          source: WeatherActionSource.ruleBased,
        );

        expect(action.isStale, isTrue);
      });

      test('returns true for action 1 hour old', () {
        final action = WeatherAction(
          action: 'Test',
          generatedAt: DateTime.now().subtract(const Duration(hours: 1)),
          source: WeatherActionSource.ruleBased,
        );

        expect(action.isStale, isTrue);
      });
    });
  });

  group('WeatherActionSource', () {
    test('has aiGenerated value', () {
      expect(WeatherActionSource.aiGenerated, isNotNull);
    });

    test('has ruleBased value', () {
      expect(WeatherActionSource.ruleBased, isNotNull);
    });

    test('values are distinct', () {
      expect(
        WeatherActionSource.aiGenerated,
        isNot(equals(WeatherActionSource.ruleBased)),
      );
    });
  });
}
