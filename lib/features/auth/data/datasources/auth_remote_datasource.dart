import 'package:dio/dio.dart';

import '../../../../core/network/dio_client.dart';
import '../models/user_model.dart';

class AuthRemoteDataSource {
  AuthRemoteDataSource(this._client);

  final DioClient _client;

  Dio get _dio => _client.dio;

  Future<AuthResult> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? householdName,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/register',
      data: {
        'name': name,
        'email': email,
        'phone': phone,
        'password': password,
        'password_confirmation': passwordConfirmation,
        if (householdName != null && householdName.isNotEmpty)
          'household_name': householdName,
        'device_name': 'flutter-mobile',
      },
    );

    return AuthResult.fromJson(response.data!);
  }

  Future<AuthResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/login',
      data: {
        'email': email,
        'password': password,
        'device_name': 'flutter-mobile',
      },
    );

    return AuthResult.fromJson(response.data!);
  }

  Future<UserModel> me() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/auth/me');
    final data = (response.data!['data'] as Map).cast<String, dynamic>();

    return UserModel.fromJson(data);
  }

  Future<List<MembershipModel>> memberships() async {
    final response = await _dio.get<Map<String, dynamic>>('/v1/auth/tenants');
    final data = (response.data!['data'] as List).cast<Map<String, dynamic>>();

    return data.map(MembershipModel.fromJson).toList();
  }

  Future<void> switchTenant(int tenantId) =>
      _dio.post<void>('/v1/auth/tenant/switch', data: {'tenant_id': tenantId});

  Future<void> updateVoiceConsent(bool optIn) =>
      _dio.patch<void>('/v1/auth/voice-consent', data: {'voice_opt_in': optIn});

  Future<void> logout() => _dio.post<void>('/v1/auth/logout');

  Future<void> sendPhoneCode() => _dio.post<void>('/v1/auth/phone/send-code');

  Future<UserModel> verifyPhone(String code) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/v1/auth/phone/verify',
      data: {'code': code},
    );

    return UserModel.fromJson(
      (response.data!['user'] as Map).cast<String, dynamic>(),
    );
  }

  Future<void> resendEmailVerification() =>
      _dio.post<void>('/v1/auth/email/resend');

  Future<void> forgotPassword(String email) =>
      _dio.post<void>('/v1/auth/forgot-password', data: {'email': email});
}
