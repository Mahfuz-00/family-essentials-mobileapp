import 'package:dio/dio.dart';

import '../../../../core/error/failures.dart';
import '../../domain/entities/ledger.dart';
import '../../domain/entities/ledger_summary.dart';
import '../../domain/repositories/ledger_repository.dart';
import '../datasources/ledger_remote_datasource.dart';
import '../models/ledger_model.dart';
import '../models/ledger_summary_model.dart';

class LedgerRepositoryImpl implements LedgerRepository {
  LedgerRepositoryImpl(this._remote);

  final LedgerRemoteDataSource _remote;

  @override
  Future<List<Ledger>> getLedgers() => _guard(() async {
    final list = await _remote.getLedgers();
    return list.map(LedgerModel.fromJson).toList();
  });

  @override
  Future<LedgerSummary> getSummary(int ledgerId, {String periodType = 'monthly'}) =>
      _guard(() async {
        final json = await _remote.getSummary(ledgerId, periodType: periodType);
        return LedgerSummaryModel.fromJson(json);
      });

  @override
  Future<List<LedgerEntry>> getEntries(int ledgerId, {String? from, String? to}) =>
      _guard(() async {
        final list = await _remote.getEntries(ledgerId, from: from, to: to);
        return list.map(LedgerEntryModel.fromJson).toList();
      });

  @override
  Future<Ledger> createLedger({
    required String name,
    int? monthlyBudgetMinor,
    int? weeklyBudgetMinor,
    int? yearlyBudgetMinor,
  }) => _guard(() async {
    final payload = <String, dynamic>{
      'name': name,
      'monthly_budget_minor': monthlyBudgetMinor,
      'weekly_budget_minor': weeklyBudgetMinor,
      'yearly_budget_minor': yearlyBudgetMinor,
    }..removeWhere((_, value) => value == null);
    final json = await _remote.createLedger(payload);
    return LedgerModel.fromJson(json);
  });

  @override
  Future<Ledger> updateLedger(
    int ledgerId, {
    String? name,
    int? monthlyBudgetMinor,
    int? weeklyBudgetMinor,
    int? yearlyBudgetMinor,
  }) => _guard(() async {
    final payload = <String, dynamic>{
      'name': name,
      'monthly_budget_minor': monthlyBudgetMinor,
      'weekly_budget_minor': weeklyBudgetMinor,
      'yearly_budget_minor': yearlyBudgetMinor,
    }..removeWhere((_, value) => value == null);
    final json = await _remote.updateLedger(ledgerId, payload);
    return LedgerModel.fromJson(json);
  });

  @override
  Future<LedgerEntry> addEntry(
    int ledgerId, {
    required String direction,
    required int amountMinor,
    required String category,
    String? description,
    String source = 'manual',
  }) => _guard(() async {
    final payload = <String, dynamic>{
      'direction': direction,
      'amount_minor': amountMinor,
      'category': category,
      if (description != null && description.isNotEmpty) 'description': description,
      'source': source,
    };
    final json = await _remote.addEntry(ledgerId, payload);
    return LedgerEntryModel.fromJson(json);
  });

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on DioException catch (dioError) {
      final msg = dioError.response?.data is Map
          ? (dioError.response?.data as Map)['message']?.toString()
          : null;
      throw AppFailure(msg ?? dioError.message ?? 'Server error occurred.');
    } catch (e) {
      throw AppFailure(e.toString());
    }
  }
}
