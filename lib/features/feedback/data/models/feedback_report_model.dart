import '../../domain/entities/feedback_report.dart';

class FeedbackReportModel extends FeedbackReport {
  const FeedbackReportModel({
    required super.id,
    required super.type,
    required super.status,
    required super.priority,
    required super.subject,
    required super.body,
    super.resolutionNote,
    super.createdAt,
  });

  factory FeedbackReportModel.fromJson(Map<String, dynamic> json) {
    return FeedbackReportModel(
      id: json['id'] as int,
      type: json['type'] as String? ?? 'bug',
      status: json['status'] as String? ?? 'new',
      priority: json['priority'] as String? ?? 'normal',
      subject: json['subject'] as String? ?? '',
      body: json['body'] as String? ?? '',
      resolutionNote: json['resolution_note'] as String?,
      createdAt: _parseDate(json['created_at']),
    );
  }

  static DateTime? _parseDate(Object? value) =>
      value is String ? DateTime.tryParse(value)?.toLocal() : null;
}
