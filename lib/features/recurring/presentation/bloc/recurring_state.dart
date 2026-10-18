import 'package:equatable/equatable.dart';

import '../../domain/entities/recurring_rule.dart';

sealed class RecurringState extends Equatable {
  const RecurringState();

  @override
  List<Object?> get props => [];
}

class RecurringInitial extends RecurringState {
  const RecurringInitial();
}

class RecurringLoading extends RecurringState {
  const RecurringLoading();
}

class RecurringLoaded extends RecurringState {
  const RecurringLoaded(this.rules);

  final List<RecurringRule> rules;

  @override
  List<Object?> get props => [rules];
}

class RecurringActionSuccess extends RecurringState {
  const RecurringActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class RecurringFailure extends RecurringState {
  const RecurringFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
