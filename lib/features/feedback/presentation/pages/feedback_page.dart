import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../domain/entities/feedback_report.dart';
import '../bloc/feedback_bloc.dart';
import '../bloc/feedback_event.dart';
import '../bloc/feedback_state.dart';

/// Send a report, and follow what happened to it.
///
/// The status of everything this household has sent is on the same screen as the
/// form, because a report you never hear back about is a report you stop sending.
class FeedbackPage extends StatelessWidget {
  const FeedbackPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<FeedbackBloc>()..add(const FeedbackRequested()),
      child: const _FeedbackView(),
    );
  }
}

class _FeedbackView extends StatefulWidget {
  const _FeedbackView();

  @override
  State<_FeedbackView> createState() => _FeedbackViewState();
}

class _FeedbackViewState extends State<_FeedbackView> {
  final TextEditingController _subject = TextEditingController();
  final TextEditingController _body = TextEditingController();
  String _type = 'bug';
  String _priority = 'normal';

  @override
  void dispose() {
    _subject.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _canSend =>
      _subject.text.trim().length >= 4 && _body.text.trim().length >= 10;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Help & feedback')),
      body: SafeArea(
        child: BlocConsumer<FeedbackBloc, FeedbackState>(
          listener: (context, state) {
            if (state is FeedbackActionSuccess) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
              _subject.clear();
              _body.clear();
              context.read<FeedbackBloc>().add(const FeedbackRequested());
            } else if (state is FeedbackFailure) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            final reports = state is FeedbackLoaded
                ? state.reports
                : const <FeedbackReport>[];

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _composer(state),
                const SizedBox(height: AppTheme.space4),
                SectionHeader(title: 'Your reports', count: reports.length),
                const SizedBox(height: AppTheme.space3),
                if (state is FeedbackLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: CircularProgressIndicator(
                        color: AppTheme.secondary,
                      ),
                    ),
                  )
                else if (reports.isEmpty)
                  const WarmEmptyState(
                    title: 'Nothing sent yet',
                    description:
                        'When something goes wrong, tell us here. The report '
                        'lands in the platform team’s queue and its status '
                        'shows up on this screen.',
                    icon: Icons.forum_outlined,
                  )
                else
                  for (final report in reports) ...[
                    _ReportTile(report: report),
                    const SizedBox(height: AppTheme.space2),
                  ],
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _composer(FeedbackState state) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Send a report',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<String>(
            initialValue: _type,
            decoration: const InputDecoration(
              labelText: 'What kind of report?',
            ),
            items: const [
              DropdownMenuItem(
                value: 'bug',
                child: Text('Something is broken'),
              ),
              DropdownMenuItem(
                value: 'feedback',
                child: Text('General feedback'),
              ),
              DropdownMenuItem(
                value: 'feature_request',
                child: Text('Something is missing'),
              ),
            ],
            onChanged: (value) => setState(() => _type = value ?? 'bug'),
          ),
          const SizedBox(height: AppTheme.space2),
          DropdownButtonFormField<String>(
            initialValue: _priority,
            decoration: const InputDecoration(labelText: 'How urgent is it?'),
            items: const [
              DropdownMenuItem(value: 'low', child: Text('Low')),
              DropdownMenuItem(value: 'normal', child: Text('Normal')),
              DropdownMenuItem(value: 'high', child: Text('High')),
              DropdownMenuItem(value: 'critical', child: Text('Critical')),
            ],
            onChanged: (value) => setState(() => _priority = value ?? 'normal'),
          ),
          const SizedBox(height: AppTheme.space2),
          TextField(
            controller: _subject,
            onChanged: (_) => setState(() {}),
            decoration: const InputDecoration(labelText: 'Subject'),
          ),
          const SizedBox(height: AppTheme.space2),
          TextField(
            controller: _body,
            onChanged: (_) => setState(() {}),
            maxLines: 5,
            decoration: const InputDecoration(
              labelText: 'What happened?',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          const Text(
            'The screen you are on and your device are attached automatically.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _canSend && state is! FeedbackLoading
                  ? () => context.read<FeedbackBloc>().add(
                      FeedbackSubmitted(
                        type: _type,
                        subject: _subject.text.trim(),
                        body: _body.text.trim(),
                        priority: _priority,
                      ),
                    )
                  : null,
              child: const Text('Send report'),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReportTile extends StatelessWidget {
  const _ReportTile({required this.report});

  final FeedbackReport report;

  WarmTone get _tone => switch (report.status) {
    'new' => WarmTone.primary,
    'in_progress' => WarmTone.warning,
    'resolved' => WarmTone.success,
    _ => WarmTone.neutral,
  };

  @override
  Widget build(BuildContext context) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.subject,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              const SizedBox(width: AppTheme.space2),
              PriorityChip(label: report.statusLabel, tone: _tone),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            report.typeLabel,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          if (report.resolutionNote != null) ...[
            const SizedBox(height: AppTheme.space2),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.space3),
              decoration: BoxDecoration(
                color: AppTheme.forestSoft,
                borderRadius: BorderRadius.circular(AppTheme.radiusMd),
              ),
              child: Text(
                report.resolutionNote!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
