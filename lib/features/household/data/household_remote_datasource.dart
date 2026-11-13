import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';

/// Household roster, role catalogue and invitations — the tenant-admin surface
/// that mirrors the web dashboard's People modules.
class HouseholdRemoteDataSource {
  HouseholdRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<List<Map<String, dynamic>>> members() async {
    final response = await _dio.get<dynamic>('/v1/tenant/members');

    return _list(response.data);
  }

  Future<Map<String, dynamic>> roleCatalogue() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/tenant/roles');

    return response.data ?? const {};
  }

  Future<List<Map<String, dynamic>>> invitations() async {
    final response = await _dio.get<dynamic>('/v1/tenant/invitations');

    return _list(response.data);
  }

  Future<void> updateRole(int userId, String role) {
    return _dio.patch<void>(
      '/v1/tenant/members/$userId',
      data: {'role': role},
    );
  }

  Future<void> removeMember(int userId) {
    return _dio.delete<void>('/v1/tenant/members/$userId');
  }

  Future<void> invite(String email, String role) {
    return _dio.post<void>(
      '/v1/tenant/invitations',
      data: {'email': email, 'role': role},
    );
  }

  Future<void> revokeInvitation(int invitationId) {
    return _dio.delete<void>('/v1/tenant/invitations/$invitationId');
  }

  List<Map<String, dynamic>> _list(dynamic payload) {
    final data = payload is Map ? payload['data'] : payload;

    return (data as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}
