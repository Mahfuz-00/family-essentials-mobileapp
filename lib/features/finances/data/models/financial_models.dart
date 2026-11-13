class FinancialOverviewModel {
  const FinancialOverviewModel({
    required this.currency,
    required this.totalAssetsMinor,
    required this.totalLiabilitiesMinor,
    required this.netWorthMinor,
    required this.savingsMinor,
    required this.investmentsMinor,
    required this.mortgageMinor,
    required this.loansMinor,
    required this.goalsActiveCount,
    required this.goalsAchievedCount,
    required this.goalsTotalSavedMinor,
    required this.goalsTotalTargetMinor,
    required this.taxesPendingCount,
    required this.taxesPendingMinor,
  });

  final String currency;
  final int totalAssetsMinor;
  final int totalLiabilitiesMinor;
  final int netWorthMinor;
  final int savingsMinor;
  final int investmentsMinor;
  final int mortgageMinor;
  final int loansMinor;
  final int goalsActiveCount;
  final int goalsAchievedCount;
  final int goalsTotalSavedMinor;
  final int goalsTotalTargetMinor;
  final int taxesPendingCount;
  final int taxesPendingMinor;

  factory FinancialOverviewModel.fromJson(Map<String, dynamic> json) {
    final goals = json['goals'] as Map<String, dynamic>? ?? {};
    final taxes = json['taxes'] as Map<String, dynamic>? ?? {};

    return FinancialOverviewModel(
      currency: json['currency'] as String? ?? 'USD',
      totalAssetsMinor: (json['total_assets_minor'] as num?)?.toInt() ?? 0,
      totalLiabilitiesMinor: (json['total_liabilities_minor'] as num?)?.toInt() ?? 0,
      netWorthMinor: (json['net_worth_minor'] as num?)?.toInt() ?? 0,
      savingsMinor: (json['savings_minor'] as num?)?.toInt() ?? 0,
      investmentsMinor: (json['investments_minor'] as num?)?.toInt() ?? 0,
      mortgageMinor: (json['mortgage_minor'] as num?)?.toInt() ?? 0,
      loansMinor: (json['loans_minor'] as num?)?.toInt() ?? 0,
      goalsActiveCount: (goals['active_count'] as num?)?.toInt() ?? 0,
      goalsAchievedCount: (goals['achieved_count'] as num?)?.toInt() ?? 0,
      goalsTotalSavedMinor: (goals['total_saved_minor'] as num?)?.toInt() ?? 0,
      goalsTotalTargetMinor: (goals['total_target_minor'] as num?)?.toInt() ?? 0,
      taxesPendingCount: (taxes['pending_count'] as num?)?.toInt() ?? 0,
      taxesPendingMinor: (taxes['pending_minor'] as num?)?.toInt() ?? 0,
    );
  }
}

class FinancialGoalModel {
  const FinancialGoalModel({
    required this.id,
    required this.name,
    this.category,
    required this.targetAmountMinor,
    required this.currentAmountMinor,
    required this.progressPercent,
    required this.currency,
    this.targetDate,
    required this.status,
    this.notes,
  });

  final int id;
  final String name;
  final String? category;
  final int targetAmountMinor;
  final int currentAmountMinor;
  final double progressPercent;
  final String currency;
  final String? targetDate;
  final String status;
  final String? notes;

  factory FinancialGoalModel.fromJson(Map<String, dynamic> json) {
    return FinancialGoalModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      category: json['category'] as String?,
      targetAmountMinor: (json['target_amount_minor'] as num?)?.toInt() ?? 0,
      currentAmountMinor: (json['current_amount_minor'] as num?)?.toInt() ?? 0,
      progressPercent: (json['progress_percent'] as num?)?.toDouble() ?? 0.0,
      currency: json['currency'] as String? ?? 'USD',
      targetDate: json['target_date'] as String?,
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
    );
  }
}

class FinancialLiabilityModel {
  const FinancialLiabilityModel({
    required this.id,
    required this.name,
    required this.type,
    this.lender,
    required this.principalAmountMinor,
    required this.remainingBalanceMinor,
    this.monthlyPaymentMinor,
    this.interestRateBps,
    this.interestRatePercent,
    required this.payoffPercent,
    this.dueDayOfMonth,
    required this.currency,
    required this.status,
    this.notes,
  });

  final int id;
  final String name;
  final String type;
  final String? lender;
  final int principalAmountMinor;
  final int remainingBalanceMinor;
  final int? monthlyPaymentMinor;
  final int? interestRateBps;
  final double? interestRatePercent;
  final double payoffPercent;
  final int? dueDayOfMonth;
  final String currency;
  final String status;
  final String? notes;

  factory FinancialLiabilityModel.fromJson(Map<String, dynamic> json) {
    return FinancialLiabilityModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'mortgage',
      lender: json['lender'] as String?,
      principalAmountMinor: (json['principal_amount_minor'] as num?)?.toInt() ?? 0,
      remainingBalanceMinor: (json['remaining_balance_minor'] as num?)?.toInt() ?? 0,
      monthlyPaymentMinor: (json['monthly_payment_minor'] as num?)?.toInt(),
      interestRateBps: (json['interest_rate_bps'] as num?)?.toInt(),
      interestRatePercent: (json['interest_rate_percent'] as num?)?.toDouble(),
      payoffPercent: (json['payoff_percent'] as num?)?.toDouble() ?? 0.0,
      dueDayOfMonth: (json['due_day_of_month'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'USD',
      status: json['status'] as String? ?? 'active',
      notes: json['notes'] as String?,
    );
  }
}

class FinancialAssetModel {
  const FinancialAssetModel({
    required this.id,
    required this.name,
    required this.type,
    this.institution,
    required this.balanceMinor,
    this.contributionMonthlyMinor,
    this.returnRateBps,
    this.returnRatePercent,
    required this.currency,
    this.notes,
  });

  final int id;
  final String name;
  final String type;
  final String? institution;
  final int balanceMinor;
  final int? contributionMonthlyMinor;
  final int? returnRateBps;
  final double? returnRatePercent;
  final String currency;
  final String? notes;

  factory FinancialAssetModel.fromJson(Map<String, dynamic> json) {
    return FinancialAssetModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'savings',
      institution: json['institution'] as String?,
      balanceMinor: (json['balance_minor'] as num?)?.toInt() ?? 0,
      contributionMonthlyMinor: (json['contribution_monthly_minor'] as num?)?.toInt(),
      returnRateBps: (json['return_rate_bps'] as num?)?.toInt(),
      returnRatePercent: (json['return_rate_percent'] as num?)?.toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      notes: json['notes'] as String?,
    );
  }
}

class FinancialTaxModel {
  const FinancialTaxModel({
    required this.id,
    required this.name,
    required this.type,
    required this.taxYear,
    required this.amountMinor,
    required this.dueDate,
    required this.status,
    this.paidAt,
    required this.currency,
    this.authority,
    this.notes,
  });

  final int id;
  final String name;
  final String type;
  final int taxYear;
  final int amountMinor;
  final String dueDate;
  final String status;
  final String? paidAt;
  final String currency;
  final String? authority;
  final String? notes;

  factory FinancialTaxModel.fromJson(Map<String, dynamic> json) {
    return FinancialTaxModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? '',
      type: json['type'] as String? ?? 'property',
      taxYear: (json['tax_year'] as num?)?.toInt() ?? DateTime.now().year,
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      dueDate: json['due_date'] as String? ?? '',
      status: json['status'] as String? ?? 'pending',
      paidAt: json['paid_at'] as String?,
      currency: json['currency'] as String? ?? 'USD',
      authority: json['authority'] as String?,
      notes: json['notes'] as String?,
    );
  }
}
