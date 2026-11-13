import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../domain/entities/service_request.dart';
import '../../domain/repositories/requests_repository.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';
import '../widgets/fulfill_sheet.dart';
import '../widgets/reminder_cue.dart';

class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestsBloc>()..add(DetailRequested(id)),
      child: _RequestDetailView(id: id),
    );
  }
}

class _RequestDetailView extends StatelessWidget {
  const _RequestDetailView({required this.id});

  final int id;

  Future<void> _reassignChore(BuildContext context, ServiceRequest request) async {
    final bloc = context.read<RequestsBloc>();
    List<HouseholdMember> members = [];
    try {
      members = await getIt<RequestsRepository>().members();
    } catch (_) {}

    if (!context.mounted) return;

    final choices = [
      const MemberChoice(null, 'Anyone in household (Unassigned)'),
      ...members.map((m) => MemberChoice(m.userId, m.name)),
    ];

    final currentChoice = choices.firstWhere(
      (c) => c.userId == request.assigneeId,
      orElse: () => choices.first,
    );

    final chosen = await showChoiceSheet<MemberChoice>(
      context: context,
      title: 'Assign / Handover Chore',
      options: choices,
      label: (c) => c.name,
      current: currentChoice,
    );

    if (chosen != null) {
      bloc.add(AssignRequested(id: request.id, assigneeId: chosen.userId));
    }
  }

  /// The member set a cue on this task; this is the one place it comes back.
  Future<void> _changeReminder(BuildContext context, ServiceRequest request) {
    final bloc = context.read<RequestsBloc>();

    return showReminderCueSheet(
      context: context,
      initialMode: request.hasLocationTrigger
          ? (request.triggerDirection ?? cueOnArrival)
          : cueByTime,
      initialPlaceId: request.triggerPlaceId,
    ).then((chosen) {
      if (chosen == null) {
        return;
      }

      bloc.add(
        ReminderCueChanged(
          id: request.id,
          triggerPlaceId: chosen.placeId,
          triggerDirection: chosen.mode == cueByTime ? null : chosen.mode,
        ),
      );
    });
  }

  Future<void> _handleCallAssignee(BuildContext context, ServiceRequest request) async {
    final bloc = context.read<RequestsBloc>();
    const phone = '+15550000002';
    final name = request.assigneeName ?? 'Assignee';

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
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
                Text(
                  'Reach $name',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.ink,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose standard cellular call or automated AI voice escalation.',
                  style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                ),
                const SizedBox(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.forestSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.phone_in_talk, color: AppTheme.secondary),
                  ),
                  title: const Text('Direct Phone Call', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Dial $phone directly on cellular network'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.muted),
                  onTap: () async {
                    Navigator.of(ctx).pop();
                    final uri = Uri.parse('tel:$phone');
                    if (await canLaunchUrl(uri)) {
                      await launchUrl(uri);
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Could not open phone dialer for $phone')),
                        );
                      }
                    }
                  },
                ),
                const Divider(height: 16),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.coralSoft,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.ring_volume, color: AppTheme.tertiary),
                  ),
                  title: const Text('AI Voice Escalation Call', style: TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: const Text('Trigger automated Twilio urgency call to assignee'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: AppTheme.muted),
                  onTap: () {
                    Navigator.of(ctx).pop();
                    bloc.add(VoiceCallRequested(request.id));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('AI voice escalation requested for $name!'),
                        backgroundColor: AppTheme.secondary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openFulfillSheet(BuildContext context, ServiceRequest request) {
    FulfillRequestSheet.show(
      context,
      request: request,
      onComplete: (payload) {
        context.read<RequestsBloc>().add(
              ActionRequested(id: request.id, action: 'complete', payload: payload),
            );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Request')),
      body: SafeArea(
        child: BlocConsumer<RequestsBloc, RequestsState>(
          listener: (context, state) {
            if (state is RequestsActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              // The task changed, so re-read it rather than assuming.
              context.read<RequestsBloc>().add(DetailRequested(id));
            } else if (state is RequestsFailure) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(state.message),
                  backgroundColor: AppTheme.coralSoft,
                ),
              );
            }
          },
          builder: (context, state) {
            if (state is RequestsLoading || state is RequestsInitial) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.secondary),
              );
            }

            if (state is RequestsFailure) {
              return Center(child: Text(state.message));
            }

            if (state is RequestsDetailLoaded) {
              return _detail(context, state.request);
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }

  Widget _detail(BuildContext context, ServiceRequest request) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        Text(
          request.title,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: AppTheme.space2),
        Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            PriorityChip(label: request.status, tone: WarmTone.neutral),
            PriorityChip(label: request.priority, tone: _priorityTone(request)),
            if (request.hasLocationTrigger)
              const PriorityChip(
                label: 'Place reminder',
                tone: WarmTone.primary,
                dot: true,
              ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),

        // Assignment Card
        WarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Assignment', count: 1),
              const SizedBox(height: AppTheme.space3),
              Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: request.assigneeName != null
                        ? AppTheme.secondary.withValues(alpha: 0.15)
                        : AppTheme.sageSoft,
                    child: Icon(
                      request.assigneeName != null ? Icons.person : Icons.group_outlined,
                      size: 22,
                      color: request.assigneeName != null ? AppTheme.secondary : AppTheme.muted,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.assigneeName ?? 'Anyone (Unassigned)',
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.ink,
                          ),
                        ),
                        Text(
                          request.assigneeName != null
                              ? 'Assigned household member'
                              : 'Open for any household member to pick up',
                          style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _reassignChore(context, request),
                    icon: const Icon(Icons.swap_horiz, size: 16),
                    label: Text(request.assigneeName != null ? 'Reassign' : 'Assign'),
                    style: OutlinedButton.styleFrom(
                      visualDensity: VisualDensity.compact,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space3),

        WarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(
                title: 'The task',
                count: _facts(request).length,
              ),
              const SizedBox(height: AppTheme.space3),
              for (final fact in _facts(request))
                _Row(label: fact.label, value: fact.value),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space3),

        if (request.items.isNotEmpty) ...[
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Items in this errand',
                  count: request.items.length,
                ),
                const SizedBox(height: AppTheme.space3),
                for (final item in request.items)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            item.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.w600,
                              color: AppTheme.ink,
                            ),
                          ),
                        ),
                        Text(
                          [
                            if (item.quantityAsked != null) 'Asked: ${item.quantityAsked}',
                            if (item.quantityGot != null) 'Got: ${item.quantityGot}',
                          ].join(' · '),
                          style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space3),
        ],

        // The cue the member actually set, in one line, with a way to change it.
        WarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SectionHeader(title: 'Reminder', count: 1),
              const SizedBox(height: AppTheme.space2),
              Text(
                request.reminderCue ??
                    'No place reminder — you are reminded by the due time.',
                style: const TextStyle(fontSize: 14, color: AppTheme.ink),
              ),
              const SizedBox(height: AppTheme.space3),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _changeReminder(context, request),
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: Text(
                    request.hasLocationTrigger
                        ? 'Change reminder'
                        : 'Add a place reminder',
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space4),

        Wrap(
          spacing: AppTheme.space2,
          runSpacing: AppTheme.space2,
          children: [
            if (request.status == 'pending')
              FilledButton(
                onPressed: () => context.read<RequestsBloc>().add(
                  ActionRequested(id: request.id, action: 'accept'),
                ),
                child: const Text('Accept'),
              ),
            if (request.status == 'accepted')
              FilledButton(
                onPressed: () => context.read<RequestsBloc>().add(
                  ActionRequested(id: request.id, action: 'start'),
                ),
                child: const Text('Start'),
              ),
            if (request.isOpen)
              FilledButton.icon(
                icon: const Icon(Icons.check_circle_outline, size: 18),
                onPressed: () => _openFulfillSheet(context, request),
                label: const Text('Fulfill & Complete'),
              ),
            if (request.isOpen)
              OutlinedButton.icon(
                icon: const Icon(Icons.swap_horiz, size: 18),
                onPressed: () => _reassignChore(context, request),
                label: const Text('Handover chore'),
              ),
            if (request.isOpen)
              OutlinedButton(
                onPressed: () => context.read<RequestsBloc>().add(
                  ActionRequested(id: request.id, action: 'cancel'),
                ),
                child: const Text('Cancel'),
              ),
            if (request.isOpen)
              OutlinedButton.icon(
                onPressed: () => _handleCallAssignee(context, request),
                icon: const Icon(Icons.phone, size: 18),
                label: const Text('Call assignee'),
              ),
          ],
        ),
        const SizedBox(height: AppTheme.space4),

        if (request.voiceCalls.isNotEmpty) ...[
          WarmCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SectionHeader(
                  title: 'Voice calls',
                  count: request.voiceCalls.length,
                ),
                const SizedBox(height: AppTheme.space3),
                for (final call in request.voiceCalls)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      '${call.status}${call.reason == null ? '' : ' (${call.reason})'}',
                      style: const TextStyle(
                        color: AppTheme.muted,
                        fontSize: 13,
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: AppTheme.space3),
        ],

        WarmCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SectionHeader(title: 'History', count: request.history.length),
              const SizedBox(height: AppTheme.space3),
              if (request.history.isEmpty)
                const Text(
                  'Nothing has happened to this task yet.',
                  style: TextStyle(fontSize: 13, color: AppTheme.muted),
                ),
              for (final entry in request.history)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    '${entry.action}${entry.actorName != null ? ' — ${entry.actorName}' : ''}',
                    style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }

  WarmTone _priorityTone(ServiceRequest request) {
    switch (request.priority) {
      case 'high':
      case 'urgent':
        return WarmTone.danger;
      case 'low':
        return WarmTone.neutral;
      default:
        return WarmTone.primary;
    }
  }

  /// Only what the API actually returned: no row is invented for a null field.
  List<({String label, String value})> _facts(ServiceRequest request) {
    return [
      if (request.quantity != null)
        (label: 'Quantity asked', value: request.quantity!),
      if (request.quantityGot != null)
        (label: 'Quantity got', value: request.quantityGot!),
      if (request.storeName != null)
        (label: 'Store', value: request.storeName!),
      if (request.assigneeName != null)
        (label: 'Assignee', value: request.assigneeName!),
      if (request.requesterName != null)
        (label: 'Requested by', value: request.requesterName!),
      if (request.dueAt != null)
        (label: 'Due', value: request.dueAt!.toLocal().toString()),
      if (request.notes != null) (label: 'Notes', value: request.notes!),
      // Money is an integer count of minor units, so it is shown as one rather
      // than dressed in a currency symbol the API never sent.
      if (request.amountMinor != null)
        (
          label: 'Ledger',
          value: request.ledgerId == null
              ? '${request.amountMinor} minor units'
              : 'Ledger #${request.ledgerId} · ${request.amountMinor} minor units',
        ),
    ];
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(color: AppTheme.muted, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(color: AppTheme.ink, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
