import '../entities/recurring_rule.dart';

abstract class RecurringRepository {
  Future<List<RecurringRule>> rules();

  Future<RecurringRule> create({
    required String title,
    required String cadence,
    int? weekday,
    int? dayOfMonth,
    String? quantity,
    String priority,
    int? assigneeId,
    int? placeId,
    int? triggerPlaceId,
    String? triggerDirection,
  });

  /// Pauses or resumes a rule. Pausing never touches requests already spawned.
  Future<RecurringRule> setActive({required int id, required bool active});

  Future<void> remove(int id);
}
