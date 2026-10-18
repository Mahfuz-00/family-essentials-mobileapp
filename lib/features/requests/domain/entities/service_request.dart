import 'package:equatable/equatable.dart';

class ServiceRequest extends Equatable {
  const ServiceRequest({
    required this.id,
    required this.title,
    required this.status,
    required this.priority,
    this.quantity,
    this.notes,
    this.category,
    this.storeName,
    this.dueAt,
    this.snoozeUntil,
    this.completedAt,
    this.itemId,
    this.assigneeId,
    this.assigneeName,
    this.requesterName,
    this.triggerPlaceId,
    this.triggerDirection,
    this.triggerPlaceName,
    this.amountMinor,
    this.ledgerId,
    this.history = const [],
    this.voiceCalls = const [],
  });

  final int id;
  final String title;
  final String status;
  final String priority;
  final String? quantity;
  final String? notes;
  final String? category;
  final String? storeName;
  final DateTime? dueAt;
  final DateTime? snoozeUntil;
  final DateTime? completedAt;
  final int? itemId;
  final int? assigneeId;
  final String? assigneeName;
  final String? requesterName;

  /// The member's own reminder cue — separate from [storeName], which is where
  /// the thing is bought. Null when the task is reminded by time alone.
  final int? triggerPlaceId;

  /// `enter` or `exit`, the direction that sets the cue off.
  final String? triggerDirection;

  /// Only present when the API eager-loaded the place.
  final String? triggerPlaceName;

  /// What this task is charged to, in integer minor units.
  final int? amountMinor;
  final int? ledgerId;

  final List<AssignmentEntry> history;
  final List<VoiceCallEntry> voiceCalls;

  bool get isOpen =>
      const ['pending', 'accepted', 'in_progress'].contains(status);

  bool get hasLocationTrigger => triggerPlaceId != null;

  /// The cue in one line, exactly as the member set it — or null when the
  /// reminder is time-based. The app never invents a cue the API did not store.
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
    status,
    priority,
    quantity,
    notes,
    category,
    storeName,
    dueAt,
    snoozeUntil,
    completedAt,
    itemId,
    assigneeId,
    assigneeName,
    requesterName,
    triggerPlaceId,
    triggerDirection,
    triggerPlaceName,
    amountMinor,
    ledgerId,
    history,
    voiceCalls,
  ];
}

class VoiceCallEntry extends Equatable {
  const VoiceCallEntry({
    required this.id,
    required this.status,
    this.reason,
    this.createdAt,
  });

  final int id;
  final String status;
  final String? reason;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, status, reason, createdAt];
}

class AssignmentEntry extends Equatable {
  const AssignmentEntry({
    required this.id,
    required this.action,
    this.note,
    this.actorName,
    this.createdAt,
  });

  final int id;
  final String action;
  final String? note;
  final String? actorName;
  final DateTime? createdAt;

  @override
  List<Object?> get props => [id, action, note, actorName, createdAt];
}

class HouseholdMember extends Equatable {
  const HouseholdMember({required this.userId, required this.name});

  final int userId;
  final String name;

  @override
  List<Object?> get props => [userId, name];
}

class RequestBoard extends Equatable {
  const RequestBoard({
    required this.counts,
    required this.overdue,
    required this.dueToday,
    required this.assignedToMe,
    required this.backlog,
    required this.completedToday,
  });

  final Map<String, int> counts;
  final List<ServiceRequest> overdue;
  final List<ServiceRequest> dueToday;
  final List<ServiceRequest> assignedToMe;

  /// Open items the other buckets miss: no due date, due later, or assigned to
  /// someone else. Without it a new undated request appeared nowhere at all.
  final List<ServiceRequest> backlog;

  final List<ServiceRequest> completedToday;

  @override
  List<Object?> get props => [
    counts,
    overdue,
    dueToday,
    assignedToMe,
    backlog,
    completedToday,
  ];
}
