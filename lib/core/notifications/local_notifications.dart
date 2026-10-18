import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/places/domain/entities/place.dart';
import '../../features/requests/domain/entities/service_request.dart';
import 'notification_planner.dart';

/// PRD Layer 1: reminders scheduled directly on the device so they fire at the
/// exact due time even without connectivity.
///
/// Also displays arrivals. The server decides who is told what; this class only
/// shows the decision it was handed, on the channel the member chose.
class LocalNotifications {
  LocalNotifications(this._plugin, this._planner);

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPlanner _planner;

  /// Wired in `main.dart` to the router, so tapping an arrival opens the place
  /// it was about.
  void Function(String placeId)? onArrivalTapped;

  static const String _arrivalPayloadPrefix = 'place:';

  /// Away from the reminder ids, which are request ids.
  static const int _arrivalIdBase = 900000;

  /// One channel per alert style: Android fixes a channel's sound and vibration
  /// when it is created, so the style cannot be applied at send time.
  static const List<String> arrivalStyles = [
    'silent',
    'vibrate',
    'sound',
    'voice',
  ];

  final Set<int> _scheduled = <int>{};
  bool _initialized = false;
  bool _permissionRequested = false;

  Future<void> init() async {
    if (_initialized) {
      return;
    }

    tz_data.initializeTimeZones();

    try {
      final info = await FlutterTimezone.getLocalTimezone();
      tz.setLocalLocation(tz.getLocation(info.identifier));
    } catch (_) {
      // Fall back to UTC if the platform timezone cannot be resolved.
    }

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      ),
      onDidReceiveNotificationResponse: (response) {
        final payload = response.payload;

        if (payload == null || !payload.startsWith(_arrivalPayloadPrefix)) {
          return;
        }

        onArrivalTapped?.call(payload.substring(_arrivalPayloadPrefix.length));
      },
    );

    await _createArrivalChannels();

    _initialized = true;
  }

  Future<void> _createArrivalChannels() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android == null) {
      return;
    }

    const channels = [
      AndroidNotificationChannel(
        'arrivals_silent',
        'Arrivals — silent',
        description: 'Work waiting where you have just arrived, quietly',
        importance: Importance.low,
        playSound: false,
        enableVibration: false,
      ),
      AndroidNotificationChannel(
        'arrivals_vibrate',
        'Arrivals — vibrate',
        description: 'Work waiting where you have just arrived, with a buzz',
        importance: Importance.high,
        playSound: false,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'arrivals_sound',
        'Arrivals — sound',
        description: 'Work waiting where you have just arrived, with a sound',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
      AndroidNotificationChannel(
        'arrivals_voice',
        'Arrivals — voice',
        description: 'The same, and spoken when you open it',
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      ),
    ];

    for (final channel in channels) {
      await android.createNotificationChannel(channel);
    }
  }

  Future<bool> requestPermission() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();

    if (android != null) {
      return await android.requestNotificationsPermission() ?? false;
    }

    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();

    if (ios != null) {
      return await ios.requestPermissions(
            alert: true,
            badge: true,
            sound: true,
          ) ??
          false;
    }

    return true;
  }

  /// Re-syncs the device reminders so they match the current household state:
  /// schedules open, future-due requests and cancels anything that is no longer.
  Future<void> sync(List<ServiceRequest> requests, DateTime now) async {
    await init();

    if (!_permissionRequested) {
      _permissionRequested = true;
      await requestPermission();
    }

    final planned = _planner.plan(requests, now);
    final keep = planned.map((notification) => notification.requestId).toSet();

    for (final id in _scheduled.where((id) => !keep.contains(id)).toList()) {
      await _plugin.cancel(id: id);
    }

    _scheduled
      ..clear()
      ..addAll(keep);

    for (final notification in planned) {
      await _plugin.zonedSchedule(
        id: notification.requestId,
        title: notification.title,
        body: notification.body.isEmpty ? null : notification.body,
        scheduledDate: tz.TZDateTime.from(notification.fireAt, tz.local),
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'family_essentials_reminders',
            'Reminders',
            channelDescription: 'Household task reminders',
            importance: Importance.high,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      );
    }
  }

  /// Show one arrival decision immediately.
  ///
  /// The text comes from the server, so the app never composes a notification the
  /// API did not authorise. `style` picks the channel; on iOS the system decides
  /// vibration, and the sound is the bundled default.
  Future<void> showArrival(
    LocationArrival arrival, {
    String style = 'sound',
  }) async {
    await init();

    await _plugin.show(
      id: _arrivalIdBase + (arrival.id % 100000),
      title: arrival.title ?? arrival.placeName ?? 'Arrival',
      body: arrival.body,
      notificationDetails: NotificationDetails(
        android: _androidDetails(style),
        iOS: const DarwinNotificationDetails(),
      ),
      payload: '$_arrivalPayloadPrefix${arrival.placeId}',
    );
  }

  /// Plays the chosen style, so the member can hear what they are choosing.
  Future<void> preview(String style) async {
    await showArrival(
      LocationArrival(
        id: 0,
        placeId: 0,
        kind: 'other',
        status: 'sent',
        placeName: 'Preview',
        title: 'Preview',
        body: style == 'voice'
            ? 'This is how an arrival will be spoken when you open it.'
            : 'This is how an arrival will look.',
      ),
      style: style,
    );
  }

  AndroidNotificationDetails _androidDetails(String style) {
    final name = switch (style) {
      'silent' => 'Arrivals — silent',
      'vibrate' => 'Arrivals — vibrate',
      'voice' => 'Arrivals — voice',
      _ => 'Arrivals — sound',
    };

    return AndroidNotificationDetails(
      'arrivals_$style',
      name,
      channelDescription: 'Work waiting where you have just arrived',
      importance: style == 'silent' ? Importance.low : Importance.high,
      priority: style == 'silent' ? Priority.low : Priority.high,
      playSound: style == 'sound' || style == 'voice',
      enableVibration: style != 'silent',
    );
  }

  Future<void> cancel(int requestId) => _plugin.cancel(id: requestId);
}
