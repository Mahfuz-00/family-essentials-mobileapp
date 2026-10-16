import 'package:equatable/equatable.dart';

sealed class PlacesEvent extends Equatable {
  const PlacesEvent();

  @override
  List<Object?> get props => [];
}

class PlacesRequested extends PlacesEvent {
  const PlacesRequested();
}

class PlaceCreated extends PlacesEvent {
  const PlaceCreated({
    required this.name,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 300,
    this.category,
  });

  final String name;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final String? category;

  @override
  List<Object?> get props => [
    name,
    latitude,
    longitude,
    radiusMeters,
    category,
  ];
}

class PlaceDeleted extends PlacesEvent {
  const PlaceDeleted(this.id);

  final int id;

  @override
  List<Object?> get props => [id];
}
