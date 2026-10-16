import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

/// The `/mobile` prefix is already in the base URL, so paths are `/v1/...`.
class FeedbackRemoteDataSource {
  FeedbackRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<Map<String, dynamic>>> reports() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/feedback');

    return (response.data!['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> send(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/feedback',
      data: payload,
    );

    return (response.data!['data'] as Map).cast<String, dynamic>();
  }
}
