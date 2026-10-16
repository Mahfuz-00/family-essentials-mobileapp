import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/features/places/domain/entities/place.dart';
import 'package:family_essentials_mobile/features/places/domain/repositories/places_repository.dart';
import 'package:family_essentials_mobile/features/places/presentation/bloc/places_bloc.dart';
import 'package:family_essentials_mobile/features/places/presentation/bloc/places_event.dart';
import 'package:family_essentials_mobile/features/places/presentation/bloc/places_state.dart';

class MockPlacesRepository extends Mock implements PlacesRepository {}

void main() {
  late MockPlacesRepository repository;

  const place = Place(
    id: 1,
    name: 'Whole Foods',
    latitude: 23.8103,
    longitude: 90.4125,
    radiusMeters: 300,
    category: 'grocery',
  );

  setUp(() => repository = MockPlacesRepository());

  blocTest<PlacesBloc, PlacesState>(
    'loads the household places',
    build: () {
      when(() => repository.places()).thenAnswer((_) async => const [place]);

      return PlacesBloc(repository);
    },
    act: (bloc) => bloc.add(const PlacesRequested()),
    expect: () => [
      const PlacesLoading(),
      const PlacesLoaded([place]),
    ],
  );

  blocTest<PlacesBloc, PlacesState>(
    'creating a place emits a success state',
    build: () {
      when(
        () => repository.create(
          name: 'Whole Foods',
          latitude: 23.8103,
          longitude: 90.4125,
          radiusMeters: 300,
          category: 'grocery',
        ),
      ).thenAnswer((_) async => place);

      return PlacesBloc(repository);
    },
    act: (bloc) => bloc.add(
      const PlaceCreated(
        name: 'Whole Foods',
        latitude: 23.8103,
        longitude: 90.4125,
        radiusMeters: 300,
        category: 'grocery',
      ),
    ),
    expect: () => [
      const PlacesLoading(),
      const PlacesActionSuccess('Place saved.'),
    ],
  );
}
