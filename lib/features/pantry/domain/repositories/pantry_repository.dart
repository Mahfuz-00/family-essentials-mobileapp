import '../entities/essential.dart';

abstract class PantryRepository {
  Future<PantrySnapshot> snapshot({bool dueOnly = false});

  Future<Essential> create({
    required String name,
    String? category,
    String? defaultStore,
    String? packSize,
    int cadenceDays = 14,
    int threshold = 1,
    int stockLevel = 0,
  });

  Future<Essential> restock({required int id, required int quantity});

  Future<void> remove(int id);
}
