import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/voice_remote_datasource.dart';

/// The caller's own escalation quota and call history — the mobile counterpart
/// of the dashboard's Voice Escalations console.
class VoiceEscalationsPage extends StatefulWidget {
  const VoiceEscalationsPage({super.key});

  @override
  State<VoiceEscalationsPage> createState() => _VoiceEscalationsPageState();
}

class _VoiceEscalationsPageState extends State<VoiceEscalationsPage> {
  late final VoiceRemoteDataSource _api;

  bool _loading = true;
  String? _error;
  Map<String, dynamic> _quota = const {};
  List<Map<String, dynamic>> _calls = [];

  @override
  void initState() {
    super.initState();
    _api = VoiceRemoteDataSource(getIt<DioClient>());
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final results = await Future.wait<dynamic>([_api.quota(), _api.calls()]);
      if (!mounted) return;

      setState(() {
        _quota = results[0] as Map<String, dynamic>;
        _calls = results[1] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load your escalation history. Pull to retry.';
      });
    }
  }

  bool get _voiceEnabled {
    final state = context.read<AuthBloc>().state;
    if (state is AuthMembershipsLoaded) return state.user.voiceOptIn;
    if (state is AuthAuthenticated) return state.user.voiceOptIn;
    return false;
  }

  bool get _phoneVerified {
    final state = context.read<AuthBloc>().state;
    if (state is AuthMembershipsLoaded) return state.user.phoneVerified;
    if (state is AuthAuthenticated) return state.user.phoneVerified;
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Text('Voice Escalations'),
        backgroundColor: AppTheme.surface,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _load,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  _quotaGrid(),
                  const SizedBox(height: 16),
                  _consentCard(),
                  const SizedBox(height: 16),
                  _policyCard(),
                  const SizedBox(height: 20),
                  const Text(
                    'Call history',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Every automated and direct call placed to your number.',
                    style: TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                  const SizedBox(height: 10),
                  if (_error != null)
                    _errorCard()
                  else if (_calls.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 16),
                      child: Text(
                        'No calls yet. Escalations only run for opted-in, overdue high-priority errands.',
                        style: TextStyle(fontSize: 13, color: AppTheme.muted),
                      ),
                    )
                  else
                    ..._calls.map(_callCard),
                ],
              ),
      ),
    );
  }

  Widget _quotaGrid() {
    final used = (_quota['used_today'] as num?)?.toInt() ?? 0;
    final budget = (_quota['daily_budget'] as num?)?.toInt() ?? 0;

    return Row(
      children: [
        Expanded(
          child: _stat(
            'Used today',
            '$used / $budget',
            Icons.phone_in_talk_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _stat(
            'Attempts / errand',
            '${_quota['max_attempts_per_request'] ?? 0}',
            Icons.repeat_rounded,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _stat(
            'Cooldown',
            '${_quota['cooldown_minutes'] ?? 0} min',
            Icons.timer_outlined,
          ),
        ),
      ],
    );
  }

  Widget _stat(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppTheme.secondary),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          Text(
            label,
            style: const TextStyle(fontSize: 11, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _consentCard() {
    final ready = _voiceEnabled && _phoneVerified;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: ready ? AppTheme.forestSoft : AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          Icon(
            ready ? Icons.verified_user_outlined : Icons.warning_amber_rounded,
            color: ready ? AppTheme.secondary : AppTheme.tertiary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ready ? 'You are reachable' : 'Calls are currently blocked',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
                Text(
                  ready
                      ? 'Voice consent is on and your phone number is verified.'
                      : !_phoneVerified
                          ? 'Verify your phone number and opt in to urgent calls.'
                          : 'Opt in to urgent overdue calls in Settings → Alerts.',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _policyCard() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How escalation works',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          SizedBox(height: 6),
          Text(
            '• Only overdue, high-priority errands assigned to you are escalated.\n'
            '• The daily budget, per-errand attempt limit and cooldown are enforced server-side.\n'
            '• Household quiet hours always win — no call is placed inside them.\n'
            '• Every call is recorded here and in the audit log.',
            style: TextStyle(fontSize: 12, height: 1.5, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _errorCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Column(
        children: [
          Text(
            _error!,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: 8),
          OutlinedButton(onPressed: _load, child: const Text('Try again')),
        ],
      ),
    );
  }

  Widget _callCard(Map<String, dynamic> call) {
    final status = call['status']?.toString() ?? 'unknown';
    final request = call['request'] is Map ? call['request'] as Map : null;
    final created = DateTime.tryParse(
      call['created_at']?.toString() ?? '',
    )?.toLocal();

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(_statusIcon(status), size: 18, color: _statusColor(status)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request?['title']?.toString() ?? 'Direct member call',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
                if (call['reason'] != null)
                  Text(
                    call['reason'].toString(),
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                  ),
                const SizedBox(height: 4),
                Text(
                  [
                    _statusLabel(status),
                    if (call['attempts'] != null) '${call['attempts']} attempt(s)',
                    if (created != null) _date(created),
                  ].join(' · '),
                  style: const TextStyle(fontSize: 10, color: AppTheme.muted),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _statusIcon(String status) => switch (status) {
    'completed' => Icons.check_circle_outline_rounded,
    'skipped' => Icons.block_rounded,
    'failed' => Icons.error_outline_rounded,
    _ => Icons.schedule_rounded,
  };

  Color _statusColor(String status) => switch (status) {
    'completed' => AppTheme.secondary,
    'skipped' || 'failed' => AppTheme.error,
    _ => AppTheme.tertiary,
  };

  String _statusLabel(String status) => switch (status) {
    'completed' => 'Completed',
    'skipped' => 'Skipped',
    'failed' => 'Failed',
    'initiated' => 'Initiated',
    'answered' => 'Answered',
    _ => status,
  };

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    final hour = value.hour.toString().padLeft(2, '0');
    final minute = value.minute.toString().padLeft(2, '0');

    return '${value.year}-$month-$day $hour:$minute';
  }
}
