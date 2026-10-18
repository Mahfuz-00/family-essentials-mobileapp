import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/requests_repository.dart';
import 'requests_event.dart';
import 'requests_state.dart';

class RequestsBloc extends Bloc<RequestsEvent, RequestsState> {
  RequestsBloc(this._repository) : super(const RequestsInitial()) {
    on<BoardRequested>(_onBoardRequested);
    on<DetailRequested>(_onDetailRequested);
    on<RequestSubmitted>(_onRequestSubmitted);
    on<ActionRequested>(_onActionRequested);
    on<VoiceCallRequested>(_onVoiceCallRequested);
  }

  final RequestsRepository _repository;

  Future<void> _onBoardRequested(
    BoardRequested event,
    Emitter<RequestsState> emit,
  ) async {
    emit(const RequestsLoading());

    try {
      final board = await _repository.board();
      final members = await _repository.members();

      emit(RequestsBoardLoaded(board, members));
    } on AppFailure catch (failure) {
      emit(RequestsFailure(failure.message));
    }
  }

  Future<void> _onDetailRequested(
    DetailRequested event,
    Emitter<RequestsState> emit,
  ) async {
    emit(const RequestsLoading());

    try {
      emit(RequestsDetailLoaded(await _repository.find(event.id)));
    } on AppFailure catch (failure) {
      emit(RequestsFailure(failure.message));
    }
  }

  Future<void> _onRequestSubmitted(
    RequestSubmitted event,
    Emitter<RequestsState> emit,
  ) async {
    emit(const RequestsLoading());

    try {
      await _repository.create(
        title: event.title,
        quantity: event.quantity,
        storeName: event.storeName,
        priority: event.priority,
        dueAt: event.dueAt,
        assigneeId: event.assigneeId,
        placeId: event.placeId,
        triggerPlaceId: event.triggerPlaceId,
        triggerDirection: event.triggerDirection,
      );

      emit(const RequestsActionSuccess('Request added.'));
    } on AppFailure catch (failure) {
      emit(RequestsFailure(failure.message));
    }
  }

  Future<void> _onActionRequested(
    ActionRequested event,
    Emitter<RequestsState> emit,
  ) async {
    emit(const RequestsLoading());

    try {
      await _repository.act(event.id, event.action, payload: event.payload);

      emit(const RequestsActionSuccess('Updated.'));
    } on AppFailure catch (failure) {
      emit(RequestsFailure(failure.message));
    }
  }

  Future<void> _onVoiceCallRequested(
    VoiceCallRequested event,
    Emitter<RequestsState> emit,
  ) async {
    emit(const RequestsLoading());

    try {
      await _repository.triggerVoiceCall(event.id);

      emit(const RequestsActionSuccess('Voice call requested.'));
    } on AppFailure catch (failure) {
      emit(RequestsFailure(failure.message));
    }
  }
}
