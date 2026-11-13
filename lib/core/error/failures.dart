import 'package:dio/dio.dart';

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

/// Extracts a clear, human-readable error message from API, network, or runtime errors.
String extractErrorMessage(
  Object error, {
  String fallback = 'Unable to complete the request. Please try again.',
}) {
  if (error is AuthFailure) return error.message;
  if (error is AppFailure) return error.message;

  if (error is DioException) {
    final data = error.response?.data;

    if (data is Map) {
      final errors = data['errors'];
      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;
        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
        if (first is String && first.trim().isNotEmpty) {
          return first.trim();
        }
      }

      final msg = data['message'];
      if (msg is String &&
          msg.trim().isNotEmpty &&
          msg.trim().toLowerCase() != 'server error') {
        return msg.trim();
      }

      final errStr = data['error'];
      if (errStr is String && errStr.trim().isNotEmpty) {
        return errStr.trim();
      }
    } else if (data is String && data.trim().isNotEmpty) {
      final trimmed = data.trim();
      if (!trimmed.startsWith('<')) {
        return trimmed;
      }
    }

    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timed out. Please check your network and try again.';
      case DioExceptionType.connectionError:
        return 'Unable to reach the household server. Using offline mode or check your connection.';
      case DioExceptionType.cancel:
        return 'Request was cancelled.';
      case DioExceptionType.badCertificate:
        return 'Security certificate error while connecting to server.';
      case DioExceptionType.badResponse:
      case DioExceptionType.unknown:
      default:
        final status = error.response?.statusCode;
        if (status == 401) {
          return 'Invalid credentials or your session has expired. Please sign in again.';
        }
        if (status == 403) {
          return 'You do not have permission for this household action.';
        }
        if (status == 404) {
          return 'Requested household resource was not found (404).';
        }
        if (status == 422) {
          return 'Please review the highlighted fields and try again.';
        }
        if (status == 429) {
          return 'Plan quota or rate limit reached. Upgrade your plan or try again shortly.';
        }
        if (status != null && status >= 500) {
          return 'The household server encountered an internal error ($status). Please try again.';
        }
        break;
    }
  }

  return fallback;
}

