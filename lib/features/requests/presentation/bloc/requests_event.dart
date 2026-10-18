import 'package:equatable/equatable.dart';

sealed class RequestsEvent extends Equatable {
  const RequestsEvent();

  @override
  List<Object?> get props => [];
}

class BoardRequested extends RequestsEvent {
  const BoardRequested();
}

class DetailRequested extends RequestsEvent {
  const DetailRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}

class RequestSubmitted extends RequestsEvent {
  const RequestSubmitted({
    required this.title,
    this.quantity,
    this.storeName,
    this.priority = 'normal',
    this.dueAt,
    this.assigneeId,
    this.placeId,
    this.triggerPlaceId,
    this.triggerDirection,
  });

  final String title;
  final String? quantity;
  final String? storeName;
  final String priority;
  final DateTime? dueAt;
  final int? assigneeId;

  /// The shop where it will be bought, if one was chosen.
  final int? placeId;

  /// The reminder cue: which saved place, and whether arriving or leaving.
  final int? triggerPlaceId;
  final String? triggerDirection;

  @override
  List<Object?> get props => [
    title,
    quantity,
    storeName,
    priority,
    dueAt,
    assigneeId,
    placeId,
    triggerPlaceId,
    triggerDirection,
  ];
}

class ActionRequested extends RequestsEvent {
  const ActionRequested({required this.id, required this.action, this.payload});

  final int id;
  final String action;
  final Map<String, dynamic>? payload;

  @override
  List<Object?> get props => [id, action, payload];
}

class VoiceCallRequested extends RequestsEvent {
  const VoiceCallRequested(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
