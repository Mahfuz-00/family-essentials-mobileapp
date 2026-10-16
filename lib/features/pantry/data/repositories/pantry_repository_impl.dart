import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/essential.dart';
import '../../domain/repositories/pantry_repository.dart';
import '../datasources/pantry_remote_datasource.dart';
import '../models/essential_model.dart';

class PantryRepositoryImpl implements PantryRepository {
  PantryRepositoryImpl(this._remote);

  final PantryRemoteDataSource _remote;

  @override
  Future<PantrySnapshot> snapshot({bool dueOnly = false}) => _guard(() async {
    return PantrySnapshotModel.fromJson(
      await _remote.snapshot(dueOnly: dueOnly),
    );
  });

  @override
  Future<Essential> create({
    required String name,
    String? category,
    String? defaultStore,
    String? packSize,
    int cadenceDays = 14,
    int threshold = 1,
    int stockLevel = 0,
  }) {
    return _guard(() async {
      final data = await _remote.create({
        'name': name,
        'category': category,
        'default_store': defaultStore,
        'pack_size': packSize,
        'cadence_days': cadenceDays,
        'threshold': threshold,
        'stock_level': stockLevel,
      });

      return EssentialModel.fromJson(data);
    });
  }

  @override
  Future<Essential> restock({required int id, required int quantity}) =>
      _guard(() async {
        return EssentialModel.fromJson(await _remote.restock(id, quantity));
      });

  @override
  Future<void> remove(int id) => _guard(() => _remote.remove(id));

  Future<T> _guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } on DioException catch (error) {
      throw AppFailure(_messageFrom(error));
    }
  }

  String _messageFrom(DioException error) {
    final data = error.response?.data;

    if (data is Map) {
      final errors = data['errors'];

      if (errors is Map && errors.isNotEmpty) {
        final first = errors.values.first;

        if (first is List && first.isNotEmpty) {
          return first.first.toString();
        }
      }

      if (data['message'] is String) {
        return data['message'] as String;
      }
    }

    return 'Something went wrong. Please try again.';
  }
}
