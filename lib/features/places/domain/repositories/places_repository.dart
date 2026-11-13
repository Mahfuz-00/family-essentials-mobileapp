import '../entities/place.dart';

abstract class PlacesRepository {
  Future<List<Place>> places();

  Future<Place> create({
    required String name,
    required double latitude,
    required double longitude,
    int radiusMeters = 300,
    String? address,
    String? category,
  });

  Future<Place> update(
    int id, {
    String? name,
    double? latitude,
    double? longitude,
    int? radiusMeters,
    String? address,
    String? category,
  });

  Future<void> remove(int id);

  Future<GeofenceEvaluation> reportPosition({
    required double latitude,
    required double longitude,
  });

  /// Everything still open at one saved place — the screen a notification opens.
  Future<PlaceNeeds> placeNeeds(int placeId);
}
