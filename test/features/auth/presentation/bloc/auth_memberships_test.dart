import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/session/auth_session.dart';
import 'package:family_essentials_mobile/features/auth/domain/entities/membership.dart';
import 'package:family_essentials_mobile/features/auth/domain/entities/tenant.dart';
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
    emailVerified: true,
    phoneVerified: true,
    activeTenantId: 1,
  );

  const tenantA = Tenant(
    id: 1,
    name: 'Household A',
    slug: 'a',
    status: 'active',
    subscriptionTier: 'pilot',
  );
  const tenantB = Tenant(
    id: 2,
    name: 'Household B',
    slug: 'b',
    status: 'active',
    subscriptionTier: 'pilot',
  );

  setUp(() {
    repository = MockAuthRepository();
    session = AuthSession();
  });

  blocTest<AuthBloc, AuthState>(
    'loads the household memberships after restoring a session',
    build: () {
      when(() => repository.me()).thenAnswer((_) async => user);
      when(() => repository.memberships()).thenAnswer(
        (_) async => const [
          Membership(tenant: tenantA, role: 'tenant_admin', isActive: true),
        ],
      );

      return AuthBloc(repository, session);
    },
    act: (bloc) => bloc.add(const SessionLoaded()),
    expect: () => [
      const AuthLoading(),
      const AuthAuthenticated(user),
      const AuthMembershipsLoaded(user, [
        Membership(tenant: tenantA, role: 'tenant_admin', isActive: true),
      ]),
    ],
    verify: (_) => expect(session.isAuthenticated.value, isTrue),
  );

  blocTest<AuthBloc, AuthState>(
    'switching the active household refreshes the memberships',
    build: () {
      var calls = 0;

      when(() => repository.me()).thenAnswer((_) async => user);
      when(() => repository.switchTenant(2)).thenAnswer((_) async {});
      when(() => repository.memberships()).thenAnswer((_) async {
        calls++;

        return calls == 1
            ? const [
                Membership(
                  tenant: tenantA,
                  role: 'tenant_admin',
                  isActive: true,
                ),
              ]
            : const [
                Membership(tenant: tenantB, role: 'member', isActive: true),
              ];
      });

      return AuthBloc(repository, session);
    },
    act: (bloc) async {
      bloc.add(const SessionLoaded());

      // Wait for the first memberships load to settle before switching, so the
      // emitted states are deterministic.
      await bloc.stream.where((state) => state is AuthMembershipsLoaded).first;

      bloc.add(const TenantSwitchRequested(2));
    },
    expect: () => [
      const AuthLoading(),
      const AuthAuthenticated(user),
      const AuthMembershipsLoaded(user, [
        Membership(tenant: tenantA, role: 'tenant_admin', isActive: true),
      ]),
      const AuthLoading(),
      const AuthMembershipsLoaded(user, [
        Membership(tenant: tenantB, role: 'member', isActive: true),
      ]),
    ],
    verify: (_) => verify(() => repository.switchTenant(2)).called(1),
  );
}
