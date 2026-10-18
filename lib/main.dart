import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/di/injector.dart';
import 'core/notifications/local_notifications.dart';
import 'core/notifications/push_service.dart';
import 'core/router/app_router.dart';
import 'core/session/auth_session.dart';
import 'core/storage/secure_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await configureDependencies();

  final SecureStorage storage = getIt<SecureStorage>();
  final AuthSession session = getIt<AuthSession>();
  final token = await storage.readToken();

  session.isAuthenticated.value = token != null && token.isNotEmpty;

  // A tapped arrival opens the place it was about, on the existing Today route.
  final router = getIt<AppRouter>().router;
  getIt<LocalNotifications>().onArrivalTapped = (placeId) =>
      router.go('/today?place_id=$placeId');

  // Registers this device when Firebase options were supplied at build time;
  // otherwise it is a no-op and local notifications still work.
  unawaited(getIt<PushService>().start());

  runApp(const FamilyEssentialsApp());
}

class FamilyEssentialsApp extends StatelessWidget {
  const FamilyEssentialsApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>(
      create: (_) => getIt<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Family Essentials',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: getIt<AppRouter>().router,
      ),
    );
  }
}
