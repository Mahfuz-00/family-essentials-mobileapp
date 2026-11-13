import 'package:equatable/equatable.dart';

import '../../domain/entities/ledger.dart';
import '../../domain/entities/ledger_summary.dart';

sealed class LedgerState extends Equatable {
  const LedgerState();

  @override
  List<Object?> get props => [];
}

class LedgerInitial extends LedgerState {
  const LedgerInitial();
}

class LedgerLoading extends LedgerState {
  const LedgerLoading();
}

class LedgerLoaded extends LedgerState {
  const LedgerLoaded({
    required this.ledgers,
    required this.activeLedger,
    required this.summary,
    required this.entries,
    this.periodType = 'monthly',
  });

  final List<Ledger> ledgers;
  final Ledger activeLedger;
  final LedgerSummary summary;
  final List<LedgerEntry> entries;
  final String periodType;

  LedgerLoaded copyWith({
    List<Ledger>? ledgers,
    Ledger? activeLedger,
    LedgerSummary? summary,
    List<LedgerEntry>? entries,
    String? periodType,
  }) {
    return LedgerLoaded(
      ledgers: ledgers ?? this.ledgers,
      activeLedger: activeLedger ?? this.activeLedger,
      summary: summary ?? this.summary,
      entries: entries ?? this.entries,
      periodType: periodType ?? this.periodType,
    );
  }

  @override
  List<Object?> get props => [ledgers, activeLedger, summary, entries, periodType];
}

class LedgerFailure extends LedgerState {
  const LedgerFailure(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}

class LedgerActionSuccess extends LedgerState {
  const LedgerActionSuccess(this.message);

  final String message;

  @override
  List<Object?> get props => [message];
}
