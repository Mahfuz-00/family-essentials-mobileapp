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

  /// Firebase, supplied at build time.
  ///
  /// Deliberately passed as options rather than a `google-services.json`, so the
  /// app still builds and runs without a Firebase project: when these are empty
  /// the app skips push registration and relies on local notifications only.
  ///
  ///   flutter run --dart-define=FIREBASE_API_KEY=... \
  ///               --dart-define=FIREBASE_APP_ID=... \
  ///               --dart-define=FIREBASE_SENDER_ID=... \
  ///               --dart-define=FIREBASE_PROJECT_ID=...
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
