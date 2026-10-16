import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tz_data;
import 'package:timezone/timezone.dart' as tz;

import '../../features/requests/domain/entities/service_request.dart';
import 'notification_planner.dart';

/// PRD Layer 1: reminders scheduled directly on the device so they fire at the
/// exact due time even without connectivity.
class LocalNotifications {
  LocalNotifications(this._plugin, this._planner);

  final FlutterLocalNotificationsPlugin _plugin;
  final NotificationPlanner _planner;

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
    );

    _initialized = true;
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

  Future<void> cancel(int requestId) => _plugin.cancel(id: requestId);
}
