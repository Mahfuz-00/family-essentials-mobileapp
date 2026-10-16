import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/features/requests/domain/repositories/requests_repository.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_bloc.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_event.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_state.dart';

class MockRequestsRepository extends Mock implements RequestsRepository {}

void main() {
  late MockRequestsRepository repository;

  setUp(() => repository = MockRequestsRepository());

  blocTest<RequestsBloc, RequestsState>(
    'triggering a voice call emits a success state',
    build: () {
      when(() => repository.triggerVoiceCall(7)).thenAnswer((_) async {});

      return RequestsBloc(repository);
    },
    act: (bloc) => bloc.add(const VoiceCallRequested(7)),
    expect: () => [
      const RequestsLoading(),
      const RequestsActionSuccess('Voice call requested.'),
    ],
    verify: (_) => verify(() => repository.triggerVoiceCall(7)).called(1),
  );
}
