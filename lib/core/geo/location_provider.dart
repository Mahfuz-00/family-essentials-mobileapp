import '../../core/geo/geofence_evaluator.dart';

/// The seam a real geolocation plugin plugs into.
///
/// Phase 5 ships [MockLocationProvider] so the geofence flow can be demoed and
/// tested without hardware. A `GeolocatorLocationProvider` (geolocator +
/// background service on Android, background location mode on iOS) implements
/// this same interface once it can be validated on a device - see
/// `Docs/phase-5-device-test-plan.md`.
abstract class LocationProvider {
  Future<GeoPoint> currentPosition();

  Future<bool> requestPermission();
}

class MockLocationProvider implements LocationProvider {
  GeoPoint? _simulated;

  /// Pretend the device is at [point] (used by the "simulate arrival" action).
  void simulate(GeoPoint point) => _simulated = point;

  @override
  Future<GeoPoint> currentPosition() async =>
      _simulated ?? const GeoPoint(0, 0);

  @override
  Future<bool> requestPermission() async => true;
}
