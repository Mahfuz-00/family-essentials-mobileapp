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
    name: 'Sarah Rahman',
    email: 'sarah@example.com',
    emailVerified: true,
    phoneVerified: true,
    voiceOptIn: true,
    activeTenantId: 1,
  );

  const tenant = Tenant(
    id: 1,
    name: 'Household A',
    slug: 'a',
    status: 'active',
    subscriptionTier: 'pilot',
  );
  const membership = Membership(tenant: tenant, role: 'member', isActive: true);

  setUp(() {
    repository = MockAuthRepository();
    session = AuthSession();
  });

  blocTest<AuthBloc, AuthState>(
    'changing voice consent refreshes the profile',
    build: () {
      when(() => repository.updateVoiceConsent(true)).thenAnswer((_) async {});
      when(() => repository.me()).thenAnswer((_) async => user);
      when(
        () => repository.memberships(),
      ).thenAnswer((_) async => const [membership]);

      return AuthBloc(repository, session);
    },
    act: (bloc) => bloc.add(const VoiceConsentChanged(true)),
    expect: () => [
      const AuthLoading(),
      const AuthMembershipsLoaded(user, [membership]),
    ],
    verify: (_) => verify(() => repository.updateVoiceConsent(true)).called(1),
  );
}
