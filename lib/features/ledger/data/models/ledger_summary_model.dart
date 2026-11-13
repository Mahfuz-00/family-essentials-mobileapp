import '../../domain/entities/ledger_summary.dart';

class LedgerCategoryTotalModel extends LedgerCategoryTotal {
  const LedgerCategoryTotalModel({
    required super.category,
    required super.label,
    super.displayName,
    required super.expenseMinor,
    required super.share,
  });

  factory LedgerCategoryTotalModel.fromJson(Map<String, dynamic> json) {
    return LedgerCategoryTotalModel(
      category: json['category'] as String? ?? 'other',
      label: json['label'] as String? ?? 'Other',
      displayName: json['display_name'] as String?,
      expenseMinor: (json['expense_minor'] as num?)?.toInt() ?? 0,
      share: (json['share'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class WeeklyLedgerBucketModel extends WeeklyLedgerBucket {
  const WeeklyLedgerBucketModel({
    required super.week,
    required super.label,
    required super.expenseMinor,
    required super.incomeMinor,
  });

  factory WeeklyLedgerBucketModel.fromJson(Map<String, dynamic> json) {
    return WeeklyLedgerBucketModel(
      week: (json['week'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? '',
      expenseMinor: (json['expense_minor'] as num?)?.toInt() ?? 0,
      incomeMinor: (json['income_minor'] as num?)?.toInt() ?? 0,
    );
  }
}

class LedgerSummaryModel extends LedgerSummary {
  const LedgerSummaryModel({
    required super.incomeMinor,
    required super.expenseMinor,
    required super.netMinor,
    super.budgetMinor,
    super.remainingBudgetMinor,
    super.budgetPercentUsed,
    super.isOverBudget,
    super.periodType,
    super.currency,
    super.categories,
    super.weeklyBreakdown,
  });

  factory LedgerSummaryModel.fromJson(Map<String, dynamic> json) {
    return LedgerSummaryModel(
      incomeMinor: (json['income_minor'] as num?)?.toInt() ?? 0,
      expenseMinor: (json['expense_minor'] as num?)?.toInt() ?? 0,
      netMinor: (json['net_minor'] as num?)?.toInt() ?? 0,
      budgetMinor: (json['budget_minor'] as num?)?.toInt(),
      remainingBudgetMinor: (json['remaining_budget_minor'] as num?)?.toInt(),
      budgetPercentUsed: (json['budget_percent_used'] as num?)?.toInt() ?? 0,
      isOverBudget: json['is_over_budget'] == true,
      periodType: json['period_type'] as String? ?? 'monthly',
      currency: json['currency'] as String? ?? 'USD',
      categories: (json['by_category'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => LedgerCategoryTotalModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      weeklyBreakdown: (json['weekly_breakdown'] as List? ?? const [])
          .whereType<Map>()
          .map((item) => WeeklyLedgerBucketModel.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
    );
  }
}
