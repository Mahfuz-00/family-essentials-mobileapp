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
    activeTenantId,
  ];
}
