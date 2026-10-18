import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class PlacesRemoteDataSource {
  PlacesRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<Map<String, dynamic>>> places() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/places');

    return (response.data!['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/places',
      data: payload,
    );

    return (response.data!['data'] as Map).cast<String, dynamic>();
  }

  Future<void> remove(int id) => _dio.delete<void>('/v1/places/$id');

  Future<Map<String, dynamic>> reportPosition(
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/geofences/evaluate',
      data: payload,
    );

    return response.data!;
  }

  /// The open work at one place — what a notification tap opens.
  Future<Map<String, dynamic>> placeNeeds(int id) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/places/$id/requests',
    );

    return response.data!;
  }
}
