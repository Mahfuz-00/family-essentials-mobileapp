import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:family_essentials_mobile/features/ledger/domain/entities/ledger.dart';
import 'package:family_essentials_mobile/features/ledger/domain/entities/ledger_summary.dart';
import 'package:family_essentials_mobile/features/ledger/domain/repositories/ledger_repository.dart';
import 'package:family_essentials_mobile/features/ledger/presentation/bloc/ledger_bloc.dart';
import 'package:family_essentials_mobile/features/ledger/presentation/bloc/ledger_event.dart';
import 'package:family_essentials_mobile/features/ledger/presentation/bloc/ledger_state.dart';

class MockLedgerRepository extends Mock implements LedgerRepository {}

void main() {
  late MockLedgerRepository repository;
  late LedgerBloc bloc;

  const sampleLedger = Ledger(
    id: 1,
    name: 'Household Expenses',
    currency: 'USD',
    monthlyBudgetMinor: 200000,
    weeklyBudgetMinor: 50000,
  );

  const sampleSummaryMonthly = LedgerSummary(
    incomeMinor: 300000,
    expenseMinor: 150000,
    netMinor: 150000,
    budgetMinor: 200000,
    remainingBudgetMinor: 50000,
    budgetPercentUsed: 75,
    isOverBudget: false,
    periodType: 'monthly',
  );

  const sampleSummaryWeekly = LedgerSummary(
    incomeMinor: 75000,
    expenseMinor: 60000,
    netMinor: 15000,
    budgetMinor: 50000,
    remainingBudgetMinor: -10000,
    budgetPercentUsed: 120,
    isOverBudget: true,
    periodType: 'weekly',
  );

  const sampleEntry = LedgerEntry(
    id: 10,
    ledgerId: 1,
    direction: 'out',
    amountMinor: 4500,
    category: 'grocery',
    description: 'Whole Foods Market',
  );

  setUp(() {
    repository = MockLedgerRepository();
    when(() => repository.getLedgers()).thenAnswer((_) async => [sampleLedger]);
    when(() => repository.getSummary(1, periodType: 'monthly'))
        .thenAnswer((_) async => sampleSummaryMonthly);
    when(() => repository.getSummary(1, periodType: 'weekly'))
        .thenAnswer((_) async => sampleSummaryWeekly);
    when(() => repository.getEntries(1)).thenAnswer((_) async => [sampleEntry]);

    bloc = LedgerBloc(repository);
  });

  tearDown(() {
    bloc.close();
  });

  test('loads ledgers, monthly summary, and entries on LedgerPageStarted', () async {
    final expectedStates = [
      isA<LedgerLoading>(),
      isA<LedgerLoaded>()
          .having((s) => s.activeLedger.name, 'name', 'Household Expenses')
          .having((s) => s.summary.expenseMinor, 'expense', 150000)
          .having((s) => s.summary.budgetPercentUsed, 'percentUsed', 75)
          .having((s) => s.summary.isOverBudget, 'isOverBudget', false)
          .having((s) => s.entries.length, 'entries', 1),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));

    bloc.add(const LedgerPageStarted());
  });

  test('switches to weekly ledger and reports over-budget warning', () async {
    bloc.emit(
      const LedgerLoaded(
        ledgers: [sampleLedger],
        activeLedger: sampleLedger,
        summary: sampleSummaryMonthly,
        entries: [sampleEntry],
        periodType: 'monthly',
      ),
    );

    final expectedStates = [
      isA<LedgerLoaded>()
          .having((s) => s.periodType, 'periodType', 'weekly'),
      isA<LedgerLoaded>()
          .having((s) => s.periodType, 'periodType', 'weekly')
          .having((s) => s.summary.budgetMinor, 'budgetMinor', 50000)
          .having((s) => s.summary.isOverBudget, 'isOverBudget', true)
          .having((s) => s.summary.remainingBudgetMinor, 'remaining', -10000),
    ];

    expectLater(bloc.stream, emitsInOrder(expectedStates));

    bloc.add(const LedgerPeriodChanged('weekly'));
  });

  test('updates budget caps and reloads summary', () async {
    when(
      () => repository.updateLedger(
        1,
        monthlyBudgetMinor: 250000,
        weeklyBudgetMinor: 60000,
      ),
    ).thenAnswer((_) async => sampleLedger);

    bloc.emit(
      const LedgerLoaded(
        ledgers: [sampleLedger],
        activeLedger: sampleLedger,
        summary: sampleSummaryMonthly,
        entries: [sampleEntry],
      ),
    );

    bloc.add(
      const LedgerBudgetUpdated(
        ledgerId: 1,
        monthlyBudgetMinor: 250000,
        weeklyBudgetMinor: 60000,
      ),
    );

    await Future<void>.delayed(const Duration(milliseconds: 50));
    verify(
      () => repository.updateLedger(
        1,
        monthlyBudgetMinor: 250000,
        weeklyBudgetMinor: 60000,
      ),
    ).called(1);
  });
}
