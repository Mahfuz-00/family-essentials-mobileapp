import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._storage);

  final AuthRemoteDataSource _remote;
  final SecureStorage _storage;

  @override
  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? householdName,
  }) {
    return _guard(() async {
      final result = await _remote.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        householdName: householdName,
      );

      await _storage.saveToken(result.token);

      return result.user;
    });
  }

  @override
  Future<User> login({required String email, required String password}) {
    return _guard(() async {
      final result = await _remote.login(email: email, password: password);
      await _storage.saveToken(result.token);

      return result.user;
    });
  }

  @override
  Future<User> me() => _guard(_remote.me);

  @override
  Future<List<Membership>> memberships() => _guard(_remote.memberships);

  @override
  Future<void> switchTenant(int tenantId) =>
      _guard(() => _remote.switchTenant(tenantId));

  @override
  Future<void> updateVoiceConsent(bool optIn) =>
      _guard(() => _remote.updateVoiceConsent(optIn));

  @override
  Future<void> updateLocationConsent(bool optIn) =>
      _guard(() => _remote.updateLocationConsent(optIn));

  @override
  Future<void> updateAlertStyle(String style) =>
      _guard(() => _remote.updateAlertStyle(style));

  @override
  Future<void> logout() {
    return _guard(() async {
      await _remote.logout();
      await _storage.clear();
    });
  }

  @override
  Future<void> sendPhoneCode() => _guard(_remote.sendPhoneCode);

  @override
  Future<User> verifyPhone(String code) =>
      _guard(() => _remote.verifyPhone(code));

  @override
  Future<void> resendEmailVerification() =>
      _guard(_remote.resendEmailVerification);

  @override
  Future<void> forgotPassword(String email) =>
      _guard(() => _remote.forgotPassword(email));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AuthFailure(
        _messageFrom(error),
        // Only a 401 means the session is over; a timeout means try again.
        unauthorized: error.response?.statusCode == 401,
      );
    }
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }

      if (data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
