import 'package:equatable/equatable.dart';

/// A recurring household essential with a restock cadence and a safety stock.
///
/// `isDue` mirrors the server rule: due when stock has fallen to or below the
/// threshold (safety stock), or when the cadence has elapsed since the last
/// restock.
class Essential extends Equatable {
  const Essential({
    required this.id,
    required this.name,
    this.category,
    this.defaultStore,
    this.packSize,
    this.cadenceDays = 14,
    this.threshold = 1,
    this.stockLevel = 0,
    this.isActive = true,
    this.lastRestockedAt,
    this.nextDueAt,
    this.daysUntilDue,
    this.isDue = false,
    this.dueReason,
    this.unitPriceMinor = 350,
    this.lastSpentMinor = 0,
    this.totalSpentMinor = 0,
    this.projectedRestockMinor = 0,
  });

  final int id;
  final String name;
  final String? category;
  final String? defaultStore;
  final String? packSize;
  final int cadenceDays;
  final int threshold;
  final int stockLevel;
  final bool isActive;
  final DateTime? lastRestockedAt;
  final DateTime? nextDueAt;
  final int? daysUntilDue;
  final bool isDue;
  final int unitPriceMinor;
  final int lastSpentMinor;
  final int totalSpentMinor;
  final int projectedRestockMinor;

  /// 'safety_stock' or 'cadence' when due, otherwise null.
  final String? dueReason;

  bool get breached => dueReason == 'safety_stock';

  @override
  List<Object?> get props => [
    id,
    name,
    category,
    defaultStore,
    packSize,
    cadenceDays,
    threshold,
    stockLevel,
    isActive,
    lastRestockedAt,
    nextDueAt,
    daysUntilDue,
    isDue,
    dueReason,
    unitPriceMinor,
    lastSpentMinor,
    totalSpentMinor,
    projectedRestockMinor,
  ];
}

/// Pantry-wide pulse numbers, computed server-side across the whole pantry.
class PantrySummary extends Equatable {
  const PantrySummary({
    this.total = 0,
    this.due = 0,
    this.safetyStock = 0,
    this.cadence = 0,
    this.totalSpentMinor = 0,
    this.projectedRestockMinor = 0,
  });

  final int total;
  final int due;
  final int safetyStock;
  final int cadence;
  final int totalSpentMinor;
  final int projectedRestockMinor;

  @override
  List<Object?> get props => [
        total,
        due,
        safetyStock,
        cadence,
        totalSpentMinor,
        projectedRestockMinor,
      ];
}

class PantrySnapshot extends Equatable {
  const PantrySnapshot({required this.summary, required this.items});

  final PantrySummary summary;
  final List<Essential> items;

  @override
  List<Object?> get props => [summary, items];
}
