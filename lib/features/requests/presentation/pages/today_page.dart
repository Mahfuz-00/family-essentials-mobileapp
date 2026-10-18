import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/notifications/local_notifications.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../auth/domain/entities/user.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../places/location_arrival_check.dart';
import '../../../places/presentation/widgets/location_needs_card.dart';
import '../../../places/presentation/widgets/nearby_section.dart';
import '../../domain/entities/service_request.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

/// M-03 — Home / Today. Live logistics for the household.
class TodayPage extends StatelessWidget {
  const TodayPage({super.key, this.focusedPlaceId});

  /// Set when an arrival notification was tapped: the place to open.
  final int? focusedPlaceId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestsBloc>()..add(const BoardRequested()),
      child: _TodayView(focusedPlaceId: focusedPlaceId),
    );
  }
}

class _TodayView extends StatefulWidget {
  const _TodayView({this.focusedPlaceId});

  final int? focusedPlaceId;

  @override
  State<_TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<_TodayView> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _checkArrivals();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // A resumed app is the only moment this page can learn about an arrival, so
    // it is checked here rather than on a timer.
    if (state == AppLifecycleState.resumed) {
      _checkArrivals();
    }
  }

  bool get _arrivalNotificationsEnabled {
    final state = context.read<AuthBloc>().state;

    if (state is AuthMembershipsLoaded) {
      return state.user.locationNotificationsOptIn;
    }

    if (state is AuthAuthenticated) {
      return state.user.locationNotificationsOptIn;
    }

    return false;
  }

  Future<void> _checkArrivals() async {
    // Off unless the member asked for it; the check itself handles a refused
    // permission and never blocks the board.
    if (!mounted || !_arrivalNotificationsEnabled) {
      return;
    }

    await getIt<LocationArrivalCheck>().run(enabled: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final created = await context.push<bool>('/requests/new');

          if (created == true && context.mounted) {
            context.read<RequestsBloc>().add(const BoardRequested());
          }
        },
        backgroundColor: AppTheme.secondary,
        foregroundColor: AppTheme.onSecondary,
        elevation: 4,
        tooltip: 'Add a request',
        child: const Icon(Icons.add, size: 28),
      ),
      body: SafeArea(
        child: BlocConsumer<RequestsBloc, RequestsState>(
          listener: (context, state) {
            if (state is RequestsActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              context.read<RequestsBloc>().add(const BoardRequested());
            } else if (state is RequestsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.coralSoft,
                ),
              );
            } else if (state is RequestsBoardLoaded) {
              // Keep device-local reminders in step with the board.
              unawaited(
                getIt<LocalNotifications>().sync([
                  ...state.board.overdue,
                  ...state.board.dueToday,
                  ...state.board.assignedToMe,
                  ...state.board.backlog,
                  ...state.board.completedToday,
                ], DateTime.now()),
              );
            }
          },
          builder: (context, state) {
            return Column(
              children: [
                const _GreetingHeader(),
                if (state is RequestsBoardLoaded &&
                    state.board.counts['overdue'] != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                    child: _OverdueBanner(
                      request: state.board.overdue.isEmpty
                          ? null
                          : state.board.overdue.first,
                      count: state.board.counts['overdue'] ?? 0,
                    ),
                  ),
                Expanded(child: _body(context, state)),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _body(BuildContext context, RequestsState state) {
    if (state is RequestsLoading || state is RequestsInitial) {
      return const Center(
        child: CircularProgressIndicator(color: AppTheme.secondary),
      );
    }

    if (state is! RequestsBoardLoaded) {
      return const Center(child: Text('Nothing to show.'));
    }

    final board = state.board;

    return RefreshIndicator(
      color: AppTheme.secondary,
      onRefresh: () async =>
          context.read<RequestsBloc>().add(const BoardRequested()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatPill(value: board.counts['total'] ?? 0, label: 'Total'),
              StatPill(
                value: board.counts['overdue'] ?? 0,
                label: 'Overdue',
                tone: WarmTone.danger,
              ),
              StatPill(
                value: board.counts['due_today'] ?? 0,
                label: 'Due today',
                tone: WarmTone.warning,
              ),
              StatPill(
                value: board.counts['assigned_to_me'] ?? 0,
                label: 'Mine',
                tone: WarmTone.primary,
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space4),
          if (widget.focusedPlaceId != null) ...[
            LocationNeedsCard(placeId: widget.focusedPlaceId!),
            const SizedBox(height: AppTheme.space4),
          ],
          const NearbySection(),
          const SizedBox(height: AppTheme.space4),
          _Section(
            title: 'Overdue',
            dotColor: AppTheme.error,
            requests: board.overdue,
            empty: 'Nothing overdue.',
          ),
          _Section(
            title: 'Due today',
            dotColor: AppTheme.warning,
            requests: board.dueToday,
            empty: 'Nothing due today.',
          ),
          _Section(
            title: 'Assigned to me',
            dotColor: AppTheme.secondary,
            requests: board.assignedToMe,
            empty: 'Nothing assigned to you.',
          ),
          _Section(
            title: 'Backlog',
            dotColor: AppTheme.outline,
            requests: board.backlog,
            empty: 'Nothing waiting in the backlog.',
          ),
          _Section(
            title: 'Completed today',
            dotColor: AppTheme.success,
            requests: board.completedToday,
            empty: 'Nothing completed yet.',
          ),
        ],
      ),
    );
  }
}

class _GreetingHeader extends StatelessWidget {
  const _GreetingHeader();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        User? user;
        String? household;

        if (state is AuthMembershipsLoaded) {
          user = state.user;

          for (final membership in state.memberships) {
            if (membership.isActive) {
              household = membership.tenant.name;
              break;
            }
          }

          household ??= state.memberships.isEmpty
              ? null
              : state.memberships.first.tenant.name;
        } else if (state is AuthAuthenticated) {
          user = state.user;
        }

        final hour = DateTime.now().hour;
        final greeting = hour < 12
            ? 'Good morning'
            : hour < 18
            ? 'Good afternoon'
            : 'Good evening';
        final firstName = (user?.name ?? 'there').split(' ').first;

        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, $firstName',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      household ?? 'Household logistics · live sync',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.02 * 11,
                        color: AppTheme.muted,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Refresh the board',
                onPressed: () =>
                    context.read<RequestsBloc>().add(const BoardRequested()),
                icon: const Icon(
                  Icons.refresh,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _OverdueBanner extends StatelessWidget {
  const _OverdueBanner({required this.request, required this.count});

  final ServiceRequest? request;
  final int count;

  @override
  Widget build(BuildContext context) {
    if (count == 0 || request == null) {
      return const SizedBox.shrink();
    }

    final bloc = context.read<RequestsBloc>();

    return WarmBanner(
      title: 'Overdue attention required ($count)',
      detail:
          '${request!.title}${request!.storeName == null ? '' : ' · ${request!.storeName}'}',
      actions: [
        OutlinedButton(
          onPressed: () => bloc.add(const BoardRequested()),
          child: const Text('Review'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            minimumSize: const Size(0, 40),
            backgroundColor: AppTheme.error,
            padding: const EdgeInsets.symmetric(horizontal: 16),
          ),
          onPressed: () =>
              bloc.add(ActionRequested(id: request!.id, action: 'escalate')),
          child: const Text('Voice alert'),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  const _Section({
    required this.title,
    required this.requests,
    required this.empty,
    this.dotColor,
  });

  final String title;
  final List<ServiceRequest> requests;
  final String empty;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionHeader(
            title: title,
            count: requests.length,
            dotColor: dotColor,
          ),
          const SizedBox(height: AppTheme.space3),
          if (requests.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: AppTheme.space3),
              child: Text(
                empty,
                style: const TextStyle(fontSize: 13, color: AppTheme.muted),
              ),
            )
          else
            for (final request in requests) TaskCard(request: request),
        ],
      ),
    );
  }
}

/// Task card: tactile completion circle, priority chip, store, assignee, due.
class TaskCard extends StatelessWidget {
  const TaskCard({super.key, required this.request});

  final ServiceRequest request;

  WarmTone get _priorityTone {
    switch (request.priority) {
      case 'high':
        return WarmTone.danger;
      case 'urgent':
        return WarmTone.danger;
      case 'low':
        return WarmTone.neutral;
      default:
        return WarmTone.primary;
    }
  }

  String? get _due {
    final due = request.dueAt;

    if (due == null) {
      return null;
    }

    final over = DateTime.now().difference(due).inHours;

    if (over > 0 && request.isOpen) {
      return '${over}h overdue';
    }

    return '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';
  }

  void _advance(BuildContext context) {
    if (request.status == 'pending') {
      context.read<RequestsBloc>().add(
        ActionRequested(id: request.id, action: 'accept'),
      );
    } else {
      context.read<RequestsBloc>().add(
        ActionRequested(id: request.id, action: 'complete'),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = request.status == 'completed';
    final due = _due;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppTheme.space3),
      child: WarmCard(
        onTap: () => context.push('/requests/${request.id}'),
        padding: const EdgeInsets.all(AppTheme.space4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 48x48 tap target around a 24px visual circle.
            Semantics(
              button: true,
              label: done
                  ? '${request.title} completed'
                  : 'Mark ${request.title} ${request.status == 'pending' ? 'accepted' : 'done'}',
              child: InkResponse(
                onTap: done ? null : () => _advance(context),
                radius: 24,
                child: SizedBox(
                  width: 44,
                  height: 44,
                  child: Center(
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: done ? AppTheme.success : Colors.transparent,
                        border: Border.all(
                          color: done ? AppTheme.success : AppTheme.outline,
                          width: 1.5,
                        ),
                      ),
                      child: done
                          ? const Icon(
                              Icons.check,
                              size: 16,
                              color: AppTheme.surface,
                            )
                          : null,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          request.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: done ? AppTheme.muted : AppTheme.ink,
                            decoration: done
                                ? TextDecoration.lineThrough
                                : null,
                          ),
                        ),
                      ),
                      PriorityChip(
                        label: request.priority,
                        tone: _priorityTone,
                        dot: true,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    [
                      if (request.quantity != null) request.quantity!,
                      if (request.storeName != null) request.storeName!,
                      if (request.assigneeName != null)
                        '→ ${request.assigneeName}',
                    ].join(' · '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  if (due != null) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(
                          Icons.schedule,
                          size: 14,
                          color: due.contains('overdue')
                              ? AppTheme.error
                              : AppTheme.muted,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          due,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: due.contains('overdue')
                                ? AppTheme.error
                                : AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
