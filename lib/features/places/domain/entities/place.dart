import 'package:equatable/equatable.dart';

import '../../../../core/geo/geofence_evaluator.dart';

class Place extends Equatable {
  const Place({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.address,
    this.category,
    this.kind,
    this.kindLabel,
    this.activeRequestsCount,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? address;

  /// The saved-place category (`home`, `office`, `grocery`, `pharmacy`, …).
  final String? category;

  /// The notification-facing kind, derived server-side from [category]. The app
  /// never re-implements that mapping — it displays what the API decided.
  final String? kind;

  final String? kindLabel;
  final int? activeRequestsCount;

  GeoPoint get point => GeoPoint(latitude, longitude);

  @override
  List<Object?> get props => [
    id,
    name,
    latitude,
    longitude,
    radiusMeters,
    address,
    category,
    kind,
    kindLabel,
    activeRequestsCount,
  ];
}

class GeofenceTransitionResult extends Equatable {
  const GeofenceTransitionResult({
    required this.placeId,
    required this.entered,
    required this.distanceMeters,
  });

  final int placeId;
  final bool entered;
  final double distanceMeters;

  @override
  List<Object?> get props => [placeId, entered, distanceMeters];
}

class GeofenceEvaluation extends Equatable {
  const GeofenceEvaluation({
    required this.transitions,
    required this.shoppingLists,
    this.arrivals = const [],
  });

  final List<GeofenceTransitionResult> transitions;
  final List<ShoppingList> shoppingLists;

  /// What the server decided on this report: one per entry, whether sent or
  /// refused with a reason.
  final List<LocationArrival> arrivals;

  @override
  List<Object?> get props => [transitions, shoppingLists, arrivals];
}

class ShoppingList extends Equatable {
  const ShoppingList({required this.place, required this.requests});

  final Place place;
  final List<NearbyRequest> requests;

  @override
  List<Object?> get props => [place, requests];
}

/// Minimal request shape for the "near this store" list.
class NearbyRequest extends Equatable {
  const NearbyRequest({
    required this.id,
    required this.title,
    required this.status,
    this.quantity,
  });

  final int id;
  final String title;
  final String status;
  final String? quantity;

  @override
  List<Object?> get props => [id, title, status, quantity];
}

/// A task the arrival notification covers.
class LocationTask extends Equatable {
  const LocationTask({
    required this.id,
    required this.title,
    required this.status,
    this.quantity,
  });

  final int id;
  final String title;
  final String status;
  final String? quantity;

  @override
  List<Object?> get props => [id, title, status, quantity];
}

/// The server's decision about one arrival.
///
/// `status` is `sent`, `skipped`, `failed` or `queued`; when it is not `sent`,
/// [reasonMessage] explains why — which is the honest half of the feature.
class LocationArrival extends Equatable {
  const LocationArrival({
    required this.id,
    required this.placeId,
    required this.kind,
    required this.status,
    this.placeName,
    this.kindLabel,
    this.reason,
    this.reasonMessage,
    this.title,
    this.body,
    this.taskCount = 0,
    this.tasks = const [],
  });

  final int id;
  final int placeId;
  final String kind;
  final String status;
  final String? placeName;
  final String? kindLabel;
  final String? reason;
  final String? reasonMessage;
  final String? title;
  final String? body;
  final int taskCount;
  final List<LocationTask> tasks;

  bool get isSent => status == 'sent';

  @override
  List<Object?> get props => [
    id,
    placeId,
    kind,
    status,
    placeName,
    kindLabel,
    reason,
    reasonMessage,
    title,
    body,
    taskCount,
    tasks,
  ];
}

/// A place and everything still open there — the screen a notification opens.
class PlaceNeeds extends Equatable {
  const PlaceNeeds({required this.place, required this.requests});

  final Place place;
  final List<NearbyRequest> requests;

  @override
  List<Object?> get props => [place, requests];
}
