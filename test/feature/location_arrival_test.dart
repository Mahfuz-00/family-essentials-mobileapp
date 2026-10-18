import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/error/failures.dart';
import 'package:family_essentials_mobile/core/geo/geofence_evaluator.dart';
import 'package:family_essentials_mobile/core/geo/location_provider.dart';
import 'package:family_essentials_mobile/core/notifications/local_notifications.dart';
import 'package:family_essentials_mobile/core/notifications/notification_planner.dart';
import 'package:family_essentials_mobile/features/places/domain/entities/place.dart';
import 'package:family_essentials_mobile/features/places/domain/repositories/places_repository.dart';
import 'package:family_essentials_mobile/features/places/location_arrival_check.dart';

class MockPlacesRepository extends Mock implements PlacesRepository {}

class MockNotificationsPlugin extends Mock
    implements FlutterLocalNotificationsPlugin {}

/// Records what would have been shown. `showArrival` is the only behaviour the
/// check needs, so overriding it keeps the test free of platform channels.
class RecordingNotifications extends LocalNotifications {
  RecordingNotifications()
    : super(MockNotificationsPlugin(), const NotificationPlanner());

  final List<LocationArrival> shown = [];

  @override
  Future<void> showArrival(LocationArrival arrival) async {
    shown.add(arrival);
  }
}

class FakeLocationProvider implements LocationProvider {
  FakeLocationProvider({
    this.permitted = true,
    this.position = const GeoPoint(23.8105, 90.4125),
    this.failure,
  });

  bool permitted;
  GeoPoint position;
  Object? failure;

  int positionReads = 0;

  @override
  Future<bool> hasPermission() async => permitted;

  @override
  Future<bool> requestPermission() async => permitted;

  @override
  Future<GeoPoint> currentPosition() async {
    positionReads++;

    if (failure != null) {
      throw failure!;
    }

    return position;
  }
}

LocationArrival arrival({int id = 1, bool sent = true}) {
  return LocationArrival(
    id: id,
    placeId: 7,
    kind: 'store',
    status: sent ? 'sent' : 'skipped',
    placeName: 'Whole Foods',
    kindLabel: 'Store',
    reason: sent ? null : 'cooldown',
    reasonMessage: sent
        ? null
        : 'You were already told about this place recently.',
    title: sent ? 'Whole Foods' : null,
    body: sent ? 'You have 2 items to buy here.' : null,
    taskCount: sent ? 2 : 0,
  );
}

GeofenceEvaluation evaluationWith(List<LocationArrival> arrivals) {
  return GeofenceEvaluation(
    transitions: const [],
    shoppingLists: const [],
    arrivals: arrivals,
  );
}

void main() {
  late MockPlacesRepository places;
  late RecordingNotifications notifications;
  late FakeLocationProvider provider;

  setUpAll(() {
    registerFallbackValue(0.0);
  });

  setUp(() {
    places = MockPlacesRepository();
    notifications = RecordingNotifications();
    provider = FakeLocationProvider();
  });

  LocationArrivalCheck check() => LocationArrivalCheck(
    provider: provider,
    places: places,
    notifications: notifications,
  );

  test('does nothing at all when the member has not opted in', () async {
    final result = await check().run(enabled: false);

    expect(result.status, ArrivalCheckStatus.disabled);
    expect(provider.positionReads, 0);
    verifyNever(
      () => places.reportPosition(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
    expect(notifications.shown, isEmpty);
  });

  test('does not read a position when permission was refused', () async {
    provider.permitted = false;

    final result = await check().run(enabled: true);

    expect(result.status, ArrivalCheckStatus.permissionDenied);
    expect(result.message, contains('Time-based reminders still work'));
    expect(provider.positionReads, 0);
    verifyNever(
      () => places.reportPosition(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    );
  });

  test('shows only the arrivals the server decided to send', () async {
    when(
      () => places.reportPosition(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer(
      (_) async =>
          evaluationWith([arrival(id: 1), arrival(id: 2, sent: false)]),
    );

    final result = await check().run(enabled: true);

    expect(result.status, ArrivalCheckStatus.checked);
    expect(result.notified, hasLength(1));
    expect(notifications.shown, hasLength(1));
    expect(notifications.shown.single.body, 'You have 2 items to buy here.');
  });

  test('reports nothing nearby when no arrival was decided', () async {
    when(
      () => places.reportPosition(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenAnswer((_) async => evaluationWith(const []));

    final result = await check().run(enabled: true);

    expect(result.status, ArrivalCheckStatus.nothingNearby);
    expect(notifications.shown, isEmpty);
  });

  test('surfaces a failure instead of throwing', () async {
    when(
      () => places.reportPosition(
        latitude: any(named: 'latitude'),
        longitude: any(named: 'longitude'),
      ),
    ).thenThrow(const AppFailure('No network'));

    final result = await check().run(enabled: true);

    expect(result.status, ArrivalCheckStatus.failed);
    expect(result.message, 'No network');
    expect(notifications.shown, isEmpty);
  });

  test('surfaces an unreadable position as a failure', () async {
    provider.failure = Exception('no fix');

    final result = await check().run(enabled: true);

    expect(result.status, ArrivalCheckStatus.failed);
    expect(notifications.shown, isEmpty);
  });
}
