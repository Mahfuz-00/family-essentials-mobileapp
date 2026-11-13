import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../finances/data/datasources/finances_remote_datasource.dart';
import '../../../finances/data/models/financial_models.dart';
import '../../domain/entities/ledger.dart';
import '../bloc/ledger_bloc.dart';
import '../bloc/ledger_event.dart';
import '../bloc/ledger_state.dart';

class LedgerPage extends StatelessWidget {
  const LedgerPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<LedgerBloc>()..add(const LedgerPageStarted()),
      child: const _LedgerView(),
    );
  }
}

class _LedgerView extends StatefulWidget {
  const _LedgerView();

  @override
  State<_LedgerView> createState() => _LedgerViewState();
}

class _LedgerViewState extends State<_LedgerView> {
  String _activeSubModule = 'entries';

  List<Map<String, dynamic>> _recurringExpenses = [];
  List<Map<String, dynamic>> _householdMembers = [];

  @override
  void initState() {
    super.initState();
    _loadRecurringExpenses();
    _loadHouseholdMembers();
  }

  Future<void> _loadHouseholdMembers() async {
    if (!getIt.isRegistered<DioClient>()) return;

    try {
      final response = await getIt<DioClient>().dio.get<Map<String, dynamic>>(
        '/v1/tenant/members',
      );
      final members = response.data?['data'] as List? ?? const [];

      if (mounted) {
        setState(
          () => _householdMembers = members
              .whereType<Map>()
              .map((member) => member.cast<String, dynamic>())
              .toList(),
        );
      }
    } catch (_) {}
  }

  Future<void> _grantLedgerAccess(int ledgerId, int userId, String role) async {
    try {
      await getIt<DioClient>().dio.post<Map<String, dynamic>>(
        '/v1/ledgers/$ledgerId/members',
        data: {'user_id': userId, 'role': role},
      );
      if (mounted) {
        context.read<LedgerBloc>().add(const LedgerPageStarted());
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Ledger access granted.'),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Could not grant ledger access.'),
        );
      }
    }
  }

  Future<void> _revokeLedgerAccess(int ledgerId, int userId) async {
    try {
      await getIt<DioClient>().dio.delete<void>(
        '/v1/ledgers/$ledgerId/members/$userId',
      );
      if (mounted) {
        context.read<LedgerBloc>().add(const LedgerPageStarted());
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.successSnackBar('Ledger access revoked.'),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Could not revoke ledger access.'),
        );
      }
    }
  }

  Future<void> _loadRecurringExpenses() async {
    if (!getIt.isRegistered<DioClient>()) return;

    try {
      final response = await getIt<DioClient>().dio.get<Map<String, dynamic>>(
        '/v1/recurring-rules',
      );
      final rules = response.data?['data'] as List? ?? const [];
      final expenses = rules
          .whereType<Map>()
          .map((rule) => rule.cast<String, dynamic>())
          .where(
            (rule) => ((rule['amount_minor'] as num?)?.toInt() ?? 0) > 0,
          )
          .toList();

      if (mounted) {
        setState(() => _recurringExpenses = expenses);
      }
    } catch (_) {}
  }

  Future<void> _deleteRecurringExpense(int id) async {
    try {
      await getIt<DioClient>().dio.delete<void>('/v1/recurring-rules/$id');
      await _loadRecurringExpenses();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppTheme.errorSnackBar('Could not remove that recurring expense.'),
        );
      }
    }
  }

  String _formatMoney(int minor, String currency) =>
      formatMoneyMinor(minor, currency);

  void _showAdjustBudgetSheet(BuildContext context, Ledger ledger) {
    final monthlyCtrl = TextEditingController(
      text: ledger.monthlyBudgetMinor != null
          ? (ledger.monthlyBudgetMinor! / 100).toStringAsFixed(2)
          : '',
    );
    final weeklyCtrl = TextEditingController(
      text: ledger.weeklyBudgetMinor != null
          ? (ledger.weeklyBudgetMinor! / 100).toStringAsFixed(2)
          : '',
    );
    final yearlyCtrl = TextEditingController(
      text: ledger.yearlyBudgetMinor != null
          ? (ledger.yearlyBudgetMinor! / 100).toStringAsFixed(2)
          : '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.outline.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Configure Budget Limiting',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.ink,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Set spending caps to track household expenses and receive over-budget alerts.',
                style: TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: monthlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Monthly Budget Limit (\$)',
                  hintText: 'e.g. 2000.00',
                  prefixIcon: Icon(Icons.calendar_month, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: weeklyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Weekly Budget Limit (\$)',
                  hintText: 'e.g. 500.00',
                  prefixIcon: Icon(Icons.view_week, size: 20),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: yearlyCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Yearly Budget Limit (\$)',
                  hintText: 'e.g. 24000.00',
                  prefixIcon: Icon(Icons.event_repeat, size: 20),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(ctx).pop(),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        final mVal = double.tryParse(monthlyCtrl.text.trim());
                        final wVal = double.tryParse(weeklyCtrl.text.trim());
                        final yVal = double.tryParse(yearlyCtrl.text.trim());
                        context.read<LedgerBloc>().add(
                              LedgerBudgetUpdated(
                                ledgerId: ledger.id,
                                monthlyBudgetMinor: mVal != null ? (mVal * 100).round() : null,
                                weeklyBudgetMinor: wVal != null ? (wVal * 100).round() : null,
                                yearlyBudgetMinor: yVal != null ? (yVal * 100).round() : null,
                              ),
                            );
                        Navigator.of(ctx).pop();
                      },
                      child: const Text('Save Caps'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showFinancesSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (sheetCtx, scrollCtrl) {
            return FutureBuilder<Map<String, dynamic>>(
              future: getIt<FinancesRemoteDataSource>().getOverview(),
              builder: (futureCtx, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView(
                    controller: scrollCtrl,
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                    children: const [
                      Row(
                        children: [
                          Expanded(child: ShimmerStatCard()),
                          SizedBox(width: 8),
                          Expanded(child: ShimmerStatCard()),
                          SizedBox(width: 8),
                          Expanded(child: ShimmerStatCard()),
                        ],
                      ),
                      SizedBox(height: 14),
                      ShimmerWarmCard(height: 110),
                      SizedBox(height: 12),
                      ShimmerWarmCard(height: 110),
                      SizedBox(height: 12),
                      ShimmerWarmCard(height: 110),
                    ],
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return const Center(
                    child: Text('Unable to load finances overview.', style: TextStyle(color: AppTheme.muted)),
                  );
                }

                final overview = FinancialOverviewModel.fromJson(snapshot.data!);
                final curr = overview.currency;

                return ListView(
                  controller: scrollCtrl,
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                  children: [
                    Center(
                      child: Container(
                        width: 44,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Household Wealth & Finances',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                              Text(
                                'Net worth, debt, goals, & taxes',
                                style: TextStyle(fontSize: 12, color: AppTheme.muted),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.forestSoft,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            curr,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Net Worth Banner Card
                    WarmCard(
                      borderColor: overview.netWorthMinor >= 0 ? AppTheme.secondary : AppTheme.tertiary,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'TOTAL NET WORTH',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                              color: AppTheme.muted,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _formatMoney(overview.netWorthMinor, curr),
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w900,
                              color: overview.netWorthMinor >= 0 ? AppTheme.secondary : AppTheme.tertiary,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Assets (savings & investments) minus Liabilities (mortgages & loans)',
                            style: TextStyle(fontSize: 12, color: AppTheme.muted),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // 2-Column: Assets & Liabilities
                    Row(
                      children: [
                        Expanded(
                          child: WarmCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.trending_up, size: 16, color: AppTheme.secondary),
                                    SizedBox(width: 4),
                                    Text('Total Assets', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatMoney(overview.totalAssetsMinor, curr),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.secondary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Savings: ${_formatMoney(overview.savingsMinor, curr)}\nInvestments: ${_formatMoney(overview.investmentsMinor, curr)}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: WarmCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.real_estate_agent, size: 16, color: AppTheme.tertiary),
                                    SizedBox(width: 4),
                                    Text('Liabilities', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatMoney(overview.totalLiabilitiesMinor, curr),
                                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppTheme.tertiary),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Mortgage: ${_formatMoney(overview.mortgageMinor, curr)}\nLoans: ${_formatMoney(overview.loansMinor, curr)}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Goals & Taxes Summary
                    Row(
                      children: [
                        Expanded(
                          child: WarmCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.flag, size: 16, color: AppTheme.primary),
                                    SizedBox(width: 4),
                                    Text('Goals', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '${overview.goalsActiveCount} Active',
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.ink),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'Saved: ${_formatMoney(overview.goalsTotalSavedMinor, curr)}',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: WarmCard(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.receipt_long, size: 16, color: AppTheme.tertiary),
                                    SizedBox(width: 4),
                                    Text('Upcoming Taxes', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _formatMoney(overview.taxesPendingMinor, curr),
                                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.tertiary),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${overview.taxesPendingCount} assessments due',
                                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // Quick Management Actions
                    const Text(
                      'Manage Household Assets, Debt & Goals',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        ActionChip(
                          avatar: const Icon(Icons.savings_outlined, size: 16, color: AppTheme.secondary),
                          label: const Text('+ Add Asset'),
                          onPressed: () => _showAddAssetDialog(sheetCtx),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.account_balance, size: 16, color: AppTheme.tertiary),
                          label: const Text('+ Add Loan / Mortgage'),
                          onPressed: () => _showAddLiabilityDialog(sheetCtx),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.flag_outlined, size: 16, color: AppTheme.primary),
                          label: const Text('+ Add Goal'),
                          onPressed: () => _showAddGoalDialog(sheetCtx),
                        ),
                        ActionChip(
                          avatar: const Icon(Icons.receipt_outlined, size: 16, color: AppTheme.ink),
                          label: const Text('+ Add Tax Assessment'),
                          onPressed: () => _showAddTaxDialog(sheetCtx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    _FinancesRecords(currency: curr),
                    const SizedBox(height: 24),

                    FilledButton.icon(
                      onPressed: () => Navigator.of(sheetCtx).pop(),
                      icon: const Icon(Icons.check, size: 18),
                      label: const Text('Back to Ledger'),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  void _showAddGoalDialog(BuildContext context) {
    final titleCtrl = TextEditingController();
    final targetCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Financial Goal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Goal Title', hintText: 'e.g. Emergency Fund'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: targetCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Target Amount (\$)', hintText: '5000.00'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final target = double.tryParse(targetCtrl.text.trim());
              if (titleCtrl.text.trim().isNotEmpty && target != null) {
                try {
                  await getIt<FinancesRemoteDataSource>().createGoal({
                    'name': titleCtrl.text.trim(),
                    'target_amount_minor': (target * 100).round(),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Goal created!'), backgroundColor: AppTheme.secondary),
                    );
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      AppTheme.errorSnackBar('Could not save the goal.'),
                    );
                  }
                }
              }
            },
            child: const Text('Save Goal'),
          ),
        ],
      ),
    );
  }

  void _showAddAssetDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final valueCtrl = TextEditingController();
    String type = 'savings';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Asset / Account'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Asset Name', hintText: 'e.g. High-Yield Savings'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'savings', child: Text('Savings Account')),
                  DropdownMenuItem(value: 'investment', child: Text('Investments / Stocks')),
                  DropdownMenuItem(value: 'real_estate', child: Text('Real Estate / Property')),
                  DropdownMenuItem(value: 'other', child: Text('Other Asset')),
                ],
                onChanged: (val) => setDialogState(() => type = val ?? 'savings'),
                decoration: const InputDecoration(labelText: 'Asset Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: valueCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Current Value (\$)', hintText: '10000.00'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final val = double.tryParse(valueCtrl.text.trim());
                if (nameCtrl.text.trim().isNotEmpty && val != null) {
                  try {
                    await getIt<FinancesRemoteDataSource>().createAsset({
                      'name': nameCtrl.text.trim(),
                      'type': type,
                      'balance_minor': (val * 100).round(),
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Asset added!'), backgroundColor: AppTheme.secondary),
                      );
                    }
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        AppTheme.errorSnackBar('Could not save the asset.'),
                      );
                    }
                  }
                }
              },
              child: const Text('Save Asset'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddLiabilityDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final balanceCtrl = TextEditingController();
    String type = 'loan';
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Liability / Debt'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Debt / Loan Name', hintText: 'e.g. Car Loan, Home Mortgage'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: type,
                items: const [
                  DropdownMenuItem(value: 'mortgage', child: Text('Mortgage')),
                  DropdownMenuItem(value: 'loan', child: Text('Personal / Auto Loan')),
                  DropdownMenuItem(value: 'credit_line', child: Text('Credit Line / Card')),
                  DropdownMenuItem(value: 'student_loan', child: Text('Student Loan')),
                ],
                onChanged: (val) => setDialogState(() => type = val ?? 'loan'),
                decoration: const InputDecoration(labelText: 'Liability Type'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: balanceCtrl,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Outstanding Balance (\$)', hintText: '15000.00'),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final val = double.tryParse(balanceCtrl.text.trim());
                if (nameCtrl.text.trim().isNotEmpty && val != null) {
                  try {
                    await getIt<FinancesRemoteDataSource>().createLiability({
                      'name': nameCtrl.text.trim(),
                      'type': type,
                      'remaining_balance_minor': (val * 100).round(),
                    });
                    if (ctx.mounted) Navigator.of(ctx).pop();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Liability added!'), backgroundColor: AppTheme.secondary),
                      );
                    }
                  } catch (_) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        AppTheme.errorSnackBar('Could not save the liability.'),
                      );
                    }
                  }
                }
              },
              child: const Text('Save Liability'),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddTaxDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    final yearCtrl = TextEditingController(text: '${DateTime.now().year}');
    String type = 'property';

    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Add Tax Assessment'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Tax Description',
                    hintText: 'e.g. Property Tax 2026',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: type,
                  decoration: const InputDecoration(labelText: 'Tax Type'),
                  items: const [
                    DropdownMenuItem(value: 'property', child: Text('Property')),
                    DropdownMenuItem(value: 'income', child: Text('Income')),
                    DropdownMenuItem(value: 'municipal', child: Text('Municipal')),
                    DropdownMenuItem(value: 'sales', child: Text('Sales')),
                    DropdownMenuItem(value: 'deduction', child: Text('Deduction')),
                    DropdownMenuItem(value: 'other', child: Text('Other')),
                  ],
                  onChanged: (value) =>
                      setDialogState(() => type = value ?? 'property'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: yearCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Tax year'),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: amountCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: const InputDecoration(
                    labelText: 'Estimated Amount Due (\$)',
                    hintText: '1200.00',
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final amt = double.tryParse(amountCtrl.text.trim());
                final year = int.tryParse(yearCtrl.text.trim());
                if (nameCtrl.text.trim().isEmpty ||
                    amt == null ||
                    year == null) {
                  return;
                }

                try {
                  await getIt<FinancesRemoteDataSource>().createTax({
                    'name': nameCtrl.text.trim(),
                    'type': type,
                    'tax_year': year,
                    'amount_minor': (amt * 100).round(),
                    'status': 'pending',
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Tax assessment added!'),
                        backgroundColor: AppTheme.secondary,
                      ),
                    );
                  }
                } catch (_) {
                  if (ctx.mounted) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      AppTheme.errorSnackBar('Could not save the tax assessment.'),
                    );
                  }
                }
              },
              child: const Text('Save Tax'),
            ),
          ],
        ),
      ),
    );
  }

  // ignore: unused_element
  void _showRecordEntrySheet(BuildContext context, int ledgerId) {
    String direction = 'out';
    String category = 'grocery';
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    const categories = [
      ('grocery', 'Groceries & Food', Icons.local_grocery_store),
      ('rent', 'Rent & Housing', Icons.home),
      ('utility', 'Utility & Bills', Icons.bolt),
      ('transport', 'Transport & Gas', Icons.directions_car),
      ('household', 'Household & Supplies', Icons.cleaning_services),
      ('health', 'Health & Care', Icons.medical_services),
      ('other', 'Other & Misc', Icons.category),
    ];

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppTheme.outline.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Record Household Transaction',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Add an expense (rent, utility bill, groceries) or household income.',
                      style: TextStyle(fontSize: 13, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 16),

                    // Direction toggle
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Expense (Spend)')),
                            selected: direction == 'out',
                            selectedColor: AppTheme.tertiary.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: direction == 'out' ? AppTheme.tertiary : AppTheme.outline,
                            ),
                            onSelected: (_) => setSheetState(() => direction = 'out'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: ChoiceChip(
                            label: const Center(child: Text('Income (Add)')),
                            selected: direction == 'in',
                            selectedColor: AppTheme.secondary.withValues(alpha: 0.15),
                            side: BorderSide(
                              color: direction == 'in' ? AppTheme.secondary : AppTheme.outline,
                            ),
                            onSelected: (_) => setSheetState(() => direction = 'in'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: amountCtrl,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      autofocus: true,
                      decoration: const InputDecoration(
                        labelText: 'Amount (\$)',
                        hintText: '0.00',
                        prefixIcon: Icon(Icons.attach_money, size: 20),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Category chips
                    const Text(
                      'Category',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: categories.map((cat) {
                        final isSel = category == cat.$1;
                        return ChoiceChip(
                          avatar: Icon(cat.$3, size: 14, color: isSel ? AppTheme.secondary : AppTheme.muted),
                          label: Text(cat.$2, style: const TextStyle(fontSize: 12)),
                          selected: isSel,
                          onSelected: (_) => setSheetState(() => category = cat.$1),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 14),

                    TextField(
                      controller: descCtrl,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        labelText: 'Description / Merchant / Note',
                        hintText: 'e.g. October Rent, Electric Bill, Trader Joe’s',
                      ),
                    ),
                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.of(ctx).pop(),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            onPressed: () {
                              final amt = double.tryParse(amountCtrl.text.trim());
                              if (amt == null || amt <= 0) return;
                              final minor = (amt * 100).round();

                              context.read<LedgerBloc>().add(
                                    LedgerEntryAdded(
                                      ledgerId: ledgerId,
                                      direction: direction,
                                      amountMinor: minor,
                                      category: category,
                                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                                    ),
                                  );
                              Navigator.of(ctx).pop();
                            },
                            child: const Text('Save Entry'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  List<LedgerEntry> _filterEntriesForPeriod(
    List<LedgerEntry> entries,
    String periodType,
    String? summaryFrom,
    String? summaryTo,
  ) {
    DateTime fromDate;
    DateTime toDate;
    final now = DateTime.now();

    if (summaryFrom != null &&
        summaryTo != null &&
        DateTime.tryParse(summaryFrom) != null &&
        DateTime.tryParse(summaryTo) != null) {
      final parsedFrom = DateTime.parse(summaryFrom);
      final parsedTo = DateTime.parse(summaryTo);
      fromDate = DateTime(parsedFrom.year, parsedFrom.month, parsedFrom.day);
      toDate = DateTime(parsedTo.year, parsedTo.month, parsedTo.day, 23, 59, 59);
    } else if (periodType == 'weekly') {
      final diffToMonday = now.weekday - DateTime.monday;
      final monday = now.subtract(Duration(days: diffToMonday));
      fromDate = DateTime(monday.year, monday.month, monday.day);
      final sunday = fromDate.add(const Duration(days: 6));
      toDate = DateTime(sunday.year, sunday.month, sunday.day, 23, 59, 59);
    } else if (periodType == 'yearly') {
      fromDate = DateTime(now.year, 1, 1);
      toDate = DateTime(now.year, 12, 31, 23, 59, 59);
    } else {
      fromDate = DateTime(now.year, now.month, 1);
      toDate = DateTime(now.year, now.month + 1, 0, 23, 59, 59);
    }

    return entries.where((e) {
      if (e.createdAt == null) return true;
      return !e.createdAt!.isBefore(fromDate) && !e.createdAt!.isAfter(toDate);
    }).toList();
  }

  void _showAddRecurringExpenseSheet(BuildContext context, String currency) {
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    String category = 'rent';
    String frequency = 'monthly';

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Add Recurring Expense',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'e.g. Monthly Rent, Fiber Internet',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountCtrl,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount (${currencySymbolFor(currency)})',
                      hintText: '1200.00',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: category,
                          decoration: const InputDecoration(labelText: 'Category'),
                          items: const [
                            DropdownMenuItem(value: 'rent', child: Text('Rent & Housing')),
                            DropdownMenuItem(value: 'utility', child: Text('Utility & Bills')),
                            DropdownMenuItem(value: 'grocery', child: Text('Groceries')),
                            DropdownMenuItem(value: 'household', child: Text('Household')),
                            DropdownMenuItem(value: 'other', child: Text('Other')),
                          ],
                          onChanged: (v) => setSheetState(() => category = v ?? 'rent'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          initialValue: frequency,
                          decoration: const InputDecoration(labelText: 'Frequency'),
                          items: const [
                            DropdownMenuItem(value: 'daily', child: Text('Daily')),
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                          ],
                          onChanged: (v) => setSheetState(() => frequency = v ?? 'monthly'),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () async {
                        final messenger = ScaffoldMessenger.of(context);
                        final amt = double.tryParse(amountCtrl.text.trim());
                        if (titleCtrl.text.trim().isEmpty || amt == null || amt <= 0) {
                          return;
                        }
                        if (!getIt.isRegistered<DioClient>()) {
                          messenger.showSnackBar(
                            AppTheme.errorSnackBar('Recurring rules need a connection.'),
                          );
                          return;
                        }

                        try {
                          await getIt<DioClient>().dio.post<Map<String, dynamic>>(
                            '/v1/recurring-rules',
                            data: {
                              'title': titleCtrl.text.trim(),
                              'cadence': frequency,
                              'weekday': frequency == 'weekly'
                                  ? DateTime.now().weekday % 7
                                  : null,
                              'day_of_month': frequency == 'monthly' ? 1 : null,
                              'category': category,
                              'amount_minor': (amt * 100).round(),
                              'active': true,
                            },
                          );

                          if (ctx.mounted) Navigator.of(ctx).pop();
                          await _loadRecurringExpenses();
                        } catch (_) {
                          messenger.showSnackBar(
                            AppTheme.errorSnackBar('Could not save that recurring expense.'),
                          );
                        }
                      },
                      child: const Text('Save Recurring Expense'),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: BlocConsumer<LedgerBloc, LedgerState>(
        listener: (context, state) {
          if (state is LedgerFailure) {
            ScaffoldMessenger.of(context).showSnackBar(
              AppTheme.errorSnackBar(state.message),
            );
          }
        },
        builder: (context, state) {
          if (state is LedgerLoading || state is LedgerInitial) {
            return ListView(
              padding: const EdgeInsets.all(AppTheme.space4),
              children: const [
                // 1:1 Shimmer matching Submodule Bar + This period + 3 SoftStatCards + Entries
                ShimmerWarmCard(height: 54),
                SizedBox(height: AppTheme.space3),
                ShimmerWarmCard(height: 92),
                SizedBox(height: AppTheme.space3),
                Row(
                  children: [
                    Expanded(child: ShimmerStatCard()),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerStatCard()),
                    SizedBox(width: 8),
                    Expanded(child: ShimmerStatCard()),
                  ],
                ),
                SizedBox(height: AppTheme.space4),
                ShimmerWarmCard(height: 82),
                SizedBox(height: AppTheme.space2),
                ShimmerWarmCard(height: 82),
                SizedBox(height: AppTheme.space2),
                ShimmerWarmCard(height: 82),
              ],
            );
          }

          if (state is! LedgerLoaded) {
            return const Center(child: Text('Unable to load Expenses & Money.'));
          }

          final summary = state.summary;
          final ledger = state.activeLedger;
          final currency = summary.currency;
          final isWeekly = state.periodType == 'weekly';
          final isYearly = state.periodType == 'yearly';
          final budgetMinor = summary.budgetMinor ?? 0;
          final remainingMinor = summary.remainingBudgetMinor ?? 0;
          final percentUsed = summary.budgetPercentUsed;
          final isOver = summary.isOverBudget;
          final periodEntries = _filterEntriesForPeriod(
            state.entries,
            state.periodType,
            summary.from,
            summary.to,
          );

          final subModules = <(String key, String label, IconData icon, int? count)>[
            ('entries', 'Entries & Transactions', Icons.receipt_long_rounded, null),
            ('budget', 'Budget & Limits', Icons.pie_chart_outline_rounded, null),
            ('categories', 'Category Breakdown', Icons.donut_large_rounded, null),
            ('periodic', 'Periodic Breakdown', Icons.bar_chart_rounded, null),
            ('recurring', 'Recurring Expenses', Icons.autorenew_rounded, _recurringExpenses.length),
            if (ledger.canManageMembers)
              ('access', 'Member Access', Icons.group_outlined, _householdMembers.length),
          ];

          return RefreshIndicator(
            color: AppTheme.secondary,
            onRefresh: () async {
              context.read<LedgerBloc>().add(const LedgerPageStarted());
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 100),
              children: [
                // SUBMODULE NAVIGATION BAR (flush at top over This period)
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppTheme.surface,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.85)),
                    boxShadow: AppTheme.elev1,
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final tab in subModules) ...[
                          Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: InkWell(
                              borderRadius: BorderRadius.circular(14),
                              onTap: () => setState(() => _activeSubModule = tab.$1),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 180),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: _activeSubModule == tab.$1
                                      ? AppTheme.primary
                                      : AppTheme.canvas.withValues(alpha: 0.7),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      tab.$3,
                                      size: 15,
                                      color: _activeSubModule == tab.$1
                                          ? Colors.white
                                          : AppTheme.muted,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      tab.$2,
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: _activeSubModule == tab.$1
                                            ? Colors.white
                                            : AppTheme.ink,
                                      ),
                                    ),
                                    if (tab.$4 != null) ...[
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                                        decoration: BoxDecoration(
                                          color: _activeSubModule == tab.$1
                                              ? Colors.white.withValues(alpha: 0.2)
                                              : AppTheme.forestSoft,
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        child: Text(
                                          '${tab.$4}',
                                          style: TextStyle(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: _activeSubModule == tab.$1
                                                ? Colors.white
                                                : AppTheme.secondary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppTheme.space4),

                // SUBMODULE 1: Entries & Transactions (has This period + Household Ledger Entries)
                if (_activeSubModule == 'entries') ...[
                  WarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'THIS PERIOD',
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.6,
                                      color: AppTheme.muted,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    isYearly
                                        ? 'Yearly Ledger'
                                        : isWeekly
                                            ? 'Weekly Ledger'
                                            : 'Monthly Ledger',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (summary.from != null && summary.to != null)
                              Flexible(
                                child: PriorityChip(
                                  label: '${summary.from} → ${summary.to}',
                                  tone: WarmTone.neutral,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: SegmentedButton<String>(
                            showSelectedIcon: false,
                            style: SegmentedButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            segments: const [
                              ButtonSegment(
                                value: 'monthly',
                                label: Text('Monthly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              ButtonSegment(
                                value: 'weekly',
                                label: Text('Weekly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                              ButtonSegment(
                                value: 'yearly',
                                label: Text('Yearly', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                              ),
                            ],
                            selected: {state.periodType},
                            onSelectionChanged: (val) {
                              context.read<LedgerBloc>().add(LedgerPeriodChanged(val.first));
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppTheme.space3),

                  // 3 SoftStatCards: Total Spent, Total Income, Net Outflow / Surplus
                  Row(
                    children: [
                      Expanded(
                        child: SoftStatCard(
                          label: 'Total Spent',
                          value: _formatMoney(summary.expenseMinor, currency),
                          icon: Icons.trending_down_rounded,
                          tone: WarmTone.danger,
                          badgeLabel: isYearly ? 'This Year' : isWeekly ? 'This Week' : 'This Month',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SoftStatCard(
                          label: 'Total Income',
                          value: _formatMoney(summary.incomeMinor, currency),
                          icon: Icons.trending_up_rounded,
                          tone: WarmTone.success,
                          badgeLabel: 'Inflows',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: SoftStatCard(
                          label: summary.netMinor >= 0 ? 'Net Surplus' : 'Net Outflow',
                          value: _formatMoney(summary.netMinor.abs(), currency),
                          icon: Icons.account_balance_wallet_outlined,
                          tone: summary.netMinor >= 0 ? WarmTone.success : WarmTone.warning,
                          badgeLabel: summary.netMinor >= 0 ? 'Positive' : 'Deficit',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space4),

                  // Household Ledger Entries Heading + Record Entry action
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            const Flexible(
                              child: Text(
                                'Household Ledger Entries',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            IconButton(
                              visualDensity: VisualDensity.compact,
                              tooltip: 'Finances: Net Worth, Goals, Loans & Taxes',
                              icon: const Icon(Icons.query_stats, size: 18, color: AppTheme.secondary),
                              onPressed: () => _showFinancesSheet(context),
                            ),
                          ],
                        ),
                      ),
                      FilledButton.icon(
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 34),
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          visualDensity: VisualDensity.compact,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        ),
                        onPressed: () => _showRecordEntrySheet(context, ledger.id),
                        icon: const Icon(Icons.add, size: 15),
                        label: const Text(
                          'Record Entry',
                          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppTheme.space3),

                  if (periodEntries.isEmpty) ...[
                    WarmCard(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Center(
                          child: Text(
                            'No transactions recorded for this ${state.periodType} period.\nTap "Record Entry" above to log an expense or income.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: AppTheme.muted, fontSize: 13),
                          ),
                        ),
                      ),
                    ),
                  ] else ...[
                    for (final entry in periodEntries)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppTheme.space2),
                        child: WarmCard(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 38,
                                height: 38,
                                decoration: BoxDecoration(
                                  color: entry.isIncome
                                      ? AppTheme.secondary.withValues(alpha: 0.12)
                                      : AppTheme.tertiary.withValues(alpha: 0.12),
                                  borderRadius: BorderRadius.circular(11),
                                ),
                                child: Icon(
                                  entry.isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                                  size: 18,
                                  color: entry.isIncome ? AppTheme.secondary : AppTheme.tertiary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      entry.description ?? entry.category.toUpperCase(),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w700,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Wrap(
                                      spacing: 6,
                                      children: [
                                        Text(
                                          entry.category,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                        ),
                                        if (entry.source == 'request')
                                          const Text('· from Errand', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.secondary)),
                                        if (entry.source == 'recurring')
                                          const Text('· Recurring', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.indigo)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              Text(
                                '${entry.isIncome ? "+" : "-"}${_formatMoney(entry.amountMinor, currency)}',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: entry.isIncome ? AppTheme.secondary : AppTheme.ink,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ],

                // SUBMODULE 2: Budget & Limits
                if (_activeSubModule == 'budget') ...[
                  WarmCard(
                    borderColor: isOver ? AppTheme.tertiary : null,
                    highlighted: isOver,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Row(
                                children: [
                                  Icon(
                                    isOver ? Icons.warning_amber_rounded : Icons.pie_chart_outline,
                                    size: 20,
                                    color: isOver ? AppTheme.tertiary : AppTheme.secondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '${isYearly ? "Yearly" : isWeekly ? "Weekly" : "Monthly"} Budget Limit',
                                      overflow: TextOverflow.ellipsis,
                                      style: const TextStyle(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: AppTheme.ink,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            TextButton.icon(
                              style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
                              icon: const Icon(Icons.tune, size: 15, color: AppTheme.secondary),
                              label: const Text(
                                'Adjust Limits',
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                              ),
                              onPressed: () => _showAdjustBudgetSheet(context, ledger),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (summary.hasBudget) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                _formatMoney(summary.expenseMinor, currency),
                                style: const TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w900,
                                  color: AppTheme.ink,
                                ),
                              ),
                              Text(
                                'Cap: ${_formatMoney(budgetMinor, currency)}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: (percentUsed / 100).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: AppTheme.forestSoft,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                isOver
                                    ? AppTheme.tertiary
                                    : percentUsed > 80
                                        ? Colors.amber.shade700
                                        : AppTheme.secondary,
                              ),
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              PriorityChip(
                                label: isOver
                                    ? 'Over Budget by ${_formatMoney(remainingMinor.abs(), currency)}'
                                    : '${_formatMoney(remainingMinor, currency)} remaining',
                                tone: isOver ? WarmTone.danger : WarmTone.success,
                              ),
                              Text(
                                '$percentUsed% spent',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppTheme.muted,
                                ),
                              ),
                            ],
                          ),
                        ] else ...[
                          const Text(
                            'No budget limit set for this period. Set a spending cap to receive alerts when your household is over budget.',
                            style: TextStyle(fontSize: 13, color: AppTheme.muted),
                          ),
                          const SizedBox(height: 12),
                          OutlinedButton.icon(
                            icon: const Icon(Icons.add, size: 16),
                            label: Text('Set ${isWeekly ? "Weekly" : isYearly ? "Yearly" : "Monthly"} Budget Cap'),
                            onPressed: () => _showAdjustBudgetSheet(context, ledger),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                // SUBMODULE 3: Category Breakdown
                if (_activeSubModule == 'categories') ...[
                  WarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Spending by Category',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (summary.categories.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No category spending recorded for this period yet.',
                              style: TextStyle(fontSize: 13, color: AppTheme.muted),
                            ),
                          )
                        else
                          for (final cat in summary.categories) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        cat.effectiveName,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: AppTheme.ink,
                                        ),
                                      ),
                                      Text(
                                        '${_formatMoney(cat.expenseMinor, currency)} · ${(cat.share * 100).round()}%',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  ClipRRect(
                                    borderRadius: BorderRadius.circular(4),
                                    child: LinearProgressIndicator(
                                      value: cat.share.clamp(0.0, 1.0),
                                      minHeight: 6,
                                      backgroundColor: AppTheme.forestSoft,
                                      valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ],

                // SUBMODULE 4: Periodic Breakdown
                if (_activeSubModule == 'periodic') ...[
                  WarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                isYearly
                                    ? '12-Month Annual Breakdown'
                                    : isWeekly
                                        ? '7-Day Daily Breakdown'
                                        : 'Weekly Breakdown',
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            PriorityChip(
                              label: '${summary.weeklyBreakdown.length} ${isYearly ? "months" : isWeekly ? "days" : "weeks"}',
                              tone: WarmTone.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (summary.weeklyBreakdown.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Text(
                              'No periodic breakdown data recorded yet.',
                              style: TextStyle(fontSize: 13, color: AppTheme.muted),
                            ),
                          )
                        else
                          for (final b in summary.weeklyBreakdown) ...[
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      b.label,
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.ink,
                                      ),
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        'Spent: ${_formatMoney(b.expenseMinor, currency)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.tertiary,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'In: ${_formatMoney(b.incomeMinor, currency)}',
                                        style: const TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                      ],
                    ),
                  ),
                ],

                // SUBMODULE 5: Recurring Expenses
                if (_activeSubModule == 'recurring') ...[
                  WarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Recurring Expenses',
                              style: TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: AppTheme.ink,
                              ),
                            ),
                            FilledButton.tonalIcon(
                              style: FilledButton.styleFrom(
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => _showAddRecurringExpenseSheet(context, currency),
                              icon: const Icon(Icons.add, size: 16),
                              label: const Text('Add Rule', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        if (_recurringExpenses.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              'No recurring expenses yet. Add a rule to track bills such as rent, utilities or subscriptions.',
                              style: TextStyle(fontSize: 12, color: AppTheme.muted),
                            ),
                          ),
                        for (final item in _recurringExpenses)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.canvas,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          item['title'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          '${(item['cadence'] ?? 'monthly').toString().toUpperCase()} · Next: ${item['next_run_on'] ?? '—'}',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    _formatMoney(item['amount_minor'] as int, currency),
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: AppTheme.ink,
                                    ),
                                  ),
                                  IconButton(
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.tertiary),
                                    onPressed: () => _deleteRecurringExpense(
                                      (item['id'] as num).toInt(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],

                // SUBMODULE 6: Member Access
                if (_activeSubModule == 'access') ...[
                  WarmCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Expanded(
                              child: Text(
                                'Who can see this ledger',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                            ),
                            PriorityChip(
                              label: '${ledger.memberCount} members',
                              tone: WarmTone.neutral,
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Managers record entries and see every line; totals-only members see the summary only.',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        if (_householdMembers
                            .where((member) => member['user_id'] != ledger.ownerId)
                            .isEmpty)
                          const Text(
                            'You are the only member in this household right now.',
                            style: TextStyle(fontSize: 12, color: AppTheme.muted),
                          ),
                        for (final member in _householdMembers.where(
                          (member) => member['user_id'] != ledger.ownerId,
                        ))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.canvas,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          member['name']?.toString() ?? 'Member',
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                        Text(
                                          member['role_label']?.toString() ??
                                              member['role']?.toString() ??
                                              'Member',
                                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    tooltip: 'Grant access',
                                    onSelected: (role) => _grantLedgerAccess(
                                      ledger.id,
                                      (member['user_id'] as num).toInt(),
                                      role,
                                    ),
                                    itemBuilder: (context) => const [
                                      PopupMenuItem(value: 'manager', child: Text('Manager')),
                                      PopupMenuItem(value: 'summary', child: Text('Totals only')),
                                    ],
                                    child: const Padding(
                                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                      child: Text(
                                        'Grant',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.secondary,
                                        ),
                                      ),
                                    ),
                                  ),
                                  IconButton(
                                    tooltip: 'Revoke access',
                                    visualDensity: VisualDensity.compact,
                                    icon: const Icon(
                                      Icons.person_remove_outlined,
                                      size: 18,
                                      color: AppTheme.error,
                                    ),
                                    onPressed: () => _revokeLedgerAccess(
                                      ledger.id,
                                      (member['user_id'] as num).toInt(),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Live goals, liabilities, assets and taxes inside the finances sheet — the
/// app counterpart of the dashboard's four wealth modules.
class _FinancesRecords extends StatefulWidget {
  const _FinancesRecords({required this.currency});

  final String currency;

  @override
  State<_FinancesRecords> createState() => _FinancesRecordsState();
}

class _FinancesRecordsState extends State<_FinancesRecords> {
  late final FinancesRemoteDataSource _api;

  bool _loading = true;
  List<Map<String, dynamic>> _goals = [];
  List<Map<String, dynamic>> _liabilities = [];
  List<Map<String, dynamic>> _assets = [];
  List<Map<String, dynamic>> _taxes = [];

  @override
  void initState() {
    super.initState();
    _api = getIt<FinancesRemoteDataSource>();
    _load();
  }

  Future<void> _load() async {
    try {
      final results = await Future.wait<dynamic>([
        _api.getGoals(),
        _api.getLiabilities(),
        _api.getAssets(),
        _api.getTaxes(),
      ]);

      if (!mounted) return;

      setState(() {
        _goals = results[0] as List<Map<String, dynamic>>;
        _liabilities = results[1] as List<Map<String, dynamic>>;
        _assets = results[2] as List<Map<String, dynamic>>;
        _taxes = results[3] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _section('Savings goals', _goals, _goalRow),
        _section('Loans & mortgages', _liabilities, _liabilityRow),
        _section('Assets & funds', _assets, _assetRow),
        _section('Tax assessments', _taxes, _taxRow),
      ],
    );
  }

  Widget _section(
    String title,
    List<Map<String, dynamic>> items,
    Widget Function(Map<String, dynamic>) row,
  ) {
    if (items.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          ...items.map(row),
        ],
      ),
    );
  }

  Widget _goalRow(Map<String, dynamic> goal) {
    final current = (goal['current_amount_minor'] as num?)?.toInt() ?? 0;
    final target = (goal['target_amount_minor'] as num?)?.toInt() ?? 0;

    return _recordRow(
      title: goal['name']?.toString() ?? 'Goal',
      subtitle:
          '${_money(current)} of ${_money(target)} · ${goal['status'] ?? 'active'}',
      primaryIcon: Icons.savings_outlined,
      primaryTooltip: 'Add savings',
      onPrimary: () async {
        final amount = await _promptAmount('Add savings', 'Amount');
        if (amount == null || amount <= 0) return;

        final next = current + (amount * 100).round();
        await _perform(
          () => _api.updateGoal(goal['id'] as int, {
            'current_amount_minor': next,
            if (target > 0 && next >= target) 'status': 'achieved',
          }),
          'Savings added.',
        );
      },
      onDelete: () => _delete(
        goal['name']?.toString() ?? 'Goal',
        () => _api.deleteGoal(goal['id'] as int),
      ),
    );
  }

  Widget _liabilityRow(Map<String, dynamic> liability) {
    final remaining =
        (liability['remaining_balance_minor'] as num?)?.toInt() ?? 0;

    return _recordRow(
      title: liability['name']?.toString() ?? 'Liability',
      subtitle:
          'Remaining ${_money(remaining)} · ${liability['status'] ?? 'active'}',
      primaryIcon: Icons.payments_outlined,
      primaryTooltip: 'Record payment',
      onPrimary: () async {
        final amount = await _promptAmount(
          'Record principal payment',
          'Amount',
          initial: remaining / 100,
        );
        if (amount == null || amount <= 0) return;

        final next = remaining - (amount * 100).round();
        final clamped = next < 0 ? 0 : next;
        await _perform(
          () => _api.updateLiability(liability['id'] as int, {
            'remaining_balance_minor': clamped,
            'status': clamped == 0 ? 'paid_off' : 'active',
          }),
          'Payment recorded.',
        );
      },
      onDelete: () => _delete(
        liability['name']?.toString() ?? 'Liability',
        () => _api.deleteLiability(liability['id'] as int),
      ),
    );
  }

  Widget _assetRow(Map<String, dynamic> asset) {
    final balance = (asset['balance_minor'] as num?)?.toInt() ?? 0;

    return _recordRow(
      title: asset['name']?.toString() ?? 'Asset',
      subtitle: '${asset['type'] ?? 'asset'} · ${_money(balance)}',
      primaryIcon: Icons.edit_outlined,
      primaryTooltip: 'Update balance',
      onPrimary: () async {
        final amount = await _promptAmount(
          'Update balance',
          'Balance',
          initial: balance / 100,
        );
        if (amount == null || amount < 0) return;

        await _perform(
          () => _api.updateAsset(asset['id'] as int, {
            'balance_minor': (amount * 100).round(),
          }),
          'Asset balance updated.',
        );
      },
      onDelete: () => _delete(
        asset['name']?.toString() ?? 'Asset',
        () => _api.deleteAsset(asset['id'] as int),
      ),
    );
  }

  Widget _taxRow(Map<String, dynamic> tax) {
    final amount = (tax['amount_minor'] as num?)?.toInt() ?? 0;
    final paid = tax['status'] == 'paid';

    return _recordRow(
      title: tax['name']?.toString() ?? 'Tax assessment',
      subtitle:
          '${tax['type'] ?? 'tax'} ${tax['tax_year'] ?? ''} · ${_money(amount)} · ${tax['status'] ?? 'pending'}',
      primaryIcon: paid ? Icons.check_circle_outline : Icons.check_circle,
      primaryTooltip: paid ? 'Already paid' : 'Mark paid',
      onPrimary: paid
          ? null
          : () => _perform(
                () => _api.updateTax(tax['id'] as int, {'status': 'paid'}),
                'Tax marked paid.',
              ),
      onDelete: () => _delete(
        tax['name']?.toString() ?? 'Tax assessment',
        () => _api.deleteTax(tax['id'] as int),
      ),
    );
  }

  Widget _recordRow({
    required String title,
    required String subtitle,
    required IconData primaryIcon,
    required String primaryTooltip,
    required Future<void> Function()? onPrimary,
    required Future<void> Function() onDelete,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: primaryTooltip,
            visualDensity: VisualDensity.compact,
            icon: Icon(primaryIcon, size: 18, color: AppTheme.secondary),
            onPressed: onPrimary == null ? null : () => onPrimary(),
          ),
          IconButton(
            tooltip: 'Delete',
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline,
              size: 18,
              color: AppTheme.error,
            ),
            onPressed: () => onDelete(),
          ),
        ],
      ),
    );
  }

  Future<void> _perform(Future<void> Function() action, String success) async {
    try {
      await action();
      await _load();
      _snack(success);
    } catch (_) {
      _snack('Could not update your finances.', error: true);
    }
  }

  Future<void> _delete(String label, Future<void> Function() action) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Delete $label?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await _perform(action, '$label removed.');
  }

  Future<double?> _promptAmount(
    String title,
    String label, {
    double? initial,
  }) async {
    final controller = TextEditingController(
      text: initial == null ? '' : initial.toStringAsFixed(2),
    );

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
          decoration: InputDecoration(
            labelText: '$label (${widget.currency})',
            prefixIcon: const Icon(Icons.attach_money, size: 20),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.of(ctx).pop(double.tryParse(controller.text.trim())),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();

    return result;
  }

  String _money(int minor) => formatMoneyMinor(minor, widget.currency);

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      error ? AppTheme.errorSnackBar(message) : AppTheme.successSnackBar(message),
    );
  }
}
