import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class PantryRemoteDataSource {
  PantryRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> snapshot({bool dueOnly = false}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/essentials',
      queryParameters: dueOnly ? {'due_only': 1} : null,
    );

    return response.data!;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/essentials',
      data: payload,
    );

    return (response.data!['data'] as Map).cast<String, dynamic>();
  }

  Future<Map<String, dynamic>> restock(int id, int quantity) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/essentials/$id/restock',
      data: {'quantity': quantity},
    );

    return (response.data!['data'] as Map).cast<String, dynamic>();
  }

  Future<void> remove(int id) => _dio.delete<void>('/v1/essentials/$id');
}
