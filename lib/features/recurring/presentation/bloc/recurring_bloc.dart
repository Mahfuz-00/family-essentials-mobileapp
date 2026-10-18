import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/recurring_repository.dart';
import 'recurring_event.dart';
import 'recurring_state.dart';

class RecurringBloc extends Bloc<RecurringEvent, RecurringState> {
  RecurringBloc(this._repository) : super(const RecurringInitial()) {
    on<RecurringRulesRequested>(_onRequested);
    on<RecurringRuleCreated>(_onCreated);
    on<RecurringRuleToggled>(_onToggled);
    on<RecurringRuleDeleted>(_onDeleted);
  }

  final RecurringRepository _repository;

  Future<void> _onRequested(
    RecurringRulesRequested event,
    Emitter<RecurringState> emit,
  ) async {
    emit(const RecurringLoading());

    try {
      emit(RecurringLoaded(await _repository.rules()));
    } on AppFailure catch (failure) {
      emit(RecurringFailure(failure.message));
    }
  }

  Future<void> _onCreated(
    RecurringRuleCreated event,
    Emitter<RecurringState> emit,
  ) async {
    try {
      await _repository.create(
        title: event.title,
        cadence: event.cadence,
        weekday: event.weekday,
        dayOfMonth: event.dayOfMonth,
        quantity: event.quantity,
        priority: event.priority,
        assigneeId: event.assigneeId,
        placeId: event.placeId,
        triggerPlaceId: event.triggerPlaceId,
        triggerDirection: event.triggerDirection,
      );

      emit(const RecurringActionSuccess('Recurring rule added.'));
    } on AppFailure catch (failure) {
      emit(RecurringFailure(failure.message));
    }
  }

  Future<void> _onToggled(
    RecurringRuleToggled event,
    Emitter<RecurringState> emit,
  ) async {
    try {
      await _repository.setActive(id: event.id, active: event.active);

      emit(
        RecurringActionSuccess(
          event.active ? 'Rule resumed.' : 'Rule paused.',
        ),
      );
    } on AppFailure catch (failure) {
      emit(RecurringFailure(failure.message));
    }
  }

  Future<void> _onDeleted(
    RecurringRuleDeleted event,
    Emitter<RecurringState> emit,
  ) async {
    try {
      await _repository.remove(event.id);

      emit(const RecurringActionSuccess('Recurring rule removed.'));
    } on AppFailure catch (failure) {
      emit(RecurringFailure(failure.message));
    }
  }
}
