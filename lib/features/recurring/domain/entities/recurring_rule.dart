import 'package:equatable/equatable.dart';

/// A recurring rule: the template the daily spawner turns into a fresh request
/// each cycle. Pausing stops new cycles; requests already spawned keep their own
/// history.
class RecurringRule extends Equatable {
  const RecurringRule({
    required this.id,
    required this.title,
    required this.cadence,
    this.quantity,
    this.notes,
    this.category,
    this.priority = 'normal',
    this.weekday,
    this.dayOfMonth,
    this.nextRunOn,
    this.lastRunOn,
    this.active = true,
    this.assigneeId,
    this.assigneeName,
    this.placeId,
    this.placeName,
    this.triggerPlaceId,
    this.triggerDirection,
    this.triggerPlaceName,
    this.amountMinor,
    this.ledgerId,
  });

  final int id;
  final String title;

  /// `daily`, `weekly` or `monthly`.
  final String cadence;

  final String? quantity;
  final String? notes;
  final String? category;
  final String priority;

  /// 0 = Sunday … 6 = Saturday, as the API stores it. Weekly only.
  final int? weekday;

  /// 1–31. Monthly only.
  final int? dayOfMonth;

  final DateTime? nextRunOn;
  final DateTime? lastRunOn;
  final bool active;

  final int? assigneeId;
  final String? assigneeName;
  final int? placeId;
  final String? placeName;

  final int? triggerPlaceId;
  final String? triggerDirection;
  final String? triggerPlaceName;

  final int? amountMinor;
  final int? ledgerId;

  bool get hasLocationTrigger => triggerPlaceId != null;

  /// The cadence in words: "Every day", "Every Thursday",
  /// "Every month on the 31st".
  String get cadenceLabel {
    switch (cadence) {
      case 'weekly':
        return 'Every ${weekdayName(weekday) ?? 'week'}';
      case 'monthly':
        return dayOfMonth == null
            ? 'Every month'
            : 'Every month on the ${ordinal(dayOfMonth!)}';
      default:
        return 'Every day';
    }
  }

  /// The cue in one line, or null when the rule has no place reminder.
  String? get reminderCue {
    if (triggerPlaceId == null) {
      return null;
    }

    final where = triggerPlaceName ?? 'a saved place';
    final how = triggerDirection == 'exit' ? 'leave' : 'arrive at';

    return 'Reminds you when you $how $where';
  }

  @override
  List<Object?> get props => [
    id,
    title,
    cadence,
    quantity,
    notes,
    category,
    priority,
    weekday,
    dayOfMonth,
    nextRunOn,
    lastRunOn,
    active,
    assigneeId,
    assigneeName,
    placeId,
    placeName,
    triggerPlaceId,
    triggerDirection,
    triggerPlaceName,
    amountMinor,
    ledgerId,
  ];
}

/// 0 = Sunday … 6 = Saturday, which is what the API's `weekday` field holds.
const List<String> weekdayNames = [
  'Sunday',
  'Monday',
  'Tuesday',
  'Wednesday',
  'Thursday',
  'Friday',
  'Saturday',
];

String? weekdayName(int? weekday) =>
    weekday == null || weekday < 0 || weekday > 6 ? null : weekdayNames[weekday];

/// Dart's `DateTime.weekday` is 1 = Monday … 7 = Sunday, so the two mappings are
/// not the same number and must not be confused.
int apiWeekdayFromDart(int dartWeekday) => dartWeekday % 7;

String ordinal(int day) {
  if (day % 100 >= 11 && day % 100 <= 13) {
    return '${day}th';
  }

  switch (day % 10) {
    case 1:
      return '${day}st';
    case 2:
      return '${day}nd';
    case 3:
      return '${day}rd';
    default:
      return '${day}th';
  }
}
