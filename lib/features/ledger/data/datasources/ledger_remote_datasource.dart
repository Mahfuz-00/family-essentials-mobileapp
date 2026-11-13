import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

class LedgerRemoteDataSource {
  LedgerRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<Map<String, dynamic>>> getLedgers() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/ledgers');
    final data = response.data?['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> getSummary(int ledgerId, {String periodType = 'monthly'}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/ledgers/$ledgerId/summary',
      queryParameters: {'period_type': periodType},
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> getEntries(
    int ledgerId, {
    String? from,
    String? to,
  }) async {
    final queryParams = <String, dynamic>{
      if (from != null && from.isNotEmpty) 'from': from,
      if (to != null && to.isNotEmpty) 'to': to,
    };
    final response = await _dio.get<Map<String, dynamic>>(
      '/v1/ledgers/$ledgerId/entries',
      queryParameters: queryParams.isEmpty ? null : queryParams,
    );
    final data = response.data?['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createLedger(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/ledgers', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateLedger(int ledgerId, Map<String, dynamic> payload) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/ledgers/$ledgerId', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> addEntry(int ledgerId, Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/ledgers/$ledgerId/entries',
      data: payload,
    );
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }
}
