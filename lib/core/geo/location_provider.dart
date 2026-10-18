import '../../core/geo/geofence_evaluator.dart';

/// The seam a real geolocation plugin plugs into.
///
/// One implementation ships: [GeolocatorLocationProvider], for a device. The
/// arrival simulation reads the place's own coordinates through the repository
/// instead, so it works on a machine with no location plugin at all and no mock
/// provider is needed.
///
/// Foreground only. Nothing here starts a background service or reads a position
/// while the app is not running — arrival while the app is closed needs platform
/// permissions this project has deliberately not asked for.
abstract class LocationProvider {
  /// Whether permission has already been granted. Must not prompt.
  Future<bool> hasPermission();

  /// Ask the operating system. Returns false when the member declines, and
  /// callers must degrade gracefully rather than insisting.
  Future<bool> requestPermission();

  /// A current fix. Throws when the position cannot be read.
  Future<GeoPoint> currentPosition();
}
