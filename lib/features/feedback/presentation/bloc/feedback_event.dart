import 'package:equatable/equatable.dart';

sealed class FeedbackEvent extends Equatable {
  const FeedbackEvent();

  @override
  List<Object?> get props => [];
}

class FeedbackRequested extends FeedbackEvent {
  const FeedbackRequested();
}

class FeedbackSubmitted extends FeedbackEvent {
  const FeedbackSubmitted({
    required this.type,
    required this.subject,
    required this.body,
    this.priority = 'normal',
  });

  final String type;
  final String subject;
  final String body;
  final String priority;

  @override
  List<Object?> get props => [type, subject, body, priority];
}
