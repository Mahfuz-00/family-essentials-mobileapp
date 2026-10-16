import 'package:equatable/equatable.dart';

import '../../domain/entities/essential.dart';

sealed class PantryState extends Equatable {
  const PantryState();

  @override
  List<Object?> get props => [];
}

class PantryInitial extends PantryState {
  const PantryInitial();
}

class PantryLoading extends PantryState {
  const PantryLoading();
}

class PantryLoaded extends PantryState {
  const PantryLoaded(this.snapshot);

  final PantrySnapshot snapshot;

  @override
  List<Object?> get props => [snapshot];
}

class PantryActionSuccess extends PantryState {
  const PantryActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PantryFailure extends PantryState {
  const PantryFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
