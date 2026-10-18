import '../../domain/entities/recurring_rule.dart';

class RecurringRuleModel extends RecurringRule {
  const RecurringRuleModel({
    required super.id,
    required super.title,
    required super.cadence,
    super.quantity,
    super.notes,
    super.category,
    super.priority,
    super.weekday,
    super.dayOfMonth,
    super.nextRunOn,
    super.lastRunOn,
    super.active,
    super.assigneeId,
    super.assigneeName,
    super.placeId,
    super.placeName,
    super.triggerPlaceId,
    super.triggerDirection,
    super.triggerPlaceName,
    super.amountMinor,
    super.ledgerId,
  });

  factory RecurringRuleModel.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'] as Map?;
    final trigger = json['location_trigger'] as Map?;

    return RecurringRuleModel(
      id: json['id'] as int,
      title: (json['title'] as String?) ?? 'Untitled',
      cadence: (json['cadence'] as String?) ?? 'daily',
      quantity: json['quantity'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      priority: (json['priority'] as String?) ?? 'normal',
      weekday: (json['weekday'] as num?)?.toInt(),
      dayOfMonth: (json['day_of_month'] as num?)?.toInt(),
      nextRunOn: _date(json['next_run_on']),
      lastRunOn: _date(json['last_run_on']),
      active: json['active'] as bool? ?? true,
      assigneeId: (json['assignee_id'] as num?)?.toInt() ?? assignee?['id'] as int?,
      assigneeName: assignee?['name'] as String?,
      placeId: (json['place_id'] as num?)?.toInt(),
      placeName: json['place_name'] as String?,
      triggerPlaceId: (trigger?['place_id'] as num?)?.toInt(),
      triggerDirection: trigger?['direction'] as String?,
      triggerPlaceName: trigger?['place_name'] as String?,
      amountMinor: (json['amount_minor'] as num?)?.toInt(),
      ledgerId: (json['ledger_id'] as num?)?.toInt(),
    );
  }

  /// Dates come back as `YYYY-MM-DD`, which is a day, not an instant.
  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}
