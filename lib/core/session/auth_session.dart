import 'package:flutter/foundation.dart';

/// Holds the in-memory authentication flag used by the router's redirect guard.
class AuthSession {
  final ValueNotifier<bool> isAuthenticated = ValueNotifier<bool>(false);
}
