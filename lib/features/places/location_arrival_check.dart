import '../../core/error/failures.dart';
import '../../core/geo/location_provider.dart';
import '../../core/notifications/local_notifications.dart';
import 'domain/entities/place.dart';
import 'domain/repositories/places_repository.dart';

enum ArrivalCheckStatus {
  /// The member has not opted in, so nothing was attempted.
  disabled,

  /// The operating system has not granted location access.
  permissionDenied,

  /// No saved place was close enough to be an arrival.
  nothingNearby,

  /// At least one arrival decision came back.
  checked,

  /// The position or the report could not be obtained.
  failed,
}

class ArrivalCheckResult {
  const ArrivalCheckResult({
    required this.status,
    this.notified = const [],
    this.message,
  });

  final ArrivalCheckStatus status;

  /// The arrivals the server decided to send — already deduped and filtered.
  final List<LocationArrival> notified;

  final String? message;

  bool get showedSomething => notified.isNotEmpty;
}

/// Ties a device position to the server's arrival decision and the local
/// notification.
///
/// The rules — opt-in, quiet hours, cooldown, who owns which task — all live on
/// the server. This class only decides *whether to ask* (opted in, permission
/// granted) and then displays what came back, which is what keeps the app from
/// inventing notifications the API did not authorise.
class LocationArrivalCheck {
  const LocationArrivalCheck({
    required LocationProvider provider,
    required PlacesRepository places,
    required LocalNotifications notifications,
  }) : _provider = provider,
       _places = places,
       _notifications = notifications;

  final LocationProvider _provider;
  final PlacesRepository _places;
  final LocalNotifications _notifications;

  Future<ArrivalCheckResult> run({required bool enabled}) async {
    if (!enabled) {
      return const ArrivalCheckResult(status: ArrivalCheckStatus.disabled);
    }

    // Check, never prompt: a member who declined must not be asked again on
    // every resume.
    if (!await _provider.hasPermission()) {
      return const ArrivalCheckResult(
        status: ArrivalCheckStatus.permissionDenied,
        message:
            'Location permission is off, so arrivals are not checked. '
            'Time-based reminders still work.',
      );
    }

    try {
      final position = await _provider.currentPosition();
      final evaluation = await _places.reportPosition(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      final sent = evaluation.arrivals
          .where((arrival) => arrival.isSent)
          .toList();

      for (final arrival in sent) {
        await _notifications.showArrival(arrival);
      }

      return ArrivalCheckResult(
        status: sent.isEmpty
            ? ArrivalCheckStatus.nothingNearby
            : ArrivalCheckStatus.checked,
        notified: sent,
      );
    } on AppFailure catch (failure) {
      return ArrivalCheckResult(
        status: ArrivalCheckStatus.failed,
        message: failure.message,
      );
    } catch (error) {
      return ArrivalCheckResult(
        status: ArrivalCheckStatus.failed,
        message: error.toString(),
      );
    }
  }
}
