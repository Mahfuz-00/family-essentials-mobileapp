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
    super.kind,
    super.kindLabel,
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
      kind: json['kind'] as String?,
      kindLabel: json['kind_label'] as String?,
      activeRequestsCount: json['active_requests_count'] as int?,
    );
  }
}

class GeofenceEvaluationModel extends GeofenceEvaluation {
  const GeofenceEvaluationModel({
    required super.transitions,
    required super.shoppingLists,
    super.arrivals,
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
              requests: _requests(item['requests']),
            ),
          )
          .toList(),
      arrivals: (json['location_notifications'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(LocationArrivalModel.fromJson)
          .toList(),
    );
  }

  static List<NearbyRequest> _requests(Object? raw) {
    return (raw as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(
          (request) => NearbyRequest(
            id: request['id'] as int,
            title: request['title'] as String,
            status: request['status'] as String,
            quantity: request['quantity'] as String?,
          ),
        )
        .toList();
  }
}

class LocationArrivalModel extends LocationArrival {
  const LocationArrivalModel({
    required super.id,
    required super.placeId,
    required super.kind,
    required super.status,
    super.placeName,
    super.kindLabel,
    super.reason,
    super.reasonMessage,
    super.title,
    super.body,
    super.taskCount,
    super.tasks,
  });

  factory LocationArrivalModel.fromJson(Map<String, dynamic> json) {
    return LocationArrivalModel(
      id: json['id'] as int,
      placeId: json['place_id'] as int,
      kind: json['kind'] as String? ?? 'other',
      status: json['status'] as String? ?? 'skipped',
      placeName: json['place_name'] as String?,
      kindLabel: json['kind_label'] as String?,
      reason: json['reason'] as String?,
      reasonMessage: json['reason_message'] as String?,
      title: json['title'] as String?,
      body: json['body'] as String?,
      taskCount: json['task_count'] as int? ?? 0,
      tasks: (json['tasks'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (task) => LocationTask(
              id: task['id'] as int,
              title: task['title'] as String,
              status: task['status'] as String,
              quantity: task['quantity'] as String?,
            ),
          )
          .toList(),
    );
  }
}

class PlaceNeedsModel extends PlaceNeeds {
  const PlaceNeedsModel({required super.place, required super.requests});

  factory PlaceNeedsModel.fromJson(Map<String, dynamic> json) {
    return PlaceNeedsModel(
      place: PlaceModel.fromJson(
        (json['place'] as Map).cast<String, dynamic>(),
      ),
      requests: GeofenceEvaluationModel._requests(json['data']),
    );
  }
}
