import '../entities/service_request.dart';

abstract class RequestsRepository {
  Future<RequestBoard> board();

  Future<List<HouseholdMember>> members();

  Future<ServiceRequest> find(int id);

  Future<ServiceRequest> create({
    required String title,
    String? quantity,
    String? storeName,
    String priority,
    DateTime? dueAt,
    int? assigneeId,
    int? placeId,
    int? triggerPlaceId,
    String? triggerDirection,
  });

  /// Change the member's reminder cue on an existing task. Passing null for both
  /// clears the cue, so the task is reminded by time alone.
  Future<ServiceRequest> updateCue({
    required int id,
    int? triggerPlaceId,
    String? triggerDirection,
  });

  Future<void> act(int id, String action, {Map<String, dynamic>? payload});

  Future<void> triggerVoiceCall(int requestId);
}
