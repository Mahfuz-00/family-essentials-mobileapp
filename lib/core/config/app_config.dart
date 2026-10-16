class AppConfig {
  /// Base URL of the Laravel API.
  ///
  /// The mobile app talks to the `/mobile` surface; the web dashboard uses
  /// `/api`. Each mints tokens with a matching ability, so they are not
  /// interchangeable. See `Backend/routes/mobile.php`.
  ///
  /// Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=http://192.168.1.20:8000/mobile
  ///
  /// 10.0.2.2 is the Android emulator's alias for the host machine's localhost.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000/mobile',
  );
}
