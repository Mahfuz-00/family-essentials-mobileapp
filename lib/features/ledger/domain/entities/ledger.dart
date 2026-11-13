import 'package:equatable/equatable.dart';

class Ledger extends Equatable {
  const Ledger({
    required this.id,
    required this.name,
    required this.currency,
    this.monthlyBudgetMinor,
    this.weeklyBudgetMinor,
    this.yearlyBudgetMinor,
    this.isDefault = false,
    this.myRole,
    this.ownerId,
    this.memberCount = 0,
    this.createdAt,
  });

  final int id;
  final String name;
  final String currency;
  final int? monthlyBudgetMinor;
  final int? weeklyBudgetMinor;
  final int? yearlyBudgetMinor;
  final bool isDefault;

  /// owner | manager | summary — the caller's own membership in this ledger.
  final String? myRole;
  final int? ownerId;
  final int memberCount;
  final DateTime? createdAt;

  bool get canManageMembers => myRole == 'owner';

  @override
  List<Object?> get props => [
    id,
    name,
    currency,
    monthlyBudgetMinor,
    weeklyBudgetMinor,
    yearlyBudgetMinor,
    isDefault,
    myRole,
    ownerId,
    memberCount,
    createdAt,
  ];
}

class LedgerEntry extends Equatable {
  const LedgerEntry({
    required this.id,
    required this.ledgerId,
    required this.direction,
    required this.amountMinor,
    required this.category,
    this.description,
    this.source = 'manual',
    this.requestId,
    this.loggedByName,
    this.createdAt,
  });

  final int id;
  final int ledgerId;
  final String direction; // 'in' or 'out'
  final int amountMinor;
  final String category;
  final String? description;
  final String source; // 'manual', 'request', 'receipt', 'recurring'
  final int? requestId;
  final String? loggedByName;
  final DateTime? createdAt;

  bool get isIncome => direction == 'in';
  bool get isExpense => direction == 'out';

  @override
  List<Object?> get props => [
    id,
    ledgerId,
    direction,
    amountMinor,
    category,
    description,
    source,
    requestId,
    loggedByName,
    createdAt,
  ];
}
