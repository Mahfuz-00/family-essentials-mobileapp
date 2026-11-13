import '../../domain/entities/ledger.dart';

class LedgerModel extends Ledger {
  const LedgerModel({
    required super.id,
    required super.name,
    required super.currency,
    super.monthlyBudgetMinor,
    super.weeklyBudgetMinor,
    super.yearlyBudgetMinor,
    super.isDefault,
    super.createdAt,
  });

  factory LedgerModel.fromJson(Map<String, dynamic> json) {
    return LedgerModel(
      id: json['id'] as int,
      name: json['name'] as String? ?? 'Household Ledger',
      currency: json['currency'] as String? ?? 'USD',
      monthlyBudgetMinor: (json['monthly_budget_minor'] as num?)?.toInt(),
      weeklyBudgetMinor: (json['weekly_budget_minor'] as num?)?.toInt(),
      yearlyBudgetMinor: (json['yearly_budget_minor'] as num?)?.toInt(),
      isDefault: json['is_default'] == true,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
    );
  }
}

class LedgerEntryModel extends LedgerEntry {
  const LedgerEntryModel({
    required super.id,
    required super.ledgerId,
    required super.direction,
    required super.amountMinor,
    required super.category,
    super.description,
    super.source,
    super.requestId,
    super.loggedByName,
    super.createdAt,
  });

  factory LedgerEntryModel.fromJson(Map<String, dynamic> json) {
    final loggedBy = json['logged_by'] as Map?;

    return LedgerEntryModel(
      id: json['id'] as int,
      ledgerId: (json['ledger_id'] as num?)?.toInt() ?? 0,
      direction: json['direction'] as String? ?? 'out',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      category: json['category'] as String? ?? 'other',
      description: json['description'] as String?,
      source: json['source'] as String? ?? 'manual',
      requestId: (json['request_id'] as num?)?.toInt(),
      loggedByName: loggedBy?['name'] as String?,
      createdAt: json['created_at'] is String
          ? DateTime.tryParse(json['created_at'] as String)?.toLocal()
          : null,
    );
  }
}
