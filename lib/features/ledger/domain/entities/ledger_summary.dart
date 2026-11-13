import 'package:equatable/equatable.dart';

class LedgerCategoryTotal extends Equatable {
  const LedgerCategoryTotal({
    required this.category,
    required this.label,
    this.displayName,
    required this.expenseMinor,
    required this.share,
  });

  final String category;
  final String label;
  final String? displayName;
  final int expenseMinor;
  final double share;

  String get effectiveName => displayName ?? label;

  @override
  List<Object?> get props => [category, label, displayName, expenseMinor, share];
}

class WeeklyLedgerBucket extends Equatable {
  const WeeklyLedgerBucket({
    required this.week,
    required this.label,
    required this.expenseMinor,
    required this.incomeMinor,
  });

  final int week;
  final String label;
  final int expenseMinor;
  final int incomeMinor;

  @override
  List<Object?> get props => [week, label, expenseMinor, incomeMinor];
}

class LedgerSummary extends Equatable {
  const LedgerSummary({
    required this.incomeMinor,
    required this.expenseMinor,
    required this.netMinor,
    this.budgetMinor,
    this.remainingBudgetMinor,
    this.budgetPercentUsed = 0,
    this.isOverBudget = false,
    this.periodType = 'monthly',
    this.currency = 'USD',
    this.categories = const [],
    this.weeklyBreakdown = const [],
  });

  final int incomeMinor;
  final int expenseMinor;
  final int netMinor;
  final int? budgetMinor;
  final int? remainingBudgetMinor;
  final int budgetPercentUsed;
  final bool isOverBudget;
  final String periodType; // 'monthly' or 'weekly'
  final String currency;
  final List<LedgerCategoryTotal> categories;
  final List<WeeklyLedgerBucket> weeklyBreakdown;

  bool get hasBudget => budgetMinor != null && budgetMinor! > 0;

  @override
  List<Object?> get props => [
    incomeMinor,
    expenseMinor,
    netMinor,
    budgetMinor,
    remainingBudgetMinor,
    budgetPercentUsed,
    isOverBudget,
    periodType,
    currency,
    categories,
    weeklyBreakdown,
  ];
}
