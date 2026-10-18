class AuthFailure implements Exception {
  const AuthFailure(this.message, {this.unauthorized = false});

  final String message;

  /// True only when the API rejected the token (401). A failure that is merely
  /// "the request did not get through" must not sign the member out.
  final bool unauthorized;

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
