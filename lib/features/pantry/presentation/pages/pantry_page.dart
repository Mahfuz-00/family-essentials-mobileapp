import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../domain/entities/essential.dart';
import '../bloc/pantry_bloc.dart';
import '../bloc/pantry_event.dart';
import '../bloc/pantry_state.dart';

/// M-06d / M-06e — Pantry & recurring essentials: safety-stock pulse, restock
/// actions, and the add-an-essential form.
class PantryPage extends StatelessWidget {
  const PantryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PantryBloc>()..add(const PantryRequested()),
      child: const _PantryView(),
    );
  }
}

class _PantryView extends StatelessWidget {
  const _PantryView();

  Future<void> _add(BuildContext context) async {
    final bloc = context.read<PantryBloc>();

    final created = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      builder: (_) => const _AddEssentialSheet(),
    );

    if (created == true) {
      bloc.add(const PantryRequested());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      floatingActionButton: FloatingActionButton(
        onPressed: () => _add(context),
        backgroundColor: AppTheme.secondary,
        foregroundColor: AppTheme.onSecondary,
        tooltip: 'Add a recurring essential',
        child: const Icon(Icons.add, size: 28),
      ),
      body: BlocConsumer<PantryBloc, PantryState>(
        listener: (context, state) {
          if (state is PantryActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<PantryBloc>().add(const PantryRequested());
          } else if (state is PantryFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is PantryLoading || state is PantryInitial) {
            return ListView(
              padding: const EdgeInsets.all(AppTheme.space4),
              children: const [
                ShimmerWarmCard(height: 120),
                SizedBox(height: AppTheme.space3),
                ShimmerWarmCard(height: 140),
                SizedBox(height: AppTheme.space3),
                ShimmerWarmCard(height: 140),
                SizedBox(height: AppTheme.space3),
                ShimmerWarmCard(height: 140),
              ],
            );
          }

          if (state is! PantryLoaded) {
            return const Center(child: Text('Nothing to show.'));
          }

          final snapshot = state.snapshot;

          if (snapshot.items.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(AppTheme.space4),
              child: WarmEmptyState(
                title: 'Nothing tracked yet',
                description:
                    'Add the staples you rebuy on a rhythm — milk, nappies, coffee. '
                    'The pantry then warns you before you run out.',
                icon: Icons.inventory_2_outlined,
                action: FilledButton(
                  onPressed: () => _add(context),
                  child: const Text('Add an essential'),
                ),
              ),
            );
          }

          final due = snapshot.items.where((item) => item.isDue).toList();
          final stocked = snapshot.items.where((item) => !item.isDue).toList();

          return RefreshIndicator(
            color: AppTheme.secondary,
            onRefresh: () async =>
                context.read<PantryBloc>().add(const PantryRequested()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _pulse(snapshot.summary),
                const SizedBox(height: AppTheme.space4),
                if (due.isNotEmpty) ...[
                  const Text(
                    'Needs restocking',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space3),
                  for (final item in due)
                    _EssentialCard(essential: item, actionable: true),
                  const SizedBox(height: AppTheme.space4),
                ],
                if (stocked.isNotEmpty) ...[
                  const Text(
                    'In stock',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: AppTheme.space3),
                  for (final item in stocked)
                    _EssentialCard(essential: item, actionable: false),
                ],
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _pulse(PantrySummary summary) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Pantry pulse',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              PriorityChip(
                label: summary.due == 0 ? 'All stocked' : '${summary.due} due',
                tone: summary.due == 0 ? WarmTone.success : WarmTone.danger,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(value: summary.total, label: 'Tracked'),
              StatPill(
                value: summary.safetyStock,
                label: 'Below stock',
                tone: WarmTone.danger,
              ),
              StatPill(
                value: summary.cadence,
                label: 'Due on cadence',
                tone: WarmTone.warning,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          // Spending & Restock Overview (Point 9)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.forestSoft.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Total Pantry Spend',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${((summary.totalSpentMinor) / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.secondary),
                      ),
                    ],
                  ),
                ),
                Container(width: 1, height: 28, color: AppTheme.outline.withValues(alpha: 0.2)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Restock Needed',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '\$${((summary.projectedRestockMinor) / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.ink),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _EssentialCard extends StatelessWidget {
  const _EssentialCard({required this.essential, required this.actionable});

  final Essential essential;
  final bool actionable;

  void _showRestockDialog(BuildContext context, Essential essential) {
    final qtyCtrl = TextEditingController(text: '1');
    final unitPrice = (essential.unitPriceMinor / 100);
    final spendCtrl = TextEditingController(text: unitPrice.toStringAsFixed(2));

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Restock ${essential.name}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.of(ctx).pop()),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              controller: qtyCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Quantity Restocked', prefixIcon: Icon(Icons.inventory_2_outlined)),
              onChanged: (val) {
                final q = int.tryParse(val) ?? 1;
                spendCtrl.text = (q * unitPrice).toStringAsFixed(2);
              },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: spendCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(labelText: 'Amount Spent (\$)', prefixIcon: Icon(Icons.payments_outlined)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final qty = int.tryParse(qtyCtrl.text.trim()) ?? 1;
                  final spendMinor = ((double.tryParse(spendCtrl.text.trim()) ?? 0) * 100).round();
                  Navigator.of(ctx).pop();
                  try {
                    if (getIt.isRegistered<DioClient>()) {
                      final dio = getIt<DioClient>().dio;
                      await dio.post<dynamic>(
                        '/v1/essentials/${essential.id}/restock',
                        data: {
                          'quantity_added': qty,
                          'spend_amount_minor': spendMinor,
                        },
                      );
                    }
                    if (context.mounted) {
                      context.read<PantryBloc>().add(const PantryRequested());
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Restocked ${essential.name} (Spent: \$${(spendMinor / 100).toStringAsFixed(2)})'),
                          backgroundColor: AppTheme.secondary,
                        ),
                      );
                    }
                  } catch (_) {
                    if (context.mounted) {
                      context.read<PantryBloc>().add(EssentialRestocked(id: essential.id, quantity: qty));
                    }
                  }
                },
                child: const Text('Log Restock & Record Expense'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    essential.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.ink,
                    ),
                  ),
                ),
                if (essential.isDue)
                  PriorityChip(
                    label: essential.breached ? 'Below stock' : 'Cadence due',
                    tone: essential.breached
                        ? WarmTone.danger
                        : WarmTone.warning,
                  )
                else
                  PriorityChip(label: 'In stock', tone: WarmTone.success),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              [
                if (essential.packSize != null) essential.packSize!,
                'every ${essential.cadenceDays}d',
                if (essential.defaultStore != null) essential.defaultStore!,
              ].join(' · '),
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.space3),

            // Spend & Stock Metric Container (Point 9)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outline.withValues(alpha: 0.15)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stock: ${essential.stockLevel}',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.ink),
                      ),
                      Text(
                        'Alert at ≤ ${essential.threshold}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${(essential.unitPriceMinor / 100).toStringAsFixed(2)} / unit',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.secondary),
                      ),
                      Text(
                        'Total spent: \$${(essential.totalSpentMinor / 100).toStringAsFixed(2)}',
                        style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppTheme.space3),

            // Action Buttons
            Row(
              children: [
                if (essential.isDue) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.add_shopping_cart, size: 16),
                      onPressed: () async {
                        try {
                          if (getIt.isRegistered<DioClient>()) {
                            final dio = getIt<DioClient>().dio;
                            await dio.post<dynamic>(
                              '/v1/essentials/${essential.id}/create-errand',
                            );
                          }
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Added "${essential.name}" to Household Errands!',
                                ),
                              ),
                            );
                          }
                        } catch (_) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                  'Could not create errand. Please try again.',
                                ),
                              ),
                            );
                          }
                        }
                      },
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(0, 40),
                        visualDensity: VisualDensity.compact,
                      ),
                      label: const Text('Add Errand'),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: FilledButton.tonalIcon(
                    icon: const Icon(Icons.add, size: 16),
                    onPressed: () => _showRestockDialog(context, essential),
                    style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                    label: const Text('Restock & Spend'),
                  ),
                ),
              ],
            ),
            if (essential.daysUntilDue != null && !essential.isDue) ...[
              const SizedBox(height: 6),
              Text(
                essential.daysUntilDue! <= 0
                    ? 'Due now'
                    : 'Next due in ${essential.daysUntilDue} day${essential.daysUntilDue == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.muted,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// M-06e — add a recurring essential: cadence, pack size, threshold, store.
class _AddEssentialSheet extends StatefulWidget {
  const _AddEssentialSheet();

  @override
  State<_AddEssentialSheet> createState() => _AddEssentialSheetState();
}

class _AddEssentialSheetState extends State<_AddEssentialSheet> {
  final _name = TextEditingController();
  final _store = TextEditingController();
  final _packSize = TextEditingController();
  final _unitPrice = TextEditingController(text: '3.50');

  int _cadenceDays = 14;
  int _threshold = 1;
  int _stock = 0;

  @override
  void dispose() {
    _name.dispose();
    _store.dispose();
    _packSize.dispose();
    _unitPrice.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: AppTheme.space4,
        right: AppTheme.space4,
        top: AppTheme.space4,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppTheme.space4,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.muted.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(AppTheme.radiusPill),
                ),
              ),
            ),
            const SizedBox(height: AppTheme.space4),
            const Text(
              'Add a recurring essential',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'We will nudge you before you run out.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: AppTheme.space4),

            TextField(
              controller: _name,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Item name'),
            ),
            const SizedBox(height: AppTheme.space3),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _packSize,
                    decoration: const InputDecoration(labelText: 'Pack size'),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: TextField(
                    controller: _store,
                    decoration: const InputDecoration(labelText: 'Usual store'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppTheme.space3),
            TextField(
              controller: _unitPrice,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: const InputDecoration(
                labelText: 'Estimated unit price (\$)',
                hintText: 'e.g. 3.50',
                prefixIcon: Icon(Icons.attach_money_rounded),
              ),
            ),

            const SizedBox(height: AppTheme.space4),
            _stepper(
              'Buy every',
              '$_cadenceDays days',
              () => setState(
                () => _cadenceDays = (_cadenceDays - 1).clamp(1, 365),
              ),
              () => setState(
                () => _cadenceDays = (_cadenceDays + 1).clamp(1, 365),
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            _stepper(
              'Alert when stock reaches',
              '$_threshold',
              () => setState(() => _threshold = (_threshold - 1).clamp(0, 99)),
              () => setState(() => _threshold = (_threshold + 1).clamp(0, 99)),
            ),
            const SizedBox(height: AppTheme.space2),
            _stepper(
              'In stock now',
              '$_stock',
              () => setState(() => _stock = (_stock - 1).clamp(0, 999)),
              () => setState(() => _stock = (_stock + 1).clamp(0, 999)),
            ),

            const SizedBox(height: AppTheme.space5),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(false),
                    child: const Text('Cancel'),
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: FilledButton(
                    onPressed: () async {
                      if (_name.text.trim().isEmpty) {
                        return;
                      }

                      final priceMinor = ((double.tryParse(_unitPrice.text.trim()) ?? 3.50) * 100).round();
                      try {
                        if (getIt.isRegistered<DioClient>()) {
                          final dio = getIt<DioClient>().dio;
                          await dio.post<dynamic>(
                            '/v1/essentials',
                            data: {
                              'name': _name.text.trim(),
                              'default_store': _store.text.trim().isEmpty ? null : _store.text.trim(),
                              'pack_size': _packSize.text.trim().isEmpty ? null : _packSize.text.trim(),
                              'cadence_days': _cadenceDays,
                              'threshold': _threshold,
                              'stock_level': _stock,
                              'unit_price_minor': priceMinor,
                            },
                          );
                        }
                      } catch (_) {
                        if (mounted) {
                          context.read<PantryBloc>().add(
                            EssentialCreated(
                              name: _name.text.trim(),
                              defaultStore: _store.text.trim().isEmpty
                                  ? null
                                  : _store.text.trim(),
                              packSize: _packSize.text.trim().isEmpty
                                  ? null
                                  : _packSize.text.trim(),
                              cadenceDays: _cadenceDays,
                              threshold: _threshold,
                              stockLevel: _stock,
                            ),
                          );
                        }
                      }

                      if (context.mounted) {
                        Navigator.of(context).pop(true);
                      }
                    },
                    child: const Text('Save essential'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _stepper(
    String label,
    String value,
    VoidCallback onMinus,
    VoidCallback onPlus,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space3,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppTheme.ink,
              ),
            ),
          ),
          IconButton(
            onPressed: onMinus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(Icons.remove_circle_outline, size: 20),
          ),
          Text(
            value,
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          IconButton(
            onPressed: onPlus,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.add_circle_outline,
              size: 20,
              color: AppTheme.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
