import '../../domain/entities/essential.dart';

class EssentialModel extends Essential {
  const EssentialModel({
    required super.id,
    required super.name,
    super.category,
    super.defaultStore,
    super.packSize,
    super.cadenceDays,
    super.threshold,
    super.stockLevel,
    super.isActive,
    super.lastRestockedAt,
    super.nextDueAt,
    super.daysUntilDue,
    super.isDue,
    super.dueReason,
  });

  factory EssentialModel.fromJson(Map<String, dynamic> json) {
    return EssentialModel(
      id: json['id'] as int,
      name: json['name'] as String,
      category: json['category'] as String?,
      defaultStore: json['default_store'] as String?,
      packSize: json['pack_size'] as String?,
      cadenceDays: (json['cadence_days'] as num?)?.toInt() ?? 14,
      threshold: (json['threshold'] as num?)?.toInt() ?? 1,
      stockLevel: (json['stock_level'] as num?)?.toInt() ?? 0,
      isActive: json['is_active'] as bool? ?? true,
      lastRestockedAt: _date(json['last_restocked_at']),
      nextDueAt: _date(json['next_due_at']),
      daysUntilDue: (json['days_until_due'] as num?)?.toInt(),
      isDue: json['is_due'] as bool? ?? false,
      dueReason: json['due_reason'] as String?,
    );
  }

  static DateTime? _date(Object? value) =>
      value is String ? DateTime.tryParse(value) : null;
}

class PantrySnapshotModel extends PantrySnapshot {
  const PantrySnapshotModel({required super.summary, required super.items});

  factory PantrySnapshotModel.fromJson(Map<String, dynamic> json) {
    final summary =
        (json['summary'] as Map?)?.cast<String, dynamic>() ?? const {};

    return PantrySnapshotModel(
      summary: PantrySummary(
        total: (summary['total'] as num?)?.toInt() ?? 0,
        due: (summary['due'] as num?)?.toInt() ?? 0,
        safetyStock: (summary['safety_stock'] as num?)?.toInt() ?? 0,
        cadence: (summary['cadence'] as num?)?.toInt() ?? 0,
      ),
      items: (json['data'] as List? ?? const [])
          .cast<Map<String, dynamic>>()
          .map(EssentialModel.fromJson)
          .toList(),
    );
  }
}
