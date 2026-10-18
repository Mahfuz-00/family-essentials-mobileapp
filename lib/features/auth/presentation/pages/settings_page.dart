import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../../domain/entities/membership.dart';
import '../../domain/entities/user.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';

/// M-08 — Reminder & voice-call settings, plus the household identity that the
/// old dashboard page used to own.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const SessionLoaded());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(title: const Text('Reminders & settings')),
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              context.go('/login');
            } else if (state is AuthFailureState) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text(state.message)));
            }
          },
          builder: (context, state) {
            User? user;
            List<Membership> memberships = const [];

            if (state is AuthMembershipsLoaded) {
              user = state.user;
              memberships = state.memberships;
            } else if (state is AuthAuthenticated) {
              user = state.user;
            }

            if (user == null) {
              return const Center(
                child: CircularProgressIndicator(color: AppTheme.secondary),
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _identity(user, memberships),
                const SizedBox(height: AppTheme.space3),
                _notifications(user),
                const SizedBox(height: AppTheme.space3),
                _escalation(user),
                const SizedBox(height: AppTheme.space3),
                _locationArrivals(user),
                const SizedBox(height: AppTheme.space3),
                _support(),
                const SizedBox(height: AppTheme.space3),
                _signOut(),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _identity(User user, List<Membership> memberships) {
    Membership? active;

    for (final membership in memberships) {
      if (membership.isActive) {
        active = membership;
        break;
      }
    }

    active ??= memberships.isEmpty ? null : memberships.first;

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your account',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02 * 11,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            user.name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          Text(
            user.email,
            style: const TextStyle(fontSize: 13, color: AppTheme.muted),
          ),
          if (active != null) ...[
            const SizedBox(height: AppTheme.space3),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Active household',
                        style: TextStyle(fontSize: 11, color: AppTheme.muted),
                      ),
                      Text(
                        active.tenant.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppTheme.ink,
                        ),
                      ),
                    ],
                  ),
                ),
                PriorityChip(label: active.role, tone: WarmTone.primary),
              ],
            ),
          ],
          if (memberships.length > 1) ...[
            const SizedBox(height: AppTheme.space3),
            DropdownButtonFormField<int>(
              initialValue: active?.tenant.id,
              decoration: const InputDecoration(labelText: 'Switch household'),
              items: [
                for (final membership in memberships)
                  DropdownMenuItem<int>(
                    value: membership.tenant.id,
                    child: Text(
                      '${membership.tenant.name} (${membership.role})',
                    ),
                  ),
              ],
              onChanged: (value) {
                if (value != null) {
                  context.read<AuthBloc>().add(TenantSwitchRequested(value));
                }
              },
            ),
          ],
        ],
      ),
    );
  }

  Widget _notifications(User user) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Delivery channels',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Push reminders are delivered by this device once notifications are permitted.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Phone number',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.ink,
                  ),
                ),
              ),
              PriorityChip(
                label: user.phoneVerified ? 'Verified' : 'Not verified',
                tone: user.phoneVerified ? WarmTone.success : WarmTone.danger,
              ),
            ],
          ),
          if (!user.phoneVerified) ...[
            const SizedBox(height: AppTheme.space2),
            SizedBox(
              width: double.infinity,
              child: FilledButton.tonal(
                onPressed: () => context.push('/verify-phone'),
                child: const Text('Verify phone number'),
              ),
            ),
          ],
          const SizedBox(height: AppTheme.space3),
          const Text(
            'Quiet hours are a household-level setting and are configured from the web dashboard.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  Widget _escalation(User user) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Voice call escalation',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Automated calls when an urgent item is overdue. Bounded by a daily budget and quiet hours.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: user.voiceOptIn,
            activeThumbColor: AppTheme.secondary,
            title: const Text('Opt in to voice calls'),
            subtitle: Text(
              user.phoneVerified
                  ? 'You are reachable on your verified number.'
                  : 'Verify your phone number to enable this.',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            onChanged: (value) {
              if (value && !user.phoneVerified) {
                context.push('/verify-phone');
                return;
              }

              context.read<AuthBloc>().add(VoiceConsentChanged(value));
            },
          ),
        ],
      ),
    );
  }

  Widget _locationArrivals(User user) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Arrival notifications',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'When you arrive at a saved place with your own work waiting, you '
            'are told once. Checked while the app is open; nothing is read in '
            'the background, and household quiet hours still apply.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space2),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: user.locationNotificationsOptIn,
            activeThumbColor: AppTheme.secondary,
            title: const Text('Tell me when I arrive'),
            subtitle: Text(
              user.locationNotificationsOptIn
                  ? 'On — location access is needed for this.'
                  : 'Off — no arrival notifications.',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            onChanged: (value) =>
                context.read<AuthBloc>().add(LocationConsentChanged(value)),
          ),
        ],
      ),
    );
  }

  Widget _support() {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Help & feedback',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Something broken, or missing? Tell the platform team — and follow '
            'what happens to it.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonal(
              onPressed: () => context.push('/feedback'),
              child: const Text('Report a problem'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _signOut() {
    return WarmCard(
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton.icon(
          onPressed: () =>
              context.read<AuthBloc>().add(const LogoutRequested()),
          icon: const Icon(Icons.logout, color: AppTheme.error),
          label: const Text(
            'Sign out',
            style: TextStyle(color: AppTheme.error),
          ),
        ),
      ),
    );
  }
}
