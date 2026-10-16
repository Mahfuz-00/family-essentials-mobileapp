import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/places_repository.dart';
import 'places_event.dart';
import 'places_state.dart';

class PlacesBloc extends Bloc<PlacesEvent, PlacesState> {
  PlacesBloc(this._repository) : super(const PlacesInitial()) {
    on<PlacesRequested>(_onRequested);
    on<PlaceCreated>(_onCreated);
    on<PlaceDeleted>(_onDeleted);
  }

  final PlacesRepository _repository;

  Future<void> _onRequested(
    PlacesRequested event,
    Emitter<PlacesState> emit,
  ) async {
    emit(const PlacesLoading());

    try {
      emit(PlacesLoaded(await _repository.places()));
    } on AppFailure catch (failure) {
      emit(PlacesFailure(failure.message));
    }
  }

  Future<void> _onCreated(PlaceCreated event, Emitter<PlacesState> emit) async {
    emit(const PlacesLoading());

    try {
      await _repository.create(
        name: event.name,
        latitude: event.latitude,
        longitude: event.longitude,
        radiusMeters: event.radiusMeters,
        category: event.category,
      );

      emit(const PlacesActionSuccess('Place saved.'));
    } on AppFailure catch (failure) {
      emit(PlacesFailure(failure.message));
    }
  }

  Future<void> _onDeleted(PlaceDeleted event, Emitter<PlacesState> emit) async {
    emit(const PlacesLoading());

    try {
      await _repository.remove(event.id);

      emit(const PlacesActionSuccess('Place removed.'));
    } on AppFailure catch (failure) {
      emit(PlacesFailure(failure.message));
    }
  }
}
