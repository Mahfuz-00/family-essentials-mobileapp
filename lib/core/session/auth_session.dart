import 'package:flutter/foundation.dart';

/// Holds in-memory session flags used by the router's redirect guards.
class AuthSession {
  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
  final ValueNotifier<bool> hasSeenOnboarding = ValueNotifier<bool>(false);
}
