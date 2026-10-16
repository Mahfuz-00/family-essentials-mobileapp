import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class RequestsRemoteDataSource {
  RequestsRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> board() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/requests/board');

    return response.data!;
  }

  Future<List<Map<String, dynamic>>> members() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/tenant/members');

    return (response.data!['data'] as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> find(int id) async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/requests/$id');

    return response.data!;
  }

  Future<Map<String, dynamic>> create(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/requests',
      data: payload,
    );

    return response.data!;
  }

  Future<void> act(int id, String action, {Map<String, dynamic>? payload}) =>
      _dio.post<void>('/v1/requests/$id/$action', data: payload ?? const {});

  Future<void> triggerVoiceCall(int requestId) =>
      _dio.post<void>('/v1/requests/$requestId/voice-escalation');
}
