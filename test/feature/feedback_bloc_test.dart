import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/error/failures.dart';
import 'package:family_essentials_mobile/features/feedback/domain/entities/feedback_report.dart';
import 'package:family_essentials_mobile/features/feedback/domain/repositories/feedback_repository.dart';
import 'package:family_essentials_mobile/features/feedback/presentation/bloc/feedback_bloc.dart';
import 'package:family_essentials_mobile/features/feedback/presentation/bloc/feedback_event.dart';
import 'package:family_essentials_mobile/features/feedback/presentation/bloc/feedback_state.dart';

class MockFeedbackRepository extends Mock implements FeedbackRepository {}

void main() {
  late MockFeedbackRepository repository;

  const report = FeedbackReport(
    id: 1,
    type: 'bug',
    status: 'in_progress',
    priority: 'high',
    subject: 'Shopping list loses items',
    body: 'Adding three items then reloading shows only two.',
  );

  setUpAll(() {
    registerFallbackValue(<String, String>{});
  });

  setUp(() => repository = MockFeedbackRepository());

  blocTest<FeedbackBloc, FeedbackState>(
    'loads what the household has already sent',
    build: () {
      when(() => repository.reports()).thenAnswer((_) async => const [report]);

      return FeedbackBloc(repository);
    },
    act: (bloc) => bloc.add(const FeedbackRequested()),
    expect: () => [
      const FeedbackLoading(),
      const FeedbackLoaded([report]),
    ],
  );

  blocTest<FeedbackBloc, FeedbackState>(
    'sending a report carries the mobile context',
    build: () {
      when(
        () => repository.send(
          type: 'bug',
          subject: 'Shopping list loses items',
          body: 'Adding three items then reloading shows only two.',
          priority: 'high',
          context: const {'platform': 'mobile'},
        ),
      ).thenAnswer((_) async => report);

      return FeedbackBloc(repository);
    },
    act: (bloc) => bloc.add(
      const FeedbackSubmitted(
        type: 'bug',
        subject: 'Shopping list loses items',
        body: 'Adding three items then reloading shows only two.',
        priority: 'high',
      ),
    ),
    expect: () => [
      const FeedbackLoading(),
      const FeedbackActionSuccess('Sent. It is in the platform team’s queue.'),
    ],
  );

  blocTest<FeedbackBloc, FeedbackState>(
    'a rejected report surfaces the reason',
    build: () {
      when(
        () => repository.send(
          type: 'bug',
          subject: 'too short',
          body: 'also far too short',
          priority: 'normal',
          context: const {'platform': 'mobile'},
        ),
      ).thenThrow(const AppFailure('Add a little more detail.'));

      return FeedbackBloc(repository);
    },
    act: (bloc) => bloc.add(
      const FeedbackSubmitted(
        type: 'bug',
        subject: 'too short',
        body: 'also far too short',
      ),
    ),
    expect: () => [
      const FeedbackLoading(),
      const FeedbackFailure('Add a little more detail.'),
    ],
  );

  test('an open report reads as open and a resolved one does not', () {
    expect(report.isOpen, isTrue);
    expect(report.statusLabel, 'In progress');
    expect(report.typeLabel, 'Something is broken');

    const closed = FeedbackReport(
      id: 2,
      type: 'feature_request',
      status: 'resolved',
      priority: 'normal',
      subject: 'Export the list',
      body: 'It would be useful to export.',
      resolutionNote: 'Shipped in 1.4.1.',
    );

    expect(closed.isOpen, isFalse);
    expect(closed.statusLabel, 'Resolved');
    expect(closed.typeLabel, 'Something is missing');
  });
}
