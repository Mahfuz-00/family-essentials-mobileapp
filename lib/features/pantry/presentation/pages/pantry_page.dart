import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
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
      appBar: AppBar(
        title: const Text('Pantry & essentials'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<PantryBloc>().add(const PantryRequested()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
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
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondary),
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
        ],
      ),
    );
  }
}

class _EssentialCard extends StatelessWidget {
  const _EssentialCard({required this.essential, required this.actionable});

  final Essential essential;
  final bool actionable;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<PantryBloc>();

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
                      fontSize: 15,
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
            Row(
              children: [
                Text(
                  'Stock ${essential.stockLevel} · alert at ${essential.threshold}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppTheme.onSurfaceVariant,
                  ),
                ),
                const Spacer(),
                FilledButton.tonal(
                  onPressed: () => bloc.add(
                    EssentialRestocked(id: essential.id, quantity: 1),
                  ),
                  style: FilledButton.styleFrom(minimumSize: const Size(0, 40)),
                  child: const Text('+ Restock'),
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

  int _cadenceDays = 14;
  int _threshold = 1;
  int _stock = 0;

  @override
  void dispose() {
    _name.dispose();
    _store.dispose();
    _packSize.dispose();
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
                    onPressed: () {
                      if (_name.text.trim().isEmpty) {
                        return;
                      }

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

                      Navigator.of(context).pop(true);
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
