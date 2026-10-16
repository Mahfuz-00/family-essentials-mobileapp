import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/core/theme/app_theme.dart';
import 'package:family_essentials_mobile/features/requests/domain/entities/service_request.dart';
import 'package:family_essentials_mobile/features/requests/domain/repositories/requests_repository.dart';
import 'package:family_essentials_mobile/features/requests/presentation/bloc/requests_bloc.dart';
import 'package:family_essentials_mobile/features/requests/presentation/pages/today_page.dart';

class MockRequestsRepository extends Mock implements RequestsRepository {}

/// Integration scope: the real task card wired to the real bloc, driving a
/// mocked data layer — the path a finger actually takes in the app.
void main() {
  late MockRequestsRepository repository;

  ServiceRequest request({
    int id = 1,
    String status = 'pending',
    String priority = 'normal',
  }) {
    return ServiceRequest(
      id: id,
      title: 'Organic Whole Milk',
      quantity: '2 litres',
      status: status,
      priority: priority,
      storeName: 'Whole Foods',
      assigneeId: 1,
      assigneeName: 'Tanvir Rahman',
    );
  }

  Widget harness(ServiceRequest item, RequestsBloc bloc) {
    return BlocProvider<RequestsBloc>.value(
      value: bloc,
      child: MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(body: TaskCard(request: item)),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(<String, dynamic>{});
    // act() takes a String action, so any() needs a String fallback.
    registerFallbackValue('');
  });

  setUp(() {
    repository = MockRequestsRepository();
  });

  testWidgets('renders the item with its quantity, store and priority',
      (tester) async {
    await tester.pumpWidget(harness(request(), RequestsBloc(repository)));

    expect(find.text('Organic Whole Milk'), findsOneWidget);
    expect(find.textContaining('2 litres'), findsWidgets);
    expect(find.textContaining('Whole Foods'), findsWidgets);
    expect(find.textContaining('Tanvir Rahman'), findsWidgets);
    expect(find.text('normal'), findsOneWidget);
  });

  testWidgets('accepts a pending item from the completion circle',
      (tester) async {
    when(() => repository.act(1, 'accept', payload: any(named: 'payload')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(harness(request(), RequestsBloc(repository)));

    await tester.tap(find.byType(InkResponse));
    await tester.pump();

    verify(() => repository.act(1, 'accept', payload: any(named: 'payload')))
        .called(1);
  });

  testWidgets('completes an accepted item from the completion circle',
      (tester) async {
    when(() => repository.act(1, 'complete', payload: any(named: 'payload')))
        .thenAnswer((_) async {});

    await tester.pumpWidget(
      harness(request(status: 'accepted'), RequestsBloc(repository)),
    );

    await tester.tap(find.byType(InkResponse));
    await tester.pump();

    verify(() => repository.act(1, 'complete', payload: any(named: 'payload')))
        .called(1);
  });

  testWidgets('shows a completed item as struck through and inert',
      (tester) async {
    await tester.pumpWidget(
      harness(request(status: 'completed'), RequestsBloc(repository)),
    );

    final titles = tester.widgetList<Text>(find.text('Organic Whole Milk'));
    expect(
      titles.any((text) => text.style?.decoration == TextDecoration.lineThrough),
      isTrue,
      reason: 'completed work is struck through',
    );

    // Inert: the completion circle carries no tap handler once done.
    final circle = tester.widget<InkResponse>(find.byType(InkResponse));
    expect(circle.onTap, isNull);
  });
}
