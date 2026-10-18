import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/place.dart';
import '../../domain/repositories/places_repository.dart';
import '../datasources/places_remote_datasource.dart';
import '../models/place_model.dart';

class PlacesRepositoryImpl implements PlacesRepository {
  PlacesRepositoryImpl(this._remote);

  final PlacesRemoteDataSource _remote;

  @override
  Future<List<Place>> places() => _guard(() async {
    return (await _remote.places()).map(PlaceModel.fromJson).toList();
  });

  @override
  Future<Place> create({
    required String name,
    required double latitude,
    required double longitude,
    int radiusMeters = 300,
    String? address,
    String? category,
  }) {
    return _guard(() async {
      final data = await _remote.create({
        'name': name,
        'latitude': latitude,
        'longitude': longitude,
        'radius_meters': radiusMeters,
        'address': address,
        'category': category,
      });

      return PlaceModel.fromJson(data);
    });
  }

  @override
  Future<void> remove(int id) => _guard(() => _remote.remove(id));

  @override
  Future<GeofenceEvaluation> reportPosition({
    required double latitude,
    required double longitude,
  }) {
    return _guard(() async {
      final data = await _remote.reportPosition({
        'latitude': latitude,
        'longitude': longitude,
      });

      return GeofenceEvaluationModel.fromJson(data);
    });
  }

  @override
  Future<PlaceNeeds> placeNeeds(int placeId) {
    return _guard(() async {
      final data = await _remote.placeNeeds(placeId);

      return PlaceNeedsModel.fromJson(data);
    });
  }

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AppFailure(_messageFrom(error));
    }
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }

      if (data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
