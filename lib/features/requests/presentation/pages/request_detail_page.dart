import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../bloc/requests_bloc.dart';
import '../bloc/requests_event.dart';
import '../bloc/requests_state.dart';

class RequestDetailPage extends StatelessWidget {
  const RequestDetailPage({super.key, required this.id});

  final int id;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<RequestsBloc>()..add(DetailRequested(id)),
      child: const _RequestDetailView(),
    );
  }
}

class _RequestDetailView extends StatelessWidget {
  const _RequestDetailView();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Request')),
      body: SafeArea(
        child: BlocConsumer<RequestsBloc, RequestsState>(
          listener: (context, state) {
            if (state is RequestsActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            if (state is RequestsLoading || state is RequestsInitial) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is RequestsFailure) {
              return Center(child: Text(state.message));
            }

            if (state is RequestsDetailLoaded) {
              final request = state.request;

              return ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Text(
                    request.title,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${request.status} · ${request.priority}',
                    style: const TextStyle(color: AppTheme.muted),
                  ),
                  const SizedBox(height: 16),
                  if (request.quantity != null)
                    _Row(label: 'Quantity', value: request.quantity!),
                  if (request.storeName != null)
                    _Row(label: 'Store', value: request.storeName!),
                  if (request.assigneeName != null)
                    _Row(label: 'Assignee', value: request.assigneeName!),
                  if (request.requesterName != null)
                    _Row(label: 'Requested by', value: request.requesterName!),
                  if (request.dueAt != null)
                    _Row(
                      label: 'Due',
                      value: request.dueAt!.toLocal().toString(),
                    ),
                  if (request.notes != null)
                    _Row(label: 'Notes', value: request.notes!),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
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
                        FilledButton(
                          onPressed: () => context.read<RequestsBloc>().add(
                            ActionRequested(id: request.id, action: 'complete'),
                          ),
                          child: const Text('Mark done'),
                        ),
                      if (request.isOpen)
                        OutlinedButton(
                          onPressed: () => context.read<RequestsBloc>().add(
                            ActionRequested(id: request.id, action: 'cancel'),
                          ),
                          child: const Text('Cancel'),
                        ),
                      if (request.isOpen)
                        OutlinedButton(
                          onPressed: () => context.read<RequestsBloc>().add(
                            VoiceCallRequested(request.id),
                          ),
                          child: const Text('Trigger voice call'),
                        ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  if (request.voiceCalls.isNotEmpty) ...[
                    const Text(
                      'Voice calls',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 8),
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
                    const SizedBox(height: 16),
                  ],
                  const Text(
                    'History',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 8),
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
              );
            }

            return const SizedBox.shrink();
          },
        ),
      ),
    );
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
