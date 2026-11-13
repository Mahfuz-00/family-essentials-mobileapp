import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _userNameKey = 'auth_user_name';
  static const String _userEmailKey = 'auth_user_email';
  static const String _userAvatarKey = 'auth_user_avatar';
  static const String _activeTierKey = 'household_active_tier';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _baseUrlKey = 'custom_base_url';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> deleteToken() => _storage.delete(key: _tokenKey);

  Future<void> saveUserName(String name) =>
      _storage.write(key: _userNameKey, value: name);

  Future<String?> readUserName() => _storage.read(key: _userNameKey);

  Future<void> saveUserEmail(String email) =>
      _storage.write(key: _userEmailKey, value: email);

  Future<String?> readUserEmail() => _storage.read(key: _userEmailKey);

  Future<void> saveUserAvatar(String avatar) =>
      _storage.write(key: _userAvatarKey, value: avatar);

  Future<String?> readUserAvatar() => _storage.read(key: _userAvatarKey);

  Future<void> saveActiveTier(String tier) =>
      _storage.write(key: _activeTierKey, value: tier);

  Future<String?> readActiveTier() => _storage.read(key: _activeTierKey);

  Future<void> clear() async {
    await _storage.delete(key: _tokenKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userEmailKey);
  }

  Future<bool> hasSeenOnboarding() async {
    final value = await _storage.read(key: _onboardingKey);
    return value == 'true';
  }

  Future<void> setSeenOnboarding(bool seen) =>
      _storage.write(key: _onboardingKey, value: seen ? 'true' : 'false');

  Future<String?> readBaseUrl() => _storage.read(key: _baseUrlKey);

  Future<void> saveBaseUrl(String url) =>
      _storage.write(key: _baseUrlKey, value: url);
}
