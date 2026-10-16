import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/error/failures.dart';
import 'package:family_essentials_mobile/core/session/auth_session.dart';
import 'package:family_essentials_mobile/features/auth/domain/entities/user.dart';
import 'package:family_essentials_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_essentials_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:family_essentials_mobile/features/auth/presentation/bloc/auth_event.dart';
import 'package:family_essentials_mobile/features/auth/presentation/bloc/auth_state.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late MockAuthRepository repository;
  late AuthSession session;

  const user = User(
    id: 1,
    name: 'Tanvir Rahman',
    email: 'tanvir@example.com',
    phone: '+15550001111',
    emailVerified: false,
    phoneVerified: false,
  );

  setUp(() {
    repository = MockAuthRepository();
    session = AuthSession();
  });

  blocTest<AuthBloc, AuthState>(
    'login success emits loading then authenticated and marks the session',
    build: () {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenAnswer((_) async => user);

      return AuthBloc(repository, session);
    },
    act: (bloc) => bloc.add(
      const LoginRequested(
        email: 'tanvir@example.com',
        password: 'Password!2345',
      ),
    ),
    expect: () => [const AuthLoading(), const AuthAuthenticated(user)],
    verify: (_) => expect(session.isAuthenticated.value, isTrue),
  );

  blocTest<AuthBloc, AuthState>(
    'login failure emits loading then a failure state',
    build: () {
      when(
        () => repository.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      ).thenThrow(const AuthFailure('Invalid credentials'));

      return AuthBloc(repository, session);
    },
    act: (bloc) => bloc.add(
      const LoginRequested(email: 'x@example.com', password: 'nope'),
    ),
    expect: () => [
      const AuthLoading(),
      const AuthFailureState('Invalid credentials'),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'logout clears the session',
    build: () {
      when(() => repository.logout()).thenAnswer((_) async {});

      return AuthBloc(repository, session);
    },
    act: (bloc) => bloc.add(const LogoutRequested()),
    expect: () => [const AuthUnauthenticated()],
    verify: (_) => expect(session.isAuthenticated.value, isFalse),
  );
}
