import 'package:flutter_test/flutter_test.dart';

import 'package:family_essentials_mobile/core/notifications/notification_planner.dart';
import 'package:family_essentials_mobile/features/requests/domain/entities/service_request.dart';

void main() {
  const planner = NotificationPlanner();
  final now = DateTime(2026, 10, 16, 12);

  ServiceRequest request({
    int id = 1,
    String status = 'pending',
    DateTime? dueAt,
    DateTime? snoozeUntil,
  }) => ServiceRequest(
    id: id,
    title: 'Milk',
    status: status,
    priority: 'normal',
    quantity: '2 litres',
    storeName: 'Whole Foods',
    dueAt: dueAt,
    snoozeUntil: snoozeUntil,
  );

  test('plans a notification for an open request due in the future', () {
    final planned = planner.plan([
      request(dueAt: now.add(const Duration(hours: 2))),
    ], now);

    expect(planned, hasLength(1));
    expect(planned.first.requestId, 1);
    expect(planned.first.title, 'Reminder: Milk');
    expect(planned.first.body, '2 litres · Whole Foods');
    expect(planned.first.fireAt, now.add(const Duration(hours: 2)));
  });

  test('skips closed requests and past due dates', () {
    final planned = planner.plan([
      request(id: 1, dueAt: now.add(const Duration(hours: 1))),
      request(
        id: 2,
        status: 'completed',
        dueAt: now.add(const Duration(hours: 1)),
      ),
      request(id: 3, dueAt: now.subtract(const Duration(hours: 1))),
      request(id: 4),
    ], now);

    expect(planned.map((n) => n.requestId), [1]);
  });

  test('prefers the snooze time over the original due date', () {
    final snoozeUntil = now.add(const Duration(hours: 5));

    final planned = planner.plan([
      request(
        dueAt: now.subtract(const Duration(hours: 1)),
        snoozeUntil: snoozeUntil,
      ),
    ], now);

    expect(planned.single.fireAt, snoozeUntil);
  });
}
