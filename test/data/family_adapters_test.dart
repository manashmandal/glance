import 'package:flutter_test/flutter_test.dart';
import 'package:glance/data/family_adapters.dart';
import 'package:glance/models/journey.dart';
import 'package:glance/models/route_stop.dart';

void main() {
  group('FamilyAdapters.routeStops', () {
    test('returns empty list when journey is null', () {
      expect(FamilyAdapters.routeStops(null), isEmpty);
    });

    test('returns empty list when journey has no legs', () {
      expect(
        FamilyAdapters.routeStops(const Journey(legs: [])),
        isEmpty,
      );
    });

    test('returns empty list when all legs are walking', () {
      final journey = Journey(legs: [
        _leg(
          originId: 'a',
          originName: 'A',
          destinationId: 'b',
          destinationName: 'B',
          walking: true,
        ),
      ]);
      expect(FamilyAdapters.routeStops(journey), isEmpty);
    });

    test('returns empty list when fewer than two unique stops survive dedup',
        () {
      final journey = Journey(legs: [
        _leg(
          originId: 'a',
          originName: 'A',
          destinationId: 'a',
          destinationName: 'A',
        ),
      ]);
      expect(FamilyAdapters.routeStops(journey), isEmpty);
    });

    test('marks first stop as current and last as destination', () {
      final journey = Journey(legs: [
        _leg(
          originId: 'a',
          originName: 'A',
          destinationId: 'b',
          destinationName: 'B',
        ),
        _leg(
          originId: 'b',
          originName: 'B',
          destinationId: 'c',
          destinationName: 'C',
        ),
      ]);
      final stops = FamilyAdapters.routeStops(journey);
      expect(stops.map((s) => s.name).toList(), equals(['A', 'B', 'C']));
      expect(stops.first.role, equals(RouteStopRole.current));
      expect(stops.last.role, equals(RouteStopRole.destination));
      expect(stops[1].role, equals(RouteStopRole.intermediate));
    });

    test('skips walking legs so chain stays coherent', () {
      final journey = Journey(legs: [
        _leg(
          originId: 'a',
          originName: 'A',
          destinationId: 'b',
          destinationName: 'B',
        ),
        _leg(
          originId: 'b',
          originName: 'B',
          destinationId: 'b2',
          destinationName: 'B platform 2',
          walking: true,
        ),
        _leg(
          originId: 'b2',
          originName: 'B platform 2',
          destinationId: 'c',
          destinationName: 'C',
        ),
      ]);
      final stops = FamilyAdapters.routeStops(journey);
      // Walking leg's destination shouldn't show up as an intermediate stop.
      expect(stops.map((s) => s.name).toList(), equals(['A', 'B', 'C']));
    });

    test('dedupes consecutive repeats by id', () {
      final journey = Journey(legs: [
        _leg(
          originId: 'a',
          originName: 'A',
          destinationId: 'b',
          destinationName: 'B',
        ),
        _leg(
          originId: 'b',
          originName: 'B',
          destinationId: 'b',
          destinationName: 'B',
        ),
        _leg(
          originId: 'b',
          originName: 'B',
          destinationId: 'c',
          destinationName: 'C',
        ),
      ]);
      expect(
        FamilyAdapters.routeStops(journey).map((s) => s.name).toList(),
        equals(['A', 'B', 'C']),
      );
    });

    test('strips "(Berlin)" and " Bhf" suffixes from station names', () {
      final journey = Journey(legs: [
        _leg(
          originId: 'a',
          originName: 'S+U Alexanderplatz Bhf (Berlin)',
          destinationId: 'b',
          destinationName: 'Ostkreuz (Berlin)',
        ),
      ]);
      final stops = FamilyAdapters.routeStops(journey);
      expect(stops.first.name, equals('S+U Alexanderplatz'));
      expect(stops.last.name, equals('Ostkreuz'));
    });
  });
}

JourneyLeg _leg({
  required String originId,
  required String originName,
  required String destinationId,
  required String destinationName,
  bool walking = false,
}) {
  return JourneyLeg(
    originId: originId,
    originName: originName,
    destinationId: destinationId,
    destinationName: destinationName,
    walking: walking,
  );
}
