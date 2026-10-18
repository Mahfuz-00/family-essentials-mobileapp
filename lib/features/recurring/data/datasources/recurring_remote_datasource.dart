import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class RecurringRemoteDataSource {
  RecurringRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<Map<String, dynamic>>> rules() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/recurring-rules',
    );

    return (response.data!['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/recurring-rules',
      data: payload,
    );

    return (response.data!['data'] as Map).cast<String, dynamic>();
  }

  /// Partial update. `{ 'active': false }` pauses without deleting.
  Future<Map<String, dynamic>> update(
    int id,
    Map<String, dynamic> payload,
  ) async {
    final response = await _dio.patch<Map<String, dynamic>>(
      '/v1/recurring-rules/$id',
      data: payload,
    );

    return (response.data!['data'] as Map).cast<String, dynamic>();
  }

  Future<void> remove(int id) => _dio.delete<void>('/v1/recurring-rules/$id');
}
