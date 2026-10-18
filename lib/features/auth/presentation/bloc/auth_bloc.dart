import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../../../core/session/auth_session.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc(this._repository, this._session) : super(const AuthInitial()) {
    on<LoginRequested>(_onLogin);
    on<RegisterRequested>(_onRegister);
    on<SessionLoaded>(_onSessionLoaded);
    on<MembershipsRequested>(_onMembershipsRequested);
    on<TenantSwitchRequested>(_onTenantSwitch);
    on<VoiceConsentChanged>(_onVoiceConsentChanged);
    on<LocationConsentChanged>(_onLocationConsentChanged);
    on<PhoneCodeRequested>(_onPhoneCode);
    on<PhoneVerifyRequested>(_onPhoneVerify);
    on<LogoutRequested>(_onLogout);
  }

  final AuthRepository _repository;
  final AuthSession _session;

  User? _user;

  Future<void> _onLogin(LoginRequested event, Emitter<AuthState> emit) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.login(
        email: event.email,
        password: event.password,
      );
      _user = user;
      _session.isAuthenticated.value = true;
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onRegister(
    RegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.register(
        name: event.name,
        email: event.email,
        phone: event.phone,
        password: event.password,
        passwordConfirmation: event.passwordConfirmation,
      );

      _user = user;
      _session.isAuthenticated.value = true;
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onSessionLoaded(
    SessionLoaded event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.me();
      _user = user;
      _session.isAuthenticated.value = true;
      emit(AuthAuthenticated(user));
      await _emitMemberships(emit, user);
    } on AuthFailure {
      _session.isAuthenticated.value = false;
      emit(const AuthUnauthenticated());
    }
  }

  Future<void> _onMembershipsRequested(
    MembershipsRequested event,
    Emitter<AuthState> emit,
  ) async {
    final user = _user;

    if (user == null) {
      return;
    }

    await _emitMemberships(emit, user);
  }

  Future<void> _onTenantSwitch(
    TenantSwitchRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _repository.switchTenant(event.tenantId);
      final user = await _repository.me();
      _user = user;
      await _emitMemberships(emit, user);
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onVoiceConsentChanged(
    VoiceConsentChanged event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _repository.updateVoiceConsent(event.optIn);

      final user = await _repository.me();
      _user = user;
      await _emitMemberships(emit, user);
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onLocationConsentChanged(
    LocationConsentChanged event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _repository.updateLocationConsent(event.optIn);

      final user = await _repository.me();
      _user = user;
      await _emitMemberships(emit, user);
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onPhoneCode(
    PhoneCodeRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      await _repository.sendPhoneCode();
      emit(const AuthCodeSent());
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onPhoneVerify(
    PhoneVerifyRequested event,
    Emitter<AuthState> emit,
  ) async {
    emit(const AuthLoading());

    try {
      final user = await _repository.verifyPhone(event.code);
      _user = user;
      emit(AuthAuthenticated(user));
    } on AuthFailure catch (failure) {
      emit(AuthFailureState(failure.message));
    }
  }

  Future<void> _onLogout(LogoutRequested event, Emitter<AuthState> emit) async {
    try {
      await _repository.logout();
    } on AuthFailure {
      // Ignore network errors on logout; the local session is cleared regardless.
    }

    _user = null;
    _session.isAuthenticated.value = false;
    emit(const AuthUnauthenticated());
  }

  Future<void> _emitMemberships(Emitter<AuthState> emit, User user) async {
    try {
      final memberships = await _repository.memberships();
      emit(AuthMembershipsLoaded(user, memberships));
    } on AuthFailure {
      emit(AuthAuthenticated(user));
    }
  }
}
