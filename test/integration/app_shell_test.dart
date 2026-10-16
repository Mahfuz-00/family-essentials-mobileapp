import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/error/failures.dart';
import 'package:family_essentials_mobile/core/router/main_shell.dart';
import 'package:family_essentials_mobile/core/session/auth_session.dart';
import 'package:family_essentials_mobile/core/theme/app_theme.dart';
import 'package:family_essentials_mobile/features/auth/domain/repositories/auth_repository.dart';
import 'package:family_essentials_mobile/features/auth/presentation/bloc/auth_bloc.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

/// Integration scope: the real shell, real bloc and real bottom navigation.
void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();

    // The shell kicks off SessionLoaded; no session is needed to render tabs.
    when(
      () => repository.me(),
    ).thenAnswer((_) async => throw const AuthFailure('no session'));
  });

  Widget harness(String location) {
    return BlocProvider<AuthBloc>(
      create: (_) => AuthBloc(repository, AuthSession()),
      child: MaterialApp(
        theme: AppTheme.light,
        home: MainShell(location: location, child: const SizedBox.shrink()),
      ),
    );
  }

  testWidgets('offers the four household tabs', (tester) async {
    await tester.pumpWidget(harness('/today'));

    for (final destination in MainShell.destinations) {
      expect(find.text(destination.label), findsWidgets);
    }
  });

  testWidgets('highlights Today by default', (tester) async {
    await tester.pumpWidget(harness('/today'));

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 0);
  });

  testWidgets('keeps the shopping tab lit for the pantry sub-screen', (
    tester,
  ) async {
    await tester.pumpWidget(harness('/pantry'));

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(
      bar.selectedIndex,
      1,
      reason: 'pantry belongs to the shopping section',
    );
  });

  testWidgets('lights the matching tab for a nested places route', (
    tester,
  ) async {
    await tester.pumpWidget(harness('/places/42'));

    final bar = tester.widget<NavigationBar>(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });
}
