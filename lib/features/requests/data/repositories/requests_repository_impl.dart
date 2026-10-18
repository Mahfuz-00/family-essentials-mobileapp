import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/repositories/requests_repository.dart';
import '../datasources/requests_remote_datasource.dart';
import '../models/request_models.dart';

class RequestsRepositoryImpl implements RequestsRepository {
  RequestsRepositoryImpl(this._remote);

  final RequestsRemoteDataSource _remote;

  @override
  Future<RequestBoard> board() => _guard(() async {
    return RequestBoardModel.fromJson(await _remote.board());
  });

  @override
  Future<List<HouseholdMember>> members() => _guard(() async {
    return (await _remote.members())
        .map(HouseholdMemberModel.fromJson)
        .toList();
  });

  @override
  Future<ServiceRequest> find(int id) => _guard(() async {
    final data = (await _remote.find(id))['data'] as Map;

    return ServiceRequestModel.fromJson(data.cast<String, dynamic>());
  });

  @override
  Future<ServiceRequest> create({
    required String title,
    String? quantity,
    String? storeName,
    String priority = 'normal',
    DateTime? dueAt,
    int? assigneeId,
    int? placeId,
    int? triggerPlaceId,
    String? triggerDirection,
  }) {
    return _guard(() async {
      final data = await _remote.create({
        'title': title,
        'quantity': quantity,
        'store_name': storeName,
        'priority': priority,
        'due_at': dueAt?.toIso8601String(),
        'assignee_id': assigneeId,
        'place_id': placeId,
        'location_trigger_place_id': triggerPlaceId,
        'location_trigger_direction': triggerDirection,
      });

      return ServiceRequestModel.fromJson(
        (data['data'] as Map).cast<String, dynamic>(),
      );
    });
  }

  @override
  Future<ServiceRequest> updateCue({
    required int id,
    int? triggerPlaceId,
    String? triggerDirection,
  }) {
    return _guard(() async {
      final data = await _remote.update(id, {
        'location_trigger_place_id': triggerPlaceId,
        'location_trigger_direction': triggerDirection,
      });

      return ServiceRequestModel.fromJson(
        (data['data'] as Map).cast<String, dynamic>(),
      );
    });
  }

  @override
  Future<void> act(int id, String action, {Map<String, dynamic>? payload}) =>
      _guard(() => _remote.act(id, action, payload: payload));

  @override
  Future<void> triggerVoiceCall(int requestId) =>
      _guard(() => _remote.triggerVoiceCall(requestId));

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
