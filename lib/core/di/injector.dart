import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:get_it/get_it.dart';

import '../../features/auth/data/datasources/auth_remote_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/feedback/data/datasources/feedback_remote_datasource.dart';
import '../../features/feedback/data/repositories/feedback_repository_impl.dart';
import '../../features/feedback/domain/repositories/feedback_repository.dart';
import '../../features/feedback/presentation/bloc/feedback_bloc.dart';
import '../../features/places/data/datasources/places_remote_datasource.dart';
import '../../features/places/data/repositories/places_repository_impl.dart';
import '../../features/places/domain/repositories/places_repository.dart';
import '../../features/places/location_arrival_check.dart';
import '../../features/places/presentation/bloc/places_bloc.dart';
import '../../features/pantry/data/datasources/pantry_remote_datasource.dart';
import '../../features/pantry/data/repositories/pantry_repository_impl.dart';
import '../../features/pantry/domain/repositories/pantry_repository.dart';
import '../../features/pantry/presentation/bloc/pantry_bloc.dart';
import '../../features/recurring/data/datasources/recurring_remote_datasource.dart';
import '../../features/recurring/data/repositories/recurring_repository_impl.dart';
import '../../features/recurring/domain/repositories/recurring_repository.dart';
import '../../features/recurring/presentation/bloc/recurring_bloc.dart';
import '../../features/requests/data/datasources/requests_remote_datasource.dart';
import '../../features/requests/data/repositories/requests_repository_impl.dart';
import '../../features/requests/domain/repositories/requests_repository.dart';
import '../../features/requests/presentation/bloc/requests_bloc.dart';
import '../geo/geolocator_location_provider.dart';
import '../geo/location_provider.dart';
import '../network/dio_client.dart';
import '../notifications/device_token_api.dart';
import '../notifications/local_notifications.dart';
import '../notifications/notification_planner.dart';
import '../notifications/push_service.dart';
import '../notifications/speech.dart';
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
    ..registerLazySingleton<FeedbackRemoteDataSource>(
      () => FeedbackRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<FeedbackRepository>(
      () => FeedbackRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<RecurringRemoteDataSource>(
      () => RecurringRemoteDataSource(getIt()),
    )
    ..registerLazySingleton<RecurringRepository>(
      () => RecurringRepositoryImpl(getIt()),
    )
    ..registerLazySingleton<LocationProvider>(
      () => const GeolocatorLocationProvider(),
    )
    ..registerLazySingleton<LocationArrivalCheck>(
      () => LocationArrivalCheck(
        provider: getIt<LocationProvider>(),
        places: getIt<PlacesRepository>(),
        notifications: getIt<LocalNotifications>(),
      ),
    )
    ..registerLazySingleton<FlutterLocalNotificationsPlugin>(
      () => FlutterLocalNotificationsPlugin(),
    )
    ..registerLazySingleton<NotificationPlanner>(
      () => const NotificationPlanner(),
    )
    ..registerLazySingleton<LocalNotifications>(
      () => LocalNotifications(getIt(), getIt()),
    )
    ..registerLazySingleton<Speech>(() => Speech(FlutterTts()))
    ..registerLazySingleton<DeviceTokenApi>(() => DeviceTokenApi(getIt()))
    ..registerLazySingleton<PushService>(
      () => PushService(
        tokens: getIt<DeviceTokenApi>(),
        notifications: getIt<LocalNotifications>(),
        speech: getIt<Speech>(),
      ),
    )
    ..registerLazySingleton<AppRouter>(() => AppRouter(getIt()))
    ..registerFactory<AuthBloc>(() => AuthBloc(getIt(), getIt()))
    ..registerFactory<RequestsBloc>(() => RequestsBloc(getIt()))
    ..registerFactory<PlacesBloc>(() => PlacesBloc(getIt()))
    ..registerFactory<PantryBloc>(() => PantryBloc(getIt()))
    ..registerFactory<FeedbackBloc>(() => FeedbackBloc(getIt()))
    ..registerFactory<RecurringBloc>(() => RecurringBloc(getIt()));
}
