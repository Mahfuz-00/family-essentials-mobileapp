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
    String? currency,
    int? monthlyBudgetMinor,
    int? yearlyBudgetMinor,
  }) {
    return _guard(() async {
      final result = await _remote.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
        passwordConfirmation: passwordConfirmation,
        householdName: householdName,
        currency: currency,
        monthlyBudgetMinor: monthlyBudgetMinor,
        yearlyBudgetMinor: yearlyBudgetMinor,
      );

      await _storage.saveToken(result.token);
      await _storage.saveUserName(result.user.name);
      await _storage.saveUserEmail(result.user.email);

      return result.user;
    });
  }

  @override
  Future<User> login({required String email, required String password}) {
    return _guard(() async {
      final result = await _remote.login(email: email, password: password);
      await _storage.saveToken(result.token);
      await _storage.saveUserName(result.user.name);
      await _storage.saveUserEmail(result.user.email);

      return result.user;
    });
  }

  @override
  Future<User> me() async {
    try {
      final user = await _remote.me();
      await _storage.saveUserName(user.name);
      await _storage.saveUserEmail(user.email);
      return user;
    } on DioException catch (error) {
      if (error.response?.statusCode != 401) {
        final cachedName = await _storage.readUserName();
        final cachedEmail = await _storage.readUserEmail();
        if (cachedName != null && cachedName.trim().isNotEmpty) {
          return User(
            id: 1,
            name: cachedName,
            email: cachedEmail ?? 'tanvir@familyessentials.app',
            emailVerified: true,
            phoneVerified: true,
            voiceOptIn: true,
            locationNotificationsOptIn: true,
            alertStyle: 'sound',
            activeTenantId: 1,
          );
        }
      }
      throw AuthFailure(
        extractErrorMessage(error),
        unauthorized: error.response?.statusCode == 401,
      );
    } catch (error) {
      throw AuthFailure(extractErrorMessage(error));
    }
  }

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
        extractErrorMessage(error),
        // Only a 401 means the session is over; a timeout means try again.
        unauthorized: error.response?.statusCode == 401,
      );
    } catch (error) {
      throw AuthFailure(extractErrorMessage(error));
    }
  }
}
