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
    this.activeRequestsCount,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? address;
  final String? category;
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
  });

  final List<GeofenceTransitionResult> transitions;
  final List<ShoppingList> shoppingLists;

  @override
  List<Object?> get props => [transitions, shoppingLists];
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
