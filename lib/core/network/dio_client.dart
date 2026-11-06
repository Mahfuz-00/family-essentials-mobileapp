import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';

class DioClient {
  DioClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: const {'Accept': 'application/json'},
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest:
            (RequestOptions options, RequestInterceptorHandler handler) async {
              final customUrl = await _storage.readBaseUrl();
              if (customUrl != null && customUrl.trim().isNotEmpty) {
                options.baseUrl = customUrl.trim();
              }

              final token = await _storage.readToken();

              if (token != null && token.isNotEmpty) {
                options.headers['Authorization'] = 'Bearer $token';
              }

              handler.next(options);
            },
      ),
    );
  }

  final SecureStorage _storage;

  late final Dio dio;
}
