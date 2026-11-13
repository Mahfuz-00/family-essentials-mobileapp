import 'package:dio/dio.dart';

import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import 'demo_mock_interceptor.dart';

class DioClient {
  DioClient(this._storage) {
    dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        headers: const {'Accept': 'application/json'},
        connectTimeout: const Duration(milliseconds: 2500),
        receiveTimeout: const Duration(milliseconds: 3000),
      ),
    );

    dio.interceptors.add(DemoMockInterceptor());

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
