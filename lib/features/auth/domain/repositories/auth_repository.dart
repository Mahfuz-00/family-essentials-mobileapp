import '../entities/membership.dart';
import '../entities/user.dart';

abstract class AuthRepository {
  Future<User> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String passwordConfirmation,
    String? householdName,
  });

  Future<User> login({required String email, required String password});

  Future<User> me();

  Future<void> updateVoiceConsent(bool optIn);

  Future<void> updateLocationConsent(bool optIn);

  Future<void> updateAlertStyle(String style);

  Future<List<Membership>> memberships();

  Future<void> switchTenant(int tenantId);

  Future<void> logout();

  Future<void> sendPhoneCode();

  Future<User> verifyPhone(String code);

  Future<void> resendEmailVerification();

  Future<void> forgotPassword(String email);
}
