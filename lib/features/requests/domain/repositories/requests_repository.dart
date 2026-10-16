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
  });

  Future<void> act(int id, String action, {Map<String, dynamic>? payload});

  Future<void> triggerVoiceCall(int requestId);
}
