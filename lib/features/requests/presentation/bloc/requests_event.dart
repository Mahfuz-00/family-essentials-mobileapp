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
  });

  final String title;
  final String? quantity;
  final String? storeName;
  final String priority;
  final DateTime? dueAt;
  final int? assigneeId;

  @override
  List<Object?> get props => [
    title,
    quantity,
    storeName,
    priority,
    dueAt,
    assigneeId,
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
