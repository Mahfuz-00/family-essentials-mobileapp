import 'package:equatable/equatable.dart';

class User extends Equatable {
  const User({
    required this.id,
    required this.name,
    required this.email,
    required this.emailVerified,
    required this.phoneVerified,
    this.phone,
    this.isPlatformAdmin = false,
    this.voiceOptIn = false,
    this.locationNotificationsOptIn = false,
    this.alertStyle = 'sound',
    this.activeTenantId,
  });

  final int id;
  final String name;
  final String email;
  final String? phone;
  final bool emailVerified;
  final bool phoneVerified;
  final bool isPlatformAdmin;
  final bool voiceOptIn;

  /// Opt-in, server-stored: arrival notifications are off until asked for.
  final bool locationNotificationsOptIn;

  /// silent | vibrate | sound | voice — the server uses this to pick the channel.
  final String alertStyle;

  final int? activeTenantId;

  @override
  List<Object?> get props => [
    id,
    name,
    email,
    phone,
    emailVerified,
    phoneVerified,
    isPlatformAdmin,
    voiceOptIn,
    locationNotificationsOptIn,
    alertStyle,
    activeTenantId,
  ];
}
