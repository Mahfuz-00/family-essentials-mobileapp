import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/notifications/local_notifications.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../places/location_arrival_check.dart';
import '../../../places/presentation/widgets/location_needs_card.dart';
import '../../domain/entities/service_request.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

/// M-03 — Home / Today.
///
/// One screen, one job: what needs doing now. "Next up" is the answer; the rest
/// of the list is context. Nothing renders before there is content.
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

    // Once, after the first frame: the auth bloc may not have a user yet.
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkArrivals());
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
          builder: (context, state) => _body(context, state),
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

    // Today and "assigned to me" overlap heavily; show each task once, most
    // urgent first.
    final today = <ServiceRequest>[
      ...board.dueToday,
      ...board.assignedToMe.where(
        (task) => !board.dueToday.any((other) => other.id == task.id),
      ),
    ];

    final next = board.overdue.isNotEmpty
        ? board.overdue.first
        : (today.isNotEmpty ? today.first : null);

    return RefreshIndicator(
      color: AppTheme.secondary,
      onRefresh: () async =>
          context.read<RequestsBloc>().add(const BoardRequested()),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
        children: [
          if (widget.focusedPlaceId != null) ...[
            LocationNeedsCard(placeId: widget.focusedPlaceId!),
            const SizedBox(height: AppTheme.space4),
          ],

          if (next == null)
            WarmEmptyState(
              title: 'Nothing needs you',
              description:
                  'When somebody asks you for something, or a deadline arrives, '
                  'it shows up here — and you are told at the moment it matters.',
              icon: Icons.check_circle_outline,
              action: FilledButton(
                onPressed: () async {
                  final created = await context.push<bool>('/requests/new');

                  if (created == true && context.mounted) {
                    context.read<RequestsBloc>().add(const BoardRequested());
                  }
                },
                child: const Text('Add a request'),
              ),
            )
          else ...[
            _NextUp(request: next),
            if (board.overdue.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space5),
              _Section(
                title: 'Overdue',
                dotColor: AppTheme.error,
                requests: board.overdue,
              ),
            ],
            if (today.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space5),
              _Section(
                title: 'Today',
                dotColor: AppTheme.warning,
                requests: today,
              ),
            ],
            if (board.backlog.isNotEmpty) ...[
              const SizedBox(height: AppTheme.space5),
              _LaterRow(
                count: board.backlog.length,
                onTap: () => context.go('/today'),
              ),
            ],
          ],
        ],
      ),
    );
  }
}

/// The one thing to do next. The only card with a coloured border on the screen.
class _NextUp extends StatelessWidget {
  const _NextUp({required this.request});

  final ServiceRequest request;

  @override
  Widget build(BuildContext context) {
    final overdue =
        request.isOpen &&
        request.dueAt != null &&
        request.dueAt!.isBefore(DateTime.now());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'NEXT UP',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.02 * 11,
            color: AppTheme.muted,
          ),
        ),
        const SizedBox(height: AppTheme.space2),
        WarmCard(
          highlighted: true,
          padding: const EdgeInsets.all(AppTheme.space4),
          onTap: () => context.push('/requests/${request.id}'),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      request.title,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.ink,
                      ),
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppTheme.muted,
                      ),
                    ),
                    if (request.dueAt != null) ...[
                      const SizedBox(height: 8),
                      PriorityChip(
                        label: overdue ? 'Overdue' : _time(request.dueAt!),
                        tone: overdue ? WarmTone.danger : WarmTone.primary,
                        dot: true,
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              IconButton(
                tooltip: 'Mark done',
                onPressed: () => context.read<RequestsBloc>().add(
                  ActionRequested(id: request.id, action: 'complete'),
                ),
                icon: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.secondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  String _time(DateTime due) =>
      '${due.hour.toString().padLeft(2, '0')}:${due.minute.toString().padLeft(2, '0')}';
}

class _Section extends StatelessWidget {
  const _Section({required this.title, required this.requests, this.dotColor});

  final String title;
  final List<ServiceRequest> requests;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title: title, count: requests.length, dotColor: dotColor),
        const SizedBox(height: AppTheme.space3),
        for (final request in requests) TaskCard(request: request),
      ],
    );
  }
}

/// The backlog, collapsed to a count: it is context, not today's work.
class _LaterRow extends StatelessWidget {
  const _LaterRow({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTheme.space4,
        vertical: AppTheme.space3,
      ),
      child: Row(
        children: [
          const Icon(Icons.inbox_outlined, size: 18, color: AppTheme.muted),
          const SizedBox(width: AppTheme.space2),
          Expanded(
            child: Text(
              '$count waiting for later',
              style: const TextStyle(
                fontSize: 13,
                color: AppTheme.onSurfaceVariant,
              ),
            ),
          ),
          const Icon(Icons.chevron_right, size: 18, color: AppTheme.muted),
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
