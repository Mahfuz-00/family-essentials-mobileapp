import 'package:equatable/equatable.dart';

import '../../domain/entities/feedback_report.dart';

sealed class FeedbackState extends Equatable {
  const FeedbackState();

  @override
  List<Object?> get props => [];
}

class FeedbackInitial extends FeedbackState {
  const FeedbackInitial();
}

class FeedbackLoading extends FeedbackState {
  const FeedbackLoading();
}

class FeedbackLoaded extends FeedbackState {
  const FeedbackLoaded(this.reports);

  final List<FeedbackReport> reports;

  @override
  List<Object?> get props => [reports];
}

class FeedbackActionSuccess extends FeedbackState {
  const FeedbackActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class FeedbackFailure extends FeedbackState {
  const FeedbackFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
