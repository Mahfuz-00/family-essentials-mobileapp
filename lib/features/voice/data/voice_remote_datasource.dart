import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

/// Voice escalation quota and call history for the signed-in member.
class VoiceRemoteDataSource {
  VoiceRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> quota() async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/voice-calls/quota',
    );

    return response.data ?? const {};
  }

  Future<List<Map<String, dynamic>>> calls() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/voice-calls');
    final data = response.data?['data'];

    return (data as List? ?? const [])
        .whereType<Map>()
        .map((call) => call.cast<String, dynamic>())
        .toList();
  }
}
