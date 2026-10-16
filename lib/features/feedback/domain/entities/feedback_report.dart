import 'package:equatable/equatable.dart';

/// A bug report, a piece of feedback, or a feature request from this household.
///
/// The household can see the status of what it sent, and the note an operator
/// wrote when closing it — a channel nobody hears back from is not a channel.
class FeedbackReport extends Equatable {
  const FeedbackReport({
    required this.id,
    required this.type,
    required this.status,
    required this.priority,
    required this.subject,
    required this.body,
    this.resolutionNote,
    this.createdAt,
  });

  final int id;
  final String type;
  final String status;
  final String priority;
  final String subject;
  final String body;
  final String? resolutionNote;
  final DateTime? createdAt;

  bool get isOpen => status != 'resolved' && status != 'wont_fix';

  /// What the household is told, rather than the raw enum.
  String get statusLabel => switch (status) {
    'new' => 'Received',
    'triaged' => 'Being looked at',
    'in_progress' => 'In progress',
    'resolved' => 'Resolved',
    'wont_fix' => "Won't fix",
    _ => status,
  };

  String get typeLabel => switch (type) {
    'bug' => 'Something is broken',
    'feedback' => 'General feedback',
    'feature_request' => 'Something is missing',
    _ => type,
  };

  @override
  List<Object?> get props => [
    id,
    type,
    status,
    priority,
    subject,
    body,
    resolutionNote,
    createdAt,
  ];
}
