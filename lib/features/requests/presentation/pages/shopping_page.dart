import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../pantry/presentation/bloc/pantry_bloc.dart';
import '../../../pantry/presentation/bloc/pantry_event.dart';
import '../../../pantry/presentation/bloc/pantry_state.dart';
import '../../domain/entities/service_request.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

/// M-06 — Shopping mode. Open requests grouped by store, optimised for
/// one-handed use in a shop: large targets, strike-through on completion.
class ShoppingPage extends StatelessWidget {
  const ShoppingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestsBloc>()..add(const BoardRequested()),
      child: const _ShoppingView(),
    );
  }
}

class _ShoppingView extends StatelessWidget {
  const _ShoppingView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Text('Shopping mode'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () =>
                context.read<RequestsBloc>().add(const BoardRequested()),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: BlocConsumer<RequestsBloc, RequestsState>(
        listener: (context, state) {
          if (state is RequestsActionSuccess) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
            context.read<RequestsBloc>().add(const BoardRequested());
          } else if (state is RequestsFailure) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.message)));
          }
        },
        builder: (context, state) {
          if (state is RequestsLoading || state is RequestsInitial) {
            return const Center(
              child: CircularProgressIndicator(color: AppTheme.secondary),
            );
          }

          if (state is! RequestsBoardLoaded) {
            return const Center(child: Text('Nothing to show.'));
          }

          final open = <ServiceRequest>[
            ...state.board.overdue,
            ...state.board.dueToday,
            ...state.board.assignedToMe,
            // Undated and unassigned items are still things to buy.
            ...state.board.backlog,
          ];

          // De-duplicate: a request can legitimately appear on more than one board.
          final seen = <int>{};
          final unique = open.where((request) => seen.add(request.id)).toList();

          if (unique.isEmpty) {
            // M-06q: every item is picked up — offer the checkout hand-off.
            return ListView(
              padding: const EdgeInsets.all(AppTheme.space4),
              children: [
                const _PantryPulseCard(),
                const SizedBox(height: AppTheme.space4),
                WarmEmptyState(
                  title: 'Run complete — ready for checkout',
                  description:
                      'Every open item across your saved stores is ticked off. '
                      'Anything still outstanding will appear here.',
                  icon: Icons.shopping_cart_checkout,
                  action: FilledButton(
                    onPressed: () => context.push('/requests/new'),
                    child: const Text('Add a request'),
                  ),
                ),
              ],
            );
          }

          // Group by store, falling back to a single "no store" bucket.
          final groups = <String, List<ServiceRequest>>{};

          for (final request in unique) {
            final key = (request.storeName ?? 'No store assigned').trim();
            groups.putIfAbsent(key, () => []).add(request);
          }

          final stores = groups.keys.toList()..sort();

          return RefreshIndicator(
            color: AppTheme.secondary,
            onRefresh: () async =>
                context.read<RequestsBloc>().add(const BoardRequested()),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                const _PantryPulseCard(),
                const SizedBox(height: AppTheme.space4),
                Text(
                  '${unique.length} item${unique.length == 1 ? '' : 's'} across ${stores.length} store${stores.length == 1 ? '' : 's'}',
                  style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                ),
                const SizedBox(height: AppTheme.space4),
                for (final store in stores)
                  _StoreGroup(store: store, requests: groups[store]!),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StoreGroup extends StatelessWidget {
  const _StoreGroup({required this.store, required this.requests});

  final String store;
  final List<ServiceRequest> requests;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<RequestsBloc>();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront, size: 18, color: AppTheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  store,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              PriorityChip(
                label: '${requests.length} to get',
                tone: WarmTone.primary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          for (final request in requests)
            Padding(
              padding: const EdgeInsets.only(bottom: AppTheme.space2),
              child: WarmCard(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.space3,
                  vertical: AppTheme.space2,
                ),
                child: Row(
                  children: [
                    Semantics(
                      button: true,
                      label: 'Mark ${request.title} as picked up',
                      child: InkResponse(
                        onTap: () => bloc.add(
                          ActionRequested(id: request.id, action: 'complete'),
                        ),
                        radius: 24,
                        child: SizedBox(
                          width: 44,
                          height: 44,
                          child: Center(
                            child: Container(
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: AppTheme.outline,
                                  width: 1.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: AppTheme.space2),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request.title,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                          if (request.quantity != null ||
                              request.assigneeName != null)
                            Text(
                              [
                                if (request.quantity != null) request.quantity!,
                                if (request.assigneeName != null)
                                  'for ${request.assigneeName}',
                              ].join(' · '),
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppTheme.muted,
                              ),
                            ),
                        ],
                      ),
                    ),
                    // M-06n: out-of-stock / substitution path. Flags the item
                    // unavailable and notifies the household with a note.
                    IconButton(
                      tooltip: 'Not available — ask for a substitute',
                      visualDensity: VisualDensity.compact,
                      onPressed: () => bloc.add(
                        ActionRequested(
                          id: request.id,
                          action: 'unavailable',
                          payload: const {
                            'note':
                                'Out of stock in store — substitute needed.',
                          },
                        ),
                      ),
                      icon: const Icon(
                        Icons.swap_horiz,
                        color: AppTheme.tertiary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: AppTheme.space2),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () {
                for (final request in requests) {
                  bloc.add(ActionRequested(id: request.id, action: 'complete'));
                }
              },
              child: Text('Mark $store done'),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pantry pulse: real safety-stock counts from /v1/essentials. Tapping opens the
/// full pantry screen, which is where restocking happens.
class _PantryPulseCard extends StatelessWidget {
  const _PantryPulseCard();

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<PantryBloc>()..add(const PantryRequested()),
      child: BlocBuilder<PantryBloc, PantryState>(
        builder: (context, state) {
          final summary = state is PantryLoaded ? state.snapshot.summary : null;

          final detail = summary == null
              ? 'Checking your staples…'
              : summary.due == 0
              ? '${summary.total} tracked · all stocked'
              : '${summary.due} of ${summary.total} need restocking';

          return WarmCard(
            onTap: () => context.push('/pantry'),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: AppTheme.forestSoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusLg),
                  ),
                  child: const Icon(
                    Icons.inventory_2_outlined,
                    color: AppTheme.secondary,
                  ),
                ),
                const SizedBox(width: AppTheme.space3),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Pantry & essentials',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                      Text(
                        detail,
                        style: const TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                        ),
                      ),
                    ],
                  ),
                ),
                if (summary != null && summary.due > 0)
                  PriorityChip(
                    label: '${summary.due} due',
                    tone: WarmTone.danger,
                  )
                else
                  const Icon(Icons.chevron_right, color: AppTheme.muted),
              ],
            ),
          );
        },
      ),
    );
  }
}
