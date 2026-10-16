import 'package:equatable/equatable.dart';

import '../../domain/entities/place.dart';

sealed class PlacesState extends Equatable {
  const PlacesState();

  @override
  List<Object?> get props => [];
}

class PlacesInitial extends PlacesState {
  const PlacesInitial();
}

class PlacesLoading extends PlacesState {
  const PlacesLoading();
}

class PlacesLoaded extends PlacesState {
  const PlacesLoaded(this.places);

  final List<Place> places;

  @override
  List<Object?> get props => [places];
}

class PlacesActionSuccess extends PlacesState {
  const PlacesActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class PlacesFailure extends PlacesState {
  const PlacesFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
