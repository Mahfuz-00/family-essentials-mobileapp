import 'package:dio/dio.dart';

import '../network/dio_client.dart';

/// Registers this device so the server has somewhere to deliver a push.
class DeviceTokenApi {
  DeviceTokenApi(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<void> register({required String token, required String platform}) =>
      _dio.post<void>(
        '/v1/device-tokens',
        data: {'token': token, 'platform': platform},
      );

  Future<void> remove(String token) async {
    // The route is keyed by id and needs the id, which the client does not keep;
    // a stale token is harmless (the push provider rejects it) so logout only
    // needs to stop using it. Nothing to call for now.
  }
}
