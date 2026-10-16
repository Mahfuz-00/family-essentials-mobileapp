import 'package:equatable/equatable.dart';

import '../../domain/entities/membership.dart';
import '../../domain/entities/user.dart';

sealed class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthAuthenticated extends AuthState {
  const AuthAuthenticated(this.user);

  final User user;

  @override
  List<Object?> get props => [user];
}

class AuthMembershipsLoaded extends AuthState {
  const AuthMembershipsLoaded(this.user, this.memberships);

  final User user;
  final List<Membership> memberships;

  Membership? get activeMembership {
    for (final membership in memberships) {
      if (membership.isActive) {
        return membership;
      }
    }

    return memberships.isEmpty ? null : memberships.first;
  }

  @override
  List<Object?> get props => [user, memberships];
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthCodeSent extends AuthState {
  const AuthCodeSent();
}

class AuthFailureState extends AuthState {
  const AuthFailureState(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
