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
  final List<AssignmentEntry> history;
  final List<VoiceCallEntry> voiceCalls;

  bool get isOpen =>
      const ['pending', 'accepted', 'in_progress'].contains(status);

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
    required this.completedToday,
  });

  final Map<String, int> counts;
  final List<ServiceRequest> overdue;
  final List<ServiceRequest> dueToday;
  final List<ServiceRequest> assignedToMe;
  final List<ServiceRequest> completedToday;

  @override
  List<Object?> get props => [
    counts,
    overdue,
    dueToday,
    assignedToMe,
    completedToday,
  ];
}
