import 'package:equatable/equatable.dart';

sealed class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class LoginRequested extends AuthEvent {
  const LoginRequested({required this.email, required this.password});

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class RegisterRequested extends AuthEvent {
  const RegisterRequested({
    required this.name,
    required this.email,
    required this.phone,
    required this.password,
    required this.passwordConfirmation,
  });

  final String name;
  final String email;
  final String phone;
  final String password;
  final String passwordConfirmation;

  @override
  List<Object?> get props => [
    name,
    email,
    phone,
    password,
    passwordConfirmation,
  ];
}

class SessionLoaded extends AuthEvent {
  const SessionLoaded();
}

class MembershipsRequested extends AuthEvent {
  const MembershipsRequested();
}

class TenantSwitchRequested extends AuthEvent {
  const TenantSwitchRequested(this.tenantId);

  final int tenantId;

  @override
  List<Object?> get props => [tenantId];
}

class VoiceConsentChanged extends AuthEvent {
  const VoiceConsentChanged(this.optIn);

  final bool optIn;

  @override
  List<Object?> get props => [optIn];
}

class PhoneCodeRequested extends AuthEvent {
  const PhoneCodeRequested();
}

class PhoneVerifyRequested extends AuthEvent {
  const PhoneVerifyRequested(this.code);

  final String code;

  @override
  List<Object?> get props => [code];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}
