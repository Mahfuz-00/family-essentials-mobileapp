import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/feedback_report.dart';
import '../../domain/repositories/feedback_repository.dart';
import '../datasources/feedback_remote_datasource.dart';
import '../models/feedback_report_model.dart';

class FeedbackRepositoryImpl implements FeedbackRepository {
  FeedbackRepositoryImpl(this._remote);

  final FeedbackRemoteDataSource _remote;

  @override
  Future<List<FeedbackReport>> reports() {
    return _guard(() async {
      final rows = await _remote.reports();

      return rows.map(FeedbackReportModel.fromJson).toList();
    });
  }

  @override
  Future<FeedbackReport> send({
    required String type,
    required String subject,
    required String body,
    String priority = 'normal',
    Map<String, String> context = const {},
  }) {
    return _guard(() async {
      final json = await _remote.send({
        'type': type,
        'priority': priority,
        'subject': subject,
        'body': body,
        'context': context,
      });

      return FeedbackReportModel.fromJson(json);
    });
  }

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
