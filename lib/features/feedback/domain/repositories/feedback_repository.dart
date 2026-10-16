import '../entities/feedback_report.dart';

abstract class FeedbackRepository {
  /// Everything this household has sent.
  Future<List<FeedbackReport>> reports();

  /// Send a new one. [context] carries whatever the client knows about where it
  /// happened, which saves a round trip of "which screen was that?".
  Future<FeedbackReport> send({
    required String type,
    required String subject,
    required String body,
    String priority,
    Map<String, String> context,
  });
}
