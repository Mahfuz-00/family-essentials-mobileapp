class AuthFailure implements Exception {
  const AuthFailure(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Generic failure for feature repositories outside authentication.
class AppFailure implements Exception {
  const AppFailure(this.message);

  final String message;

  @override
  String toString() => message;
}
