import 'package:flutter_test/flutter_test.dart';
import 'package:glance/models/route_stop.dart';

void main() {
  group('RouteStop', () {
    test('defaults to intermediate role', () {
      const stop = RouteStop(name: 'Ostkreuz');
      expect(stop.role, equals(RouteStopRole.intermediate));
      expect(stop.isCurrent, isFalse);
      expect(stop.isDestination, isFalse);
    });

    test('current role reports isCurrent', () {
      const stop = RouteStop(name: 'A', role: RouteStopRole.current);
      expect(stop.isCurrent, isTrue);
      expect(stop.isDestination, isFalse);
    });

    test('destination role reports isDestination', () {
      const stop = RouteStop(name: 'Z', role: RouteStopRole.destination);
      expect(stop.isDestination, isTrue);
      expect(stop.isCurrent, isFalse);
    });
  });
}
