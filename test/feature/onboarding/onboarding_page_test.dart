import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/di/injector.dart';
import 'package:family_essentials_mobile/core/session/auth_session.dart';
import 'package:family_essentials_mobile/core/storage/secure_storage.dart';
import 'package:family_essentials_mobile/features/onboarding/presentation/pages/onboarding_page.dart';

class MockSecureStorage extends Mock implements SecureStorage {}

void main() {
  setUp(() {
    getIt.reset();
    final mockStorage = MockSecureStorage();
    when(() => mockStorage.setSeenOnboarding(true))
        .thenAnswer((_) async {});
    getIt.registerLazySingleton<SecureStorage>(() => mockStorage);
    getIt.registerLazySingleton<AuthSession>(() => AuthSession());
  });

  tearDown(() {
    getIt.reset();
  });

  testWidgets('onboarding page renders initial slide and navigates', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: OnboardingPage(),
      ),
    );

    // First slide content
    expect(find.text('ACCOUNTABILITY'), findsOneWidget);
    expect(find.text('One Task, One Owner'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    // Tap continue to go to second slide (OpenStreetMap)
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('OPENSTREETMAP GEOFENCING'), findsOneWidget);
    expect(find.text('Store Arrival Triggers'), findsOneWidget);
  });
}
