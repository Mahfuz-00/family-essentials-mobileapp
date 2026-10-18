import 'package:geolocator/geolocator.dart';

import 'geofence_evaluator.dart';
import 'location_provider.dart';

/// Reads a real device position — while the app is open.
///
/// The permission handling is deliberately conservative: it checks first, asks
/// only when asked to, and reports a refusal instead of insisting. Arrival while
/// the app is backgrounded or closed is **not** implemented: that needs
/// `ACCESS_BACKGROUND_LOCATION` plus a foreground service on Android, and the
/// `location` background mode on iOS, none of which this app declares.
class GeolocatorLocationProvider implements LocationProvider {
  const GeolocatorLocationProvider();

  @override
  Future<bool> hasPermission() async {
    final permission = await Geolocator.checkPermission();

    return permission == LocationPermission.whileInUse ||
        permission == LocationPermission.always;
  }

  @override
  Future<bool> requestPermission() async {
    if (await hasPermission()) {
      return true;
    }

    final permission = await Geolocator.checkPermission();

    // A permanent refusal cannot be prompted again; the member has to change it
    // in system settings, which the app explains rather than fighting.
    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    final requested = await Geolocator.requestPermission();

    return requested == LocationPermission.whileInUse ||
        requested == LocationPermission.always;
  }

  @override
  Future<GeoPoint> currentPosition() async {
    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 20),
      ),
    );

    return GeoPoint(position.latitude, position.longitude);
  }
}
