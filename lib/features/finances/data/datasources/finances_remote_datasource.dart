import 'package:dio/dio.dart';
import '../../../../core/network/dio_client.dart';

class FinancesRemoteDataSource {
  FinancesRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<Map<String, dynamic>> getOverview() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/finances/overview');
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<List<Map<String, dynamic>>> getGoals() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/finances/goals');
    final data = response.data?['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createGoal(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/finances/goals', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateGoal(int id, Map<String, dynamic> payload) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/finances/goals/$id', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> deleteGoal(int id) async {
    await _dio.delete('/v1/finances/goals/$id');
  }

  Future<List<Map<String, dynamic>>> getLiabilities() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/finances/liabilities');
    final data = response.data?['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createLiability(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/finances/liabilities', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateLiability(int id, Map<String, dynamic> payload) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/finances/liabilities/$id', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> deleteLiability(int id) async {
    await _dio.delete('/v1/finances/liabilities/$id');
  }

  Future<List<Map<String, dynamic>>> getAssets() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/finances/assets');
    final data = response.data?['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createAsset(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/finances/assets', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateAsset(int id, Map<String, dynamic> payload) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/finances/assets/$id', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> deleteAsset(int id) async {
    await _dio.delete('/v1/finances/assets/$id');
  }

  Future<List<Map<String, dynamic>>> getTaxes() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/finances/taxes');
    final data = response.data?['data'] as List? ?? [];
    return data.map((e) => Map<String, dynamic>.from(e as Map)).toList();
  }

  Future<Map<String, dynamic>> createTax(Map<String, dynamic> payload) async {
    final response = await _dio.post<Map<String, dynamic>>('/v1/finances/taxes', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<Map<String, dynamic>> updateTax(int id, Map<String, dynamic> payload) async {
    final response = await _dio.patch<Map<String, dynamic>>('/v1/finances/taxes/$id', data: payload);
    return response.data?['data'] as Map<String, dynamic>? ?? {};
  }

  Future<void> deleteTax(int id) async {
    await _dio.delete('/v1/finances/taxes/$id');
  }
}
