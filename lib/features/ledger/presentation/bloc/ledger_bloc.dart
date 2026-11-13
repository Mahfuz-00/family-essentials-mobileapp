import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/error/failures.dart';
import '../../domain/repositories/ledger_repository.dart';
import 'ledger_event.dart';
import 'ledger_state.dart';

class LedgerBloc extends Bloc<LedgerEvent, LedgerState> {
  LedgerBloc(this._repository) : super(const LedgerInitial()) {
    on<LedgerPageStarted>(_onStarted);
    on<LedgerPeriodChanged>(_onPeriodChanged);
    on<LedgerSelected>(_onLedgerSelected);
    on<LedgerBudgetUpdated>(_onBudgetUpdated);
    on<LedgerEntryAdded>(_onEntryAdded);
    on<LedgerCreated>(_onLedgerCreated);
  }

  final LedgerRepository _repository;

  Future<void> _onStarted(
    LedgerPageStarted event,
    Emitter<LedgerState> emit,
  ) async {
    emit(const LedgerLoading());
    await _loadData(emit, periodType: 'monthly');
  }

  Future<void> _onPeriodChanged(
    LedgerPeriodChanged event,
    Emitter<LedgerState> emit,
  ) async {
    if (state is! LedgerLoaded) return;
    final current = state as LedgerLoaded;
    if (current.periodType == event.periodType) return;

    // Immediately update periodType for instant UI response
    emit(current.copyWith(periodType: event.periodType));

    try {
      final summary = await _repository.getSummary(
        current.activeLedger.id,
        periodType: event.periodType,
      );
      final entries = await _repository.getEntries(
        current.activeLedger.id,
        from: summary.from,
        to: summary.to,
      );
      if (state is LedgerLoaded && (state as LedgerLoaded).periodType == event.periodType) {
        emit((state as LedgerLoaded).copyWith(summary: summary, entries: entries));
      }
    } on AppFailure catch (failure) {
      emit(LedgerFailure(failure.message));
    } catch (e) {
      emit(LedgerFailure(e.toString()));
    }
  }

  Future<void> _onLedgerSelected(
    LedgerSelected event,
    Emitter<LedgerState> emit,
  ) async {
    final period = state is LedgerLoaded ? (state as LedgerLoaded).periodType : 'monthly';
    emit(const LedgerLoading());
    await _loadData(emit, selectedLedgerId: event.ledgerId, periodType: period);
  }

  Future<void> _onBudgetUpdated(
    LedgerBudgetUpdated event,
    Emitter<LedgerState> emit,
  ) async {
    final period = state is LedgerLoaded ? (state as LedgerLoaded).periodType : 'monthly';
    try {
      await _repository.updateLedger(
        event.ledgerId,
        monthlyBudgetMinor: event.monthlyBudgetMinor,
        weeklyBudgetMinor: event.weeklyBudgetMinor,
        yearlyBudgetMinor: event.yearlyBudgetMinor,
      );
      await _loadData(emit, selectedLedgerId: event.ledgerId, periodType: period);
    } on AppFailure catch (failure) {
      emit(LedgerFailure(failure.message));
    } catch (e) {
      emit(LedgerFailure(e.toString()));
    }
  }

  Future<void> _onEntryAdded(
    LedgerEntryAdded event,
    Emitter<LedgerState> emit,
  ) async {
    final period = state is LedgerLoaded ? (state as LedgerLoaded).periodType : 'monthly';
    try {
      await _repository.addEntry(
        event.ledgerId,
        direction: event.direction,
        amountMinor: event.amountMinor,
        category: event.category,
        description: event.description,
      );
      await _loadData(emit, selectedLedgerId: event.ledgerId, periodType: period);
    } on AppFailure catch (failure) {
      emit(LedgerFailure(failure.message));
    } catch (e) {
      emit(LedgerFailure(e.toString()));
    }
  }

  Future<void> _onLedgerCreated(
    LedgerCreated event,
    Emitter<LedgerState> emit,
  ) async {
    emit(const LedgerLoading());
    try {
      final created = await _repository.createLedger(
        name: event.name,
        monthlyBudgetMinor: event.monthlyBudgetMinor,
        weeklyBudgetMinor: event.weeklyBudgetMinor,
        yearlyBudgetMinor: event.yearlyBudgetMinor,
      );
      await _loadData(emit, selectedLedgerId: created.id, periodType: 'monthly');
    } on AppFailure catch (failure) {
      emit(LedgerFailure(failure.message));
    } catch (e) {
      emit(LedgerFailure(e.toString()));
    }
  }

  Future<void> _loadData(
    Emitter<LedgerState> emit, {
    int? selectedLedgerId,
    required String periodType,
  }) async {
    try {
      var ledgers = await _repository.getLedgers();
      if (ledgers.isEmpty) {
        // Auto-create default household ledger if none exists
        final defaultLedger = await _repository.createLedger(
          name: 'Household Expenses',
          monthlyBudgetMinor: 200000,
          weeklyBudgetMinor: 50000,
        );
        ledgers = [defaultLedger];
      }

      final active = selectedLedgerId != null
          ? (ledgers.where((l) => l.id == selectedLedgerId).firstOrNull ?? ledgers.first)
          : ledgers.first;

      final summary = await _repository.getSummary(active.id, periodType: periodType);
      final entries = await _repository.getEntries(
        active.id,
        from: summary.from,
        to: summary.to,
      );

      emit(
        LedgerLoaded(
          ledgers: ledgers,
          activeLedger: active,
          summary: summary,
          entries: entries,
          periodType: periodType,
        ),
      );
    } on AppFailure catch (failure) {
      emit(LedgerFailure(failure.message));
    } catch (e) {
      emit(LedgerFailure(e.toString()));
    }
  }
}
