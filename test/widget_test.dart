import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/session/auth_session.dart';
import 'package:family_essentials_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_essentials_mobile/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:family_essentials_mobile/features/auth/presentation/pages/login_page.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  testWidgets('login page renders the email and password fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      BlocProvider(
        create: (_) => AuthBloc(MockAuthRepository(), AuthSession()),
        child: const MaterialApp(home: LoginPage()),
      ),
    );

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.byType(TextField), findsNWidgets(2));
    expect(find.text('Sign in'), findsOneWidget);
  });
}
