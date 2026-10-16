import 'dart:math' as math;

class GeoPoint {
  const GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}

class GeofenceTransition {
  const GeofenceTransition({
    required this.placeId,
    required this.entered,
    required this.distanceMeters,
  });

  final int placeId;
  final bool entered;
  final double distanceMeters;
}

/// Dart port of the backend's `App\Geo\GeofenceEvaluator` - pure maths, no
/// platform calls, so it is unit tested without a device.
class GeofenceEvaluator {
  const GeofenceEvaluator();

  static const double _earthRadiusMeters = 6371000.0;

  double distanceMeters(GeoPoint from, GeoPoint to) {
    final lat1 = _radians(from.latitude);
    final lat2 = _radians(to.latitude);
    final deltaLat = _radians(to.latitude - from.latitude);
    final deltaLng = _radians(to.longitude - from.longitude);

    final a =
        math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1) *
            math.cos(lat2) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    return 2 * _earthRadiusMeters * math.asin(math.min(1.0, math.sqrt(a)));
  }

  bool isWithin(GeoPoint center, int radiusMeters, GeoPoint point) =>
      distanceMeters(center, point) <= radiusMeters;

  List<GeofenceTransition> evaluate(
    List<({int placeId, GeoPoint point, int radius})> places,
    GeoPoint current,
    Map<int, bool> previouslyInside,
  ) {
    final transitions = <GeofenceTransition>[];

    for (final place in places) {
      final distance = distanceMeters(place.point, current);
      final inside = distance <= place.radius;
      final wasInside = previouslyInside[place.placeId] ?? false;

      if (inside && !wasInside) {
        transitions.add(
          GeofenceTransition(
            placeId: place.placeId,
            entered: true,
            distanceMeters: distance,
          ),
        );
      } else if (!inside && wasInside) {
        transitions.add(
          GeofenceTransition(
            placeId: place.placeId,
            entered: false,
            distanceMeters: distance,
          ),
        );
      }
    }

    return transitions;
  }

  double _radians(double degrees) => degrees * math.pi / 180.0;
}
