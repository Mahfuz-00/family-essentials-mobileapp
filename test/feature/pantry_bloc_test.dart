import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/features/pantry/domain/entities/essential.dart';
import 'package:family_essentials_mobile/features/pantry/domain/repositories/pantry_repository.dart';
import 'package:family_essentials_mobile/features/pantry/presentation/bloc/pantry_bloc.dart';
import 'package:family_essentials_mobile/features/pantry/presentation/bloc/pantry_event.dart';
import 'package:family_essentials_mobile/features/pantry/presentation/bloc/pantry_state.dart';

class MockPantryRepository extends Mock implements PantryRepository {}

void main() {
  late MockPantryRepository repository;

  const summary = PantrySummary(total: 2, due: 1, safetyStock: 1, cadence: 0);

  const milk = Essential(
    id: 1,
    name: 'Milk',
    stockLevel: 0,
    threshold: 1,
    isDue: true,
    dueReason: 'safety_stock',
  );

  const snapshot = PantrySnapshot(summary: summary, items: [milk]);

  setUp(() => repository = MockPantryRepository());

  blocTest<PantryBloc, PantryState>(
    'loads the pantry pulse and its items',
    build: () {
      when(
        () => repository.snapshot(dueOnly: false),
      ).thenAnswer((_) async => snapshot);

      return PantryBloc(repository);
    },
    act: (bloc) => bloc.add(const PantryRequested()),
    expect: () => [const PantryLoading(), const PantryLoaded(snapshot)],
  );

  blocTest<PantryBloc, PantryState>(
    'restocking an item emits a success state',
    build: () {
      when(
        () => repository.restock(id: 1, quantity: 1),
      ).thenAnswer((_) async => milk);

      return PantryBloc(repository);
    },
    act: (bloc) => bloc.add(const EssentialRestocked(id: 1)),
    expect: () => [const PantryActionSuccess('Stock topped up.')],
  );

  blocTest<PantryBloc, PantryState>(
    'adding an essential emits a success state',
    build: () {
      when(
        () => repository.create(
          name: 'Coffee',
          category: null,
          defaultStore: null,
          packSize: null,
          cadenceDays: 14,
          threshold: 1,
          stockLevel: 0,
        ),
      ).thenAnswer((_) async => milk);

      return PantryBloc(repository);
    },
    act: (bloc) => bloc.add(const EssentialCreated(name: 'Coffee')),
    expect: () => [const PantryActionSuccess('Essential added to the pantry.')],
  );

  blocTest<PantryBloc, PantryState>(
    'a due-only request is passed through to the repository',
    build: () {
      when(
        () => repository.snapshot(dueOnly: true),
      ).thenAnswer((_) async => snapshot);

      return PantryBloc(repository);
    },
    act: (bloc) => bloc.add(const PantryRequested(dueOnly: true)),
    expect: () => [const PantryLoading(), const PantryLoaded(snapshot)],
    verify: (_) => verify(() => repository.snapshot(dueOnly: true)).called(1),
  );
}
