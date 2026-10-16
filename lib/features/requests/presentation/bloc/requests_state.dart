import 'package:equatable/equatable.dart';

import '../../domain/entities/service_request.dart';

sealed class RequestsState extends Equatable {
  const RequestsState();

  @override
  List<Object?> get props => [];
}

class RequestsInitial extends RequestsState {
  const RequestsInitial();
}

class RequestsLoading extends RequestsState {
  const RequestsLoading();
}

class RequestsBoardLoaded extends RequestsState {
  const RequestsBoardLoaded(this.board, this.members);

  final RequestBoard board;
  final List<HouseholdMember> members;

  @override
  List<Object?> get props => [board, members];
}

class RequestsDetailLoaded extends RequestsState {
  const RequestsDetailLoaded(this.request);

  final ServiceRequest request;

  @override
  List<Object?> get props => [request];
}

class RequestsActionSuccess extends RequestsState {
  const RequestsActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class RequestsFailure extends RequestsState {
  const RequestsFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
