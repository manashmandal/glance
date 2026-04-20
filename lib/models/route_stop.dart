enum RouteStopRole { current, intermediate, destination }

/// A single stop on the dashboard route rail. Role encodes whether this
/// is the traveler's current station, an interchange, or the destination.
class RouteStop {
  final String name;
  final RouteStopRole role;

  const RouteStop({
    required this.name,
    this.role = RouteStopRole.intermediate,
  });

  bool get isCurrent => role == RouteStopRole.current;
  bool get isDestination => role == RouteStopRole.destination;
}
