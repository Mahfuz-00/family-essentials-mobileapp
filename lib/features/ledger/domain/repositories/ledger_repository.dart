import '../entities/ledger.dart';
import '../entities/ledger_summary.dart';

abstract class LedgerRepository {
  Future<List<Ledger>> getLedgers();

  Future<LedgerSummary> getSummary(int ledgerId, {String periodType = 'monthly'});

  Future<List<LedgerEntry>> getEntries(int ledgerId);

  Future<Ledger> createLedger({
    required String name,
    int? monthlyBudgetMinor,
    int? weeklyBudgetMinor,
    int? yearlyBudgetMinor,
  });

  Future<Ledger> updateLedger(
    int ledgerId, {
    String? name,
    int? monthlyBudgetMinor,
    int? weeklyBudgetMinor,
    int? yearlyBudgetMinor,
  });

  Future<LedgerEntry> addEntry(
    int ledgerId, {
    required String direction,
    required int amountMinor,
    required String category,
    String? description,
    String source = 'manual',
  });
}
