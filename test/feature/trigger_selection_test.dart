import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/features/requests/domain/entities/service_request.dart';
import 'package:family_essentials_mobile/features/requests/domain/repositories/requests_repository.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_bloc.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_event.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_state.dart';

class MockRequestsRepository extends Mock implements RequestsRepository {}

void main() {
  late MockRequestsRepository repository;

  const saved = ServiceRequest(
    id: 1,
    title: 'Chips',
    status: 'pending',
    priority: 'normal',
  );

  setUp(() => repository = MockRequestsRepository());

  blocTest<RequestsBloc, RequestsState>(
    'a task carries its own reminder cue to the server',
    build: () {
      when(
        () => repository.create(
          title: 'Chips',
          quantity: null,
          storeName: null,
          priority: 'normal',
          dueAt: null,
          assigneeId: null,
          placeId: 4,
          triggerPlaceId: 2,
          triggerDirection: 'exit',
        ),
      ).thenAnswer((_) async => saved);

      return RequestsBloc(repository);
    },
    act: (bloc) => bloc.add(
      const RequestSubmitted(
        title: 'Chips',
        placeId: 4,
        triggerPlaceId: 2,
        triggerDirection: 'exit',
      ),
    ),
    expect: () => [
      const RequestsLoading(),
      const RequestsActionSuccess('Request added.'),
    ],
    verify: (_) {
      verify(
        () => repository.create(
          title: 'Chips',
          quantity: null,
          storeName: null,
          priority: 'normal',
          dueAt: null,
          assigneeId: null,
          placeId: 4,
          triggerPlaceId: 2,
          triggerDirection: 'exit',
        ),
      ).called(1);
    },
  );

  blocTest<RequestsBloc, RequestsState>(
    'a time reminder sends no location trigger at all',
    build: () {
      when(
        () => repository.create(
          title: 'Chips',
          quantity: null,
          storeName: null,
          priority: 'normal',
          dueAt: null,
          assigneeId: null,
          placeId: null,
          triggerPlaceId: null,
          triggerDirection: null,
        ),
      ).thenAnswer((_) async => saved);

      return RequestsBloc(repository);
    },
    act: (bloc) => bloc.add(const RequestSubmitted(title: 'Chips')),
    expect: () => [
      const RequestsLoading(),
      const RequestsActionSuccess('Request added.'),
    ],
  );
}
