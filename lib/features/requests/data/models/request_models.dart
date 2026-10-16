import '../../domain/entities/service_request.dart';

class ServiceRequestModel extends ServiceRequest {
  const ServiceRequestModel({
    required super.id,
    required super.title,
    required super.status,
    required super.priority,
    super.quantity,
    super.notes,
    super.category,
    super.storeName,
    super.dueAt,
    super.snoozeUntil,
    super.completedAt,
    super.itemId,
    super.assigneeId,
    super.assigneeName,
    super.requesterName,
    super.history,
    super.voiceCalls,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    final assignee = json['assignee'] as Map?;
    final requester = json['requested_by'] as Map?;

    return ServiceRequestModel(
      id: json['id'] as int,
      title: json['title'] as String,
      status: json['status'] as String,
      priority: json['priority'] as String,
      quantity: json['quantity'] as String?,
      notes: json['notes'] as String?,
      category: json['category'] as String?,
      storeName: json['store_name'] as String?,
      dueAt: _parseDate(json['due_at']),
      snoozeUntil: _parseDate(json['snooze_until']),
      completedAt: _parseDate(json['completed_at']),
      itemId: json['item_id'] as int?,
      assigneeId: assignee?['id'] as int?,
      assigneeName: assignee?['name'] as String?,
      requesterName: requester?['name'] as String?,
      history: (json['history'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(AssignmentModel.fromJson)
          .toList(),
      voiceCalls: (json['voice_calls'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(
            (item) => VoiceCallEntry(
              id: item['id'] as int,
              status: item['status'] as String,
              reason: item['reason'] as String?,
              createdAt: item['created_at'] is String
                  ? DateTime.tryParse(item['created_at'] as String)?.toLocal()
                  : null,
            ),
          )
          .toList(),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}

class AssignmentModel extends AssignmentEntry {
  const AssignmentModel({
    required super.id,
    required super.action,
    super.note,
    super.actorName,
    super.createdAt,
  });

  factory AssignmentModel.fromJson(Map<String, dynamic> json) {
    final actor = json['assigned_by'] as Map?;

    return AssignmentModel(
      id: json['id'] as int,
      action: json['action'] as String,
      note: json['note'] as String?,
      actorName: actor?['name'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
    );
  }
}

class HouseholdMemberModel extends HouseholdMember {
  const HouseholdMemberModel({required super.userId, required super.name});

  factory HouseholdMemberModel.fromJson(Map<String, dynamic> json) {
    return HouseholdMemberModel(
      userId: json['user_id'] as int,
      name: (json['name'] as String?) ?? 'Unnamed',
    );
  }
}

class RequestBoardModel extends RequestBoard {
  const RequestBoardModel({
    required super.counts,
    required super.overdue,
    required super.dueToday,
    required super.assignedToMe,
    required super.completedToday,
  });

  factory RequestBoardModel.fromJson(Map<String, dynamic> json) {
    List<ServiceRequest> parse(String key) => (json[key] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(ServiceRequestModel.fromJson)
        .toList();

    return RequestBoardModel(
      counts: (json['counts'] as Map? ?? const {}).map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      ),
      overdue: parse('overdue'),
      dueToday: parse('due_today'),
      assignedToMe: parse('assigned_to_me'),
      completedToday: parse('completed_today'),
    );
  }
}
