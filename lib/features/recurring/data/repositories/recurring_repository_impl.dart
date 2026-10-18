import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/recurring_rule.dart';
import '../../domain/repositories/recurring_repository.dart';
import '../datasources/recurring_remote_datasource.dart';
import '../models/recurring_rule_model.dart';

class RecurringRepositoryImpl implements RecurringRepository {
  RecurringRepositoryImpl(this._remote);

  final RecurringRemoteDataSource _remote;

  @override
  Future<List<RecurringRule>> rules() => _guard(() async {
    return (await _remote.rules()).map(RecurringRuleModel.fromJson).toList();
  });

  @override
  Future<RecurringRule> create({
    required String title,
    required String cadence,
    int? weekday,
    int? dayOfMonth,
    String? quantity,
    String priority = 'normal',
    int? assigneeId,
    int? placeId,
    int? triggerPlaceId,
    String? triggerDirection,
  }) {
    return _guard(() async {
      final data = await _remote.create({
        'title': title,
        'cadence': cadence,
        // The API requires the field the cadence needs and nothing else.
        'weekday': cadence == 'weekly' ? weekday : null,
        'day_of_month': cadence == 'monthly' ? dayOfMonth : null,
        'quantity': quantity,
        'priority': priority,
        'assignee_id': assigneeId,
        'place_id': placeId,
        'location_trigger_place_id': triggerPlaceId,
        'location_trigger_direction': triggerPlaceId == null
            ? null
            : triggerDirection,
      });

      return RecurringRuleModel.fromJson(data);
    });
  }

  @override
  Future<RecurringRule> setActive({required int id, required bool active}) =>
      _guard(() async {
        return RecurringRuleModel.fromJson(
          await _remote.update(id, {'active': active}),
        );
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
