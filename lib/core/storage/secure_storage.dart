import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStorage {
  SecureStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const String _tokenKey = 'auth_token';
  static const String _onboardingKey = 'has_seen_onboarding';
  static const String _baseUrlKey = 'custom_base_url';

  Future<void> saveToken(String token) =>
      _storage.write(key: _tokenKey, value: token);

  Future<String?> readToken() => _storage.read(key: _tokenKey);

  Future<void> clear() => _storage.delete(key: _tokenKey);

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
