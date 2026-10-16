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

  const request = ServiceRequest(
    id: 1,
    title: 'Milk',
    status: 'pending',
    priority: 'normal',
  );

  const board = RequestBoard(
    counts: {
      'total': 1,
      'open': 1,
      'overdue': 0,
      'due_today': 0,
      'assigned_to_me': 0,
      'backlog': 1,
      'completed_today': 0,
    },
    overdue: [],
    dueToday: [],
    assignedToMe: [request],
    backlog: [],
    completedToday: [],
  );

  const member = HouseholdMember(userId: 7, name: 'Sarah');

  setUp(() => repository = MockRequestsRepository());

  blocTest<RequestsBloc, RequestsState>(
    'loads the board and household members',
    build: () {
      when(() => repository.board()).thenAnswer((_) async => board);
      when(() => repository.members()).thenAnswer((_) async => const [member]);

      return RequestsBloc(repository);
    },
    act: (bloc) => bloc.add(const BoardRequested()),
    expect: () => [
      const RequestsLoading(),
      const RequestsBoardLoaded(board, [member]),
    ],
  );

  blocTest<RequestsBloc, RequestsState>(
    'creating a request emits a success state',
    build: () {
      when(
        () => repository.create(title: 'Milk', priority: 'normal'),
      ).thenAnswer((_) async => request);

      return RequestsBloc(repository);
    },
    act: (bloc) => bloc.add(const RequestSubmitted(title: 'Milk')),
    expect: () => [
      const RequestsLoading(),
      const RequestsActionSuccess('Request added.'),
    ],
  );

  blocTest<RequestsBloc, RequestsState>(
    'performing a request action emits a success state',
    build: () {
      when(() => repository.act(1, 'complete')).thenAnswer((_) async {});

      return RequestsBloc(repository);
    },
    act: (bloc) => bloc.add(const ActionRequested(id: 1, action: 'complete')),
    expect: () => [
      const RequestsLoading(),
      const RequestsActionSuccess('Updated.'),
    ],
  );
}
