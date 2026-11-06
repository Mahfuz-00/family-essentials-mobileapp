import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:geofencing_api/geofencing_api.dart';

import '../notifications/local_notifications.dart';
import '../../features/places/domain/entities/place.dart';
import '../../features/places/domain/repositories/places_repository.dart';

/// Hardware Geofencing Manager (Approach A)
///
/// Registers native geofences with Android (LocationServices) / iOS (CoreLocation)
/// using [Geofencing].
/// 
/// Monitors both:
/// - ENTER: When arriving at stores / markets / places.
/// - EXIT: When leaving places (e.g. leaving the office or home).
///
/// Hardware triggers are handled by the OS even when the app is swiped away or closed,
/// and routed to this service to display honest local notifications.
class NativeGeofenceManager {
  NativeGeofenceManager({
    required PlacesRepository placesRepository,
    required LocalNotifications localNotifications,
  })  : _placesRepository = placesRepository,
        _localNotifications = localNotifications;

  final PlacesRepository _placesRepository;
  final LocalNotifications _localNotifications;

  final Geofencing _geofencing = Geofencing.instance;
  bool _isInitialized = false;

  /// Sets up native background geofence listening.
  Future<void> init() async {
    if (_isInitialized) return;

    try {
      _geofencing.setup(
        interval: 10000,
        accuracy: 100,
        statusChangeDelay: 5000,
        allowsMockLocation: true,
        printsDebugLog: kDebugMode,
      );

      _geofencing.addGeofenceStatusChangedListener(_onGeofenceStatusChanged);
      _geofencing.addGeofenceErrorCallbackListener(_onGeofenceError);

      _isInitialized = true;
      debugPrint('[NativeGeofenceManager] Initialized native geofence listener.');
    } catch (e) {
      debugPrint('[NativeGeofenceManager] Initialization error: $e');
    }
  }

  /// Syncs saved household places with native OS geofence regions.
  Future<void> syncPlaces(List<Place> places) async {
    try {
      final regions = <GeofenceRegion>{};

      for (final place in places) {
        // Register circular geofence with ENTER, EXIT and DWELL triggers.
        final region = GeofenceRegion.circular(
          id: 'place_${place.id}',
          data: <String, dynamic>{
            'place_id': place.id,
            'name': place.name,
            'kind': place.kind ?? 'other',
            'kind_label': place.kindLabel,
            'active_requests_count': place.activeRequestsCount ?? 0,
          },
          center: LatLng(place.latitude, place.longitude),
          radius: place.radiusMeters.toDouble().clamp(50.0, 5000.0),
        );
        regions.add(region);
      }

      if (_geofencing.isRunningService) {
        await _geofencing.stop();
      }

      _geofencing.clearAllRegions();

      if (regions.isNotEmpty) {
        await _geofencing.start(regions: regions);
        debugPrint('[NativeGeofenceManager] Started geofencing with ${regions.length} regions.');
      }
    } catch (e) {
      debugPrint('[NativeGeofenceManager] Failed to sync regions: $e');
    }
  }

  /// Triggered whenever the OS detects an ENTER or EXIT transition.
  Future<void> _onGeofenceStatusChanged(
    GeofenceRegion region,
    GeofenceStatus status,
    Location location,
  ) async {
    final Map<String, dynamic>? data = region.data is Map<String, dynamic>
        ? region.data as Map<String, dynamic>
        : null;

    final placeId = data?['place_id'] as int?;
    final placeName = data?['name'] as String? ?? 'Saved Place';
    final kind = data?['kind'] as String? ?? 'other';
    final activeRequestsCount = data?['active_requests_count'] as int? ?? 0;

    debugPrint(
      '[NativeGeofenceManager] Transition: ${status.name} at $placeName (id: $placeId, kind: $kind)',
    );

    if (placeId == null) return;

    // Report device position and transition to backend so server records event & returns filtered arrival
    try {
      final evaluation = await _placesRepository.reportPosition(
        latitude: location.latitude,
        longitude: location.longitude,
      );

      // If the server produced sent arrivals, LocalNotifications handles them
      if (evaluation.arrivals.any((a) => a.isSent)) {
        for (final arrival in evaluation.arrivals.where((a) => a.isSent)) {
          _localNotifications.showArrival(arrival);
        }
      } else {
        // Trigger fallback notification if departure from office/home or entry to store
        _fallbackLocalNotification(status, placeId, placeName, kind, activeRequestsCount);
      }
    } catch (e) {
      debugPrint('[NativeGeofenceManager] Exception during transition handling: $e');
      _fallbackLocalNotification(status, placeId, placeName, kind, activeRequestsCount);
    }
  }

  void _fallbackLocalNotification(
    GeofenceStatus status,
    int placeId,
    String placeName,
    String kind,
    int activeCount,
  ) {
    String title = placeName;
    String body;

    if (status == GeofenceStatus.enter) {
      body = activeCount > 0
          ? 'Arrived at $placeName — $activeCount ${activeCount == 1 ? "item" : "items"} on the list.'
          : 'Arrived at $placeName.';
    } else {
      // EXIT / DEPARTURE
      if (kind == 'office') {
        body = activeCount > 0
            ? 'Leaving work: $activeCount ${activeCount == 1 ? "item" : "items"} to pick up.'
            : 'Leaving work: check pending household errands.';
      } else if (kind == 'home') {
        body = activeCount > 0
            ? 'You left home: $activeCount ${activeCount == 1 ? "task" : "tasks"} still open.'
            : 'You left home.';
      } else {
        body = activeCount > 0
            ? 'Leaving $placeName — $activeCount ${activeCount == 1 ? "item" : "items"} remaining.'
            : 'Leaving $placeName.';
      }
    }

    _localNotifications.showArrival(
      LocationArrival(
        id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        placeId: placeId,
        kind: kind,
        status: 'sent',
        placeName: placeName,
        title: title,
        body: body,
        taskCount: activeCount,
      ),
    );
  }

  void _onGeofenceError(Object error, [StackTrace? stackTrace]) {
    debugPrint('[NativeGeofenceManager] Geofence error: $error\n$stackTrace');
  }
}
