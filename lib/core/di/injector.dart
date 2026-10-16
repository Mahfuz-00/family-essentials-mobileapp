import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/places/data/datasources/places_remote_datasource.dart';
import '../../features/places/data/repositories/places_repository_impl.dart';
import '../../features/places/domain/repositories/places_repository.dart';
import '../../features/places/presentation/bloc/places_bloc.dart';
import '../../features/pantry/data/datasources/pantry_remote_datasource.dart';
import '../../features/pantry/data/repositories/pantry_repository_impl.dart';
import '../../features/pantry/domain/repositories/pantry_repository.dart';
import '../../features/pantry/presentation/bloc/pantry_bloc.dart';
import '../../features/requests/data/datasources/requests_remote_datasource.dart';
import '../../features/requests/data/repositories/requests_repository_impl.dart';
import '../../features/requests/domain/repositories/requests_repository.dart';
import '../../features/requests/presentation/bloc/requests_bloc.dart';
import '../geo/location_provider.dart';
import '../network/dio_client.dart';
import '../notifications/local_notifications.dart';
import '../notifications/notification_planner.dart';
import '../router/app_router.dart';
import '../session/auth_session.dart';
import '../storage/secure_storage.dart';

final GetIt getIt = GetIt.instance;

Future<void> configureDependencies() async {
  getIt
    ..registerLazySingleton<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    )
    ..registerLazySingleton<SecureStorage>(() => SecureStorage(getIt()))
    ..registerLazySingleton<AuthSession>(() => AuthSession())
    ..registerLazySingleton<DioClient>(() => DioClient(getIt()))
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => AuthRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => AuthRepositoryImpl(getIt(), getIt()),
    )
    ..registerLazySingleton<RequestsRemoteDataSource>(
      () => RequestsRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<RequestsRepository>(
      () => RequestsRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<PlacesRemoteDataSource>(
      () => PlacesRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<PlacesRepository>(
      () => PlacesRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<PantryRemoteDataSource>(
      () => PantryRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<PantryRepository>(
      () => PantryRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<LocationProvider>(() => MockLocationProvider())
    ..registerLazySingleton<FlutterLocalNotificationsPlugin>(
      () => FlutterLocalNotificationsPlugin(),
    )
    ..registerLazySingleton<NotificationPlanner>(
      () => const NotificationPlanner(),
    )
    ..registerLazySingleton<LocalNotifications>(
      () => LocalNotifications(getIt(), getIt()),
    )
    ..registerLazySingleton<AppRouter>(() => AppRouter(getIt()))
    ..registerFactory<AuthBloc>(() => AuthBloc(getIt(), getIt()))
    ..registerFactory<RequestsBloc>(() => RequestsBloc(getIt()))
    ..registerFactory<PlacesBloc>(() => PlacesBloc(getIt()))
    ..registerFactory<PantryBloc>(() => PantryBloc(getIt()));
}
