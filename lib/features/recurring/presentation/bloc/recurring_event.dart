import 'package:equatable/equatable.dart';

sealed class RecurringEvent extends Equatable {
  const RecurringEvent();

  @override
  List<Object?> get props => [];
}

class RecurringRulesRequested extends RecurringEvent {
  const RecurringRulesRequested();
}

class RecurringRuleCreated extends RecurringEvent {
  const RecurringRuleCreated({
    required this.title,
    required this.cadence,
    this.weekday,
    this.dayOfMonth,
    this.quantity,
    this.priority = 'normal',
    this.assigneeId,
    this.placeId,
    this.triggerPlaceId,
    this.triggerDirection,
  });

  final String title;

  /// `daily`, `weekly` or `monthly`.
  final String cadence;

  /// Required by the API when the cadence is weekly.
  final int? weekday;

  /// Required by the API when the cadence is monthly.
  final int? dayOfMonth;

  final String? quantity;
  final String priority;
  final int? assigneeId;
  final int? placeId;
  final int? triggerPlaceId;
  final String? triggerDirection;

  @override
  List<Object?> get props => [
    title,
    cadence,
    weekday,
    dayOfMonth,
    quantity,
    priority,
    assigneeId,
    placeId,
    triggerPlaceId,
    triggerDirection,
  ];
}

/// Pause or resume one rule.
class RecurringRuleToggled extends RecurringEvent {
  const RecurringRuleToggled({required this.id, required this.active});

  final int id;
  final bool active;

  @override
  List<Object?> get props => [id, active];
}

class RecurringRuleDeleted extends RecurringEvent {
  const RecurringRuleDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
