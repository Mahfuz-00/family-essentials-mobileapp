import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/pantry_repository.dart';
import 'pantry_event.dart';
import 'pantry_state.dart';

class PantryBloc extends Bloc<PantryEvent, PantryState> {
  PantryBloc(this._repository) : super(const PantryInitial()) {
    on<PantryRequested>(_onRequested);
    on<EssentialCreated>(_onCreated);
    on<EssentialRestocked>(_onRestocked);
    on<EssentialDeleted>(_onDeleted);
  }

  final PantryRepository _repository;

  Future<void> _onRequested(
    PantryRequested event,
    Emitter<PantryState> emit,
  ) async {
    emit(const PantryLoading());

    try {
      emit(PantryLoaded(await _repository.snapshot(dueOnly: event.dueOnly)));
    } on AppFailure catch (failure) {
      emit(PantryFailure(failure.message));
    }
  }

  Future<void> _onCreated(
    EssentialCreated event,
    Emitter<PantryState> emit,
  ) async {
    try {
      await _repository.create(
        name: event.name,
        category: event.category,
        defaultStore: event.defaultStore,
        packSize: event.packSize,
        cadenceDays: event.cadenceDays,
        threshold: event.threshold,
        stockLevel: event.stockLevel,
      );

      emit(const PantryActionSuccess('Essential added to the pantry.'));
    } on AppFailure catch (failure) {
      emit(PantryFailure(failure.message));
    }
  }

  Future<void> _onRestocked(
    EssentialRestocked event,
    Emitter<PantryState> emit,
  ) async {
    try {
      await _repository.restock(id: event.id, quantity: event.quantity);

      emit(const PantryActionSuccess('Stock topped up.'));
    } on AppFailure catch (failure) {
      emit(PantryFailure(failure.message));
    }
  }

  Future<void> _onDeleted(
    EssentialDeleted event,
    Emitter<PantryState> emit,
  ) async {
    try {
      await _repository.remove(event.id);

      emit(const PantryActionSuccess('Essential removed.'));
    } on AppFailure catch (failure) {
      emit(PantryFailure(failure.message));
    }
  }
}
