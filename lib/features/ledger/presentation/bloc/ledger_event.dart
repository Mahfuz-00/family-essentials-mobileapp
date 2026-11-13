import 'package:equatable/equatable.dart';

sealed class LedgerEvent extends Equatable {
  const LedgerEvent();

  @override
  List<Object?> get props => [];
}

class LedgerPageStarted extends LedgerEvent {
  const LedgerPageStarted();
}

class LedgerPeriodChanged extends LedgerEvent {
  const LedgerPeriodChanged(this.periodType);

  final String periodType; // 'monthly' or 'weekly'

  @override
  List<Object?> get props => [periodType];
}

class LedgerSelected extends LedgerEvent {
  const LedgerSelected(this.ledgerId);

  final int ledgerId;

  @override
  List<Object?> get props => [ledgerId];
}

class LedgerBudgetUpdated extends LedgerEvent {
  const LedgerBudgetUpdated({
    required this.ledgerId,
    this.monthlyBudgetMinor,
    this.weeklyBudgetMinor,
    this.yearlyBudgetMinor,
  });

  final int ledgerId;
  final int? monthlyBudgetMinor;
  final int? weeklyBudgetMinor;
  final int? yearlyBudgetMinor;

  @override
  List<Object?> get props => [
    ledgerId,
    monthlyBudgetMinor,
    weeklyBudgetMinor,
    yearlyBudgetMinor,
  ];
}

class LedgerEntryAdded extends LedgerEvent {
  const LedgerEntryAdded({
    required this.ledgerId,
    required this.direction,
    required this.amountMinor,
    required this.category,
    this.description,
  });

  final int ledgerId;
  final String direction;
  final int amountMinor;
  final String category;
  final String? description;

  @override
  List<Object?> get props => [ledgerId, direction, amountMinor, category, description];
}

class LedgerCreated extends LedgerEvent {
  const LedgerCreated({
    required this.name,
    this.monthlyBudgetMinor,
    this.weeklyBudgetMinor,
    this.yearlyBudgetMinor,
  });

  final String name;
  final int? monthlyBudgetMinor;
  final int? weeklyBudgetMinor;
  final int? yearlyBudgetMinor;

  @override
  List<Object?> get props => [
    name,
    monthlyBudgetMinor,
    weeklyBudgetMinor,
    yearlyBudgetMinor,
  ];
}
