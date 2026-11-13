import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
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

  final List<Map<String, dynamic>> _recurringExpenses = [
    {
      'id': 1,
      'title': 'Home Rent / Mortgage',
      'category': 'rent',
      'amount_minor': 120000,
      'frequency': 'monthly',
      'next_due_at': '2026-12-01',
    },
    {
      'id': 2,
      'title': 'High-Speed Fiber Internet',
      'category': 'utility',
      'amount_minor': 6500,
      'frequency': 'monthly',
      'next_due_at': '2026-11-25',
    },
    {
      'id': 3,
      'title': 'Electricity & Water Utility',
      'category': 'utility',
      'amount_minor': 14500,
      'frequency': 'monthly',
      'next_due_at': '2026-11-28',
    },
  ];

  final List<Map<String, dynamic>> _memberAccess = [
    {
      'user_id': 1,
      'name': 'Tanvir Rahman',
      'role': 'Household Admin',
      'can_view': true,
      'can_record': true,
    },
    {
      'user_id': 2,
      'name': 'Sarah Rahman',
      'role': 'Household Member',
      'can_view': true,
      'can_record': true,
    },
  ];

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
                await getIt<FinancesRemoteDataSource>().createGoal({
                  'title': titleCtrl.text.trim(),
                  'target_minor': (target * 100).round(),
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Goal created!'), backgroundColor: AppTheme.secondary),
                  );
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
                  DropdownMenuItem(value: 'property', child: Text('Real Estate / Property')),
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
                  await getIt<FinancesRemoteDataSource>().createAsset({
                    'name': nameCtrl.text.trim(),
                    'type': type,
                    'value_minor': (val * 100).round(),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Asset added!'), backgroundColor: AppTheme.secondary),
                    );
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
                  DropdownMenuItem(value: 'credit_card', child: Text('Credit Card Balance')),
                  DropdownMenuItem(value: 'other', child: Text('Other Liability')),
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
                  await getIt<FinancesRemoteDataSource>().createLiability({
                    'name': nameCtrl.text.trim(),
                    'type': type,
                    'balance_minor': (val * 100).round(),
                  });
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Liability added!'), backgroundColor: AppTheme.secondary),
                    );
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
    final titleCtrl = TextEditingController();
    final amountCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Tax Assessment'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: titleCtrl,
              decoration: const InputDecoration(labelText: 'Tax Description', hintText: 'e.g. Property Tax 2026 Q1'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Estimated Amount Due (\$)', hintText: '1200.00'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              final amt = double.tryParse(amountCtrl.text.trim());
              if (titleCtrl.text.trim().isNotEmpty && amt != null) {
                await getIt<FinancesRemoteDataSource>().createTax({
                  'title': titleCtrl.text.trim(),
                  'amount_minor': (amt * 100).round(),
                  'status': 'pending',
                });
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tax assessment added!'), backgroundColor: AppTheme.secondary),
                  );
                }
              }
            },
            child: const Text('Save Tax'),
          ),
        ],
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
                            DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                            DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                            DropdownMenuItem(value: 'yearly', child: Text('Yearly')),
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
                      onPressed: () {
                        final amt = double.tryParse(amountCtrl.text.trim());
                        if (titleCtrl.text.trim().isEmpty || amt == null || amt <= 0) return;
                        setState(() {
                          _recurringExpenses.insert(0, {
                            'id': DateTime.now().millisecondsSinceEpoch,
                            'title': titleCtrl.text.trim(),
                            'category': category,
                            'amount_minor': (amt * 100).round(),
                            'frequency': frequency,
                            'next_due_at': '2026-12-01',
                          });
                        });
                        Navigator.of(ctx).pop();
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
            ('access', 'Member Access', Icons.group_outlined, _memberAccess.length),
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
                                          '${(item['frequency'] as String).toUpperCase()} · Next: ${item['next_due_at']}',
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
                                    onPressed: () {
                                      setState(() {
                                        _recurringExpenses.removeWhere((e) => e['id'] == item['id']);
                                      });
                                    },
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
                        const Text(
                          'Household Member Access',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Control which family members can view or record transactions in this ledger.',
                          style: TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                        const SizedBox(height: 12),
                        for (final member in _memberAccess)
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
                                          member['name'] as String,
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w700,
                                            color: AppTheme.ink,
                                          ),
                                        ),
                                        Text(
                                          member['role'] as String,
                                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                                        ),
                                      ],
                                    ),
                                  ),
                                  FilterChip(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    label: const Text('View', style: TextStyle(fontSize: 11)),
                                    selected: member['can_view'] == true,
                                    onSelected: (v) {
                                      setState(() => member['can_view'] = v);
                                    },
                                  ),
                                  const SizedBox(width: 6),
                                  FilterChip(
                                    visualDensity: VisualDensity.compact,
                                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                    label: const Text('Record', style: TextStyle(fontSize: 11)),
                                    selected: member['can_record'] == true,
                                    onSelected: (v) {
                                      setState(() => member['can_record'] = v);
                                    },
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
