import '../../features/requests/domain/entities/service_request.dart';

class ScheduledNotification {
  const ScheduledNotification({
    required this.requestId,
    required this.title,
    required this.body,
    required this.fireAt,
  });

  final int requestId;
  final String title;
  final String body;
  final DateTime fireAt;
}

/// Pure mapping from requests to the device-local reminders that should exist.
/// Kept free of platform calls so it can be unit tested without a device.
class NotificationPlanner {
  const NotificationPlanner();

  List<ScheduledNotification> plan(
    List<ServiceRequest> requests,
    DateTime now,
  ) {
    final planned = <ScheduledNotification>[];

    for (final request in requests) {
      if (!request.isOpen) {
        continue;
      }

      final fireAt = request.snoozeUntil ?? request.dueAt;

      if (fireAt == null || !fireAt.isAfter(now)) {
        continue;
      }

      planned.add(
        ScheduledNotification(
          requestId: request.id,
          title: 'Reminder: ${request.title}',
          body: [
            request.quantity,
            request.storeName,
          ].whereType<String>().join(' · '),
          fireAt: fireAt,
        ),
      );
    }

    return planned;
  }
}
