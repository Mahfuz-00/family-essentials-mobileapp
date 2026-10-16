import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/feedback_repository.dart';
import 'feedback_event.dart';
import 'feedback_state.dart';

class FeedbackBloc extends Bloc<FeedbackEvent, FeedbackState> {
  FeedbackBloc(this._repository) : super(const FeedbackInitial()) {
    on<FeedbackRequested>(_onRequested);
    on<FeedbackSubmitted>(_onSubmitted);
  }

  final FeedbackRepository _repository;

  Future<void> _onRequested(
    FeedbackRequested event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(const FeedbackLoading());

    try {
      emit(FeedbackLoaded(await _repository.reports()));
    } on AppFailure catch (failure) {
      emit(FeedbackFailure(failure.message));
    }
  }

  Future<void> _onSubmitted(
    FeedbackSubmitted event,
    Emitter<FeedbackState> emit,
  ) async {
    emit(const FeedbackLoading());

    try {
      await _repository.send(
        type: event.type,
        subject: event.subject,
        body: event.body,
        priority: event.priority,
        context: const {'platform': 'mobile'},
      );

      emit(
        const FeedbackActionSuccess(
          'Sent. It is in the platform team’s queue.',
        ),
      );
    } on AppFailure catch (failure) {
      emit(FeedbackFailure(failure.message));
    }
  }
}
