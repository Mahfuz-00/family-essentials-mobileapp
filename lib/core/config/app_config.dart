class AppConfig {
  /// Base URL of the Laravel API.
  ///
  /// The mobile app talks to the `/mobile` surface; the web dashboard uses
  /// `/api`. Each mints tokens with a matching ability, so they are not
  /// interchangeable. See `Backend/routes/mobile.php`.
  ///
  /// Override at build time with:
  ///   flutter run --dart-define=API_BASE_URL=http://localhost:8000/mobile
  ///
  /// For physical devices connected via USB, running `adb reverse tcp:8000 tcp:8000`
  /// maps localhost:8000 directly to the host machine.
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:8000/mobile',
  );

  /// Firebase, supplied at build time.
  static const String firebaseApiKey = String.fromEnvironment(
    'FIREBASE_API_KEY',
  );
  static const String firebaseAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String firebaseSenderId = String.fromEnvironment(
    'FIREBASE_SENDER_ID',
  );
  static const String firebaseProjectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );

  static bool get hasFirebase =>
      firebaseApiKey.isNotEmpty &&
      firebaseAppId.isNotEmpty &&
      firebaseSenderId.isNotEmpty &&
      firebaseProjectId.isNotEmpty;
}
