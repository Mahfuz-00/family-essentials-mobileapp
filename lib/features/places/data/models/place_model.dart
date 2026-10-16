import '../../domain/entities/place.dart';

class PlaceModel extends Place {
  const PlaceModel({
    required super.id,
    required super.name,
    required super.latitude,
    required super.longitude,
    required super.radiusMeters,
    super.address,
    super.category,
    super.activeRequestsCount,
  });

  factory PlaceModel.fromJson(Map<String, dynamic> json) {
    return PlaceModel(
      id: json['id'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radius_meters'] as num).toInt(),
      address: json['address'] as String?,
      category: json['category'] as String?,
      activeRequestsCount: json['active_requests_count'] as int?,
    );
  }
}

class GeofenceEvaluationModel extends GeofenceEvaluation {
  const GeofenceEvaluationModel({
    required super.transitions,
    required super.shoppingLists,
  });

  factory GeofenceEvaluationModel.fromJson(Map<String, dynamic> json) {
    return GeofenceEvaluationModel(
      transitions: (json['transitions'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (item) => GeofenceTransitionResult(
              placeId: item['place_id'] as int,
              entered: item['event'] == 'enter',
              distanceMeters: (item['distance_meters'] as num).toDouble(),
            ),
          )
          .toList(),
      shoppingLists: (json['shopping_lists'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (item) => ShoppingList(
              place: PlaceModel.fromJson(
                (item['place'] as Map).cast<String, dynamic>(),
              ),
              requests: (item['requests'] as List? ?? const [])
                  .cast<Map<String, dynamic>>()
                  .map(
                    (request) => NearbyRequest(
                      id: request['id'] as int,
                      title: request['title'] as String,
                      status: request['status'] as String,
                      quantity: request['quantity'] as String?,
                    ),
                  )
                  .toList(),
            ),
          )
          .toList(),
    );
  }
}
