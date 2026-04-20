import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/api_diagnostics.dart';

void main() {
  setUp(ApiDiagnostics.reset);

  group('ApiDiagnostics.bvgDegraded', () {
    test('returns false when no attempts have been made', () {
      expect(ApiDiagnostics.bvgDegraded, isFalse);
    });

    test('returns false after a successful BVG attempt', () {
      ApiDiagnostics.record(_attempt(success: true));
      expect(ApiDiagnostics.bvgDegraded, isFalse);
    });

    test('returns true when most recent attempt fails and no prior success',
        () {
      ApiDiagnostics.record(_attempt(success: false));
      expect(ApiDiagnostics.bvgDegraded, isTrue);
    });

    test('returns false when last failure is within the stale threshold', () {
      // Success 1 minute ago, then a failure now → not yet stale.
      ApiDiagnostics.record(_attempt(
        success: true,
        at: DateTime.now().subtract(const Duration(minutes: 1)),
      ));
      ApiDiagnostics.record(_attempt(success: false));
      expect(ApiDiagnostics.bvgDegraded, isFalse);
    });

    test('returns true when last success was beyond the stale threshold', () {
      ApiDiagnostics.record(_attempt(
        success: true,
        at: DateTime.now().subtract(const Duration(minutes: 10)),
      ));
      ApiDiagnostics.record(_attempt(success: false));
      expect(ApiDiagnostics.bvgDegraded, isTrue);
    });

    test('only considers BVG-source attempts', () {
      ApiDiagnostics.record(_attempt(
        success: false,
        source: ApiSource.weather,
      ));
      expect(ApiDiagnostics.bvgDegraded, isFalse);
    });
  });

  group('ApiDiagnostics.bvgUptimeWindow', () {
    test('pads with success when there is no history', () {
      expect(
        ApiDiagnostics.bvgUptimeWindow(length: 5),
        equals(<bool>[true, true, true, true, true]),
      );
    });

    test('orders attempts oldest-first within the window', () {
      // Record three failures then one success — internal storage is
      // newest-first; the window must reverse it to oldest-first.
      ApiDiagnostics.record(_attempt(success: false));
      ApiDiagnostics.record(_attempt(success: false));
      ApiDiagnostics.record(_attempt(success: false));
      ApiDiagnostics.record(_attempt(success: true));

      final window = ApiDiagnostics.bvgUptimeWindow(length: 4);
      expect(window, equals(<bool>[false, false, false, true]));
    });

    test('only counts BVG attempts', () {
      ApiDiagnostics.record(_attempt(success: false, source: ApiSource.weather));
      ApiDiagnostics.record(_attempt(success: true));

      final window = ApiDiagnostics.bvgUptimeWindow(length: 2);
      expect(window, equals(<bool>[true, true]));
    });
  });

  group('ApiDiagnostics.recent', () {
    test('caps at the maximum buffer size', () {
      for (var i = 0; i < 20; i++) {
        ApiDiagnostics.record(_attempt(success: i.isEven));
      }
      expect(ApiDiagnostics.recent.length, lessThanOrEqualTo(12));
    });

    test('returns most recent first', () {
      ApiDiagnostics.record(_attempt(
        success: true,
        endpoint: 'first',
      ));
      ApiDiagnostics.record(_attempt(
        success: false,
        endpoint: 'second',
      ));
      expect(ApiDiagnostics.recent.first.endpoint, equals('second'));
      expect(ApiDiagnostics.recent.last.endpoint, equals('first'));
    });
  });

  group('ApiDiagnostics.lastBvgSuccess', () {
    test('is null until a BVG success is recorded', () {
      ApiDiagnostics.record(_attempt(success: false));
      ApiDiagnostics.record(_attempt(success: true, source: ApiSource.weather));
      expect(ApiDiagnostics.lastBvgSuccess, isNull);
    });

    test('updates only on BVG success', () {
      final t1 = DateTime(2026, 1, 1, 12);
      final t2 = DateTime(2026, 1, 1, 12, 5);
      ApiDiagnostics.record(_attempt(success: true, at: t1));
      ApiDiagnostics.record(_attempt(success: false, at: t2));
      expect(ApiDiagnostics.lastBvgSuccess, equals(t1));
    });
  });
}

ApiAttempt _attempt({
  required bool success,
  ApiSource source = ApiSource.bvg,
  String endpoint = 'test/endpoint',
  DateTime? at,
}) {
  return ApiAttempt(
    endpoint: endpoint,
    statusLabel: success ? '200 · 100ms' : 'timeout · 8s',
    success: success,
    at: at ?? DateTime.now(),
    source: source,
  );
}
