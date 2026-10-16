import 'package:equatable/equatable.dart';

sealed class PantryEvent extends Equatable {
  const PantryEvent();

  @override
  List<Object?> get props => [];
}

class PantryRequested extends PantryEvent {
  const PantryRequested({this.dueOnly = false});

  final bool dueOnly;

  @override
  List<Object?> get props => [dueOnly];
}

class EssentialCreated extends PantryEvent {
  const EssentialCreated({
    required this.name,
    this.category,
    this.defaultStore,
    this.packSize,
    this.cadenceDays = 14,
    this.threshold = 1,
    this.stockLevel = 0,
  });

  final String name;
  final String? category;
  final String? defaultStore;
  final String? packSize;
  final int cadenceDays;
  final int threshold;
  final int stockLevel;

  @override
  List<Object?> get props => [
    name,
    category,
    defaultStore,
    packSize,
    cadenceDays,
    threshold,
    stockLevel,
  ];
}

class EssentialRestocked extends PantryEvent {
  const EssentialRestocked({required this.id, this.quantity = 1});

  final int id;
  final int quantity;

  @override
  List<Object?> get props => [id, quantity];
}

class EssentialDeleted extends PantryEvent {
  const EssentialDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
