import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/notifications/local_notifications.dart';
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
              // A failed me() leaves the user null for good, so say so and offer
              // the one action that can fix it instead of spinning forever.
              if (state is AuthFailureState) {
                return Padding(
                  padding: const EdgeInsets.all(AppTheme.space4),
                  child: WarmEmptyState(
                    title: 'Your settings did not load',
                    description:
                        '${state.message}\nCheck your connection and try again.',
                    icon: Icons.cloud_off_outlined,
                    action: FilledButton(
                      onPressed: () =>
                          context.read<AuthBloc>().add(const SessionLoaded()),
                      child: const Text('Try again'),
                    ),
                  ),
                );
              }

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
                _alerts(user),
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

  /// One card for everything about interruption: how it announces itself, what
  /// it announces, and whether it may call.
  Widget _alerts(User user) {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Alerts',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'How the app reaches you, and how loudly. Household quiet hours always win.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),

          const Text(
            'HOW IT ANNOUNCES ITSELF',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02 * 11,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Wrap(
            spacing: AppTheme.space2,
            runSpacing: AppTheme.space2,
            children: [
              for (final style in LocalNotifications.arrivalStyles)
                ChoiceChip(
                  selected: user.alertStyle == style,
                  onSelected: (_) =>
                      context.read<AuthBloc>().add(AlertStyleChanged(style)),
                  showCheckmark: false,
                  selectedColor: AppTheme.forestSoft,
                  backgroundColor: AppTheme.surface,
                  side: BorderSide(
                    color: user.alertStyle == style
                        ? AppTheme.secondary
                        : const Color(0x1F2B2D42),
                  ),
                  label: Text(
                    _styleLabel(style),
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: user.alertStyle == style
                          ? AppTheme.secondary
                          : AppTheme.ink,
                    ),
                  ),
                ),
            ],
          ),
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              onPressed: () =>
                  getIt<LocalNotifications>().preview(user.alertStyle),
              icon: const Icon(Icons.play_arrow, size: 18),
              label: const Text('Preview'),
            ),
          ),
          const Text(
            'Voice speaks the line when you open the notification. iOS cannot '
            'speak from a push, and neither platform can while the app is closed.',
            style: TextStyle(fontSize: 11, color: AppTheme.muted),
          ),

          const Divider(height: 24),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: user.locationNotificationsOptIn,
            activeThumbColor: AppTheme.secondary,
            title: const Text('Tell me when I arrive or leave'),
            subtitle: Text(
              user.locationNotificationsOptIn
                  ? 'On — checked while the app is open.'
                  : 'Off — no arrival notifications.',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            onChanged: (value) =>
                context.read<AuthBloc>().add(LocationConsentChanged(value)),
          ),

          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: user.voiceOptIn,
            activeThumbColor: AppTheme.secondary,
            title: const Text('Call me for urgent overdue tasks'),
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

  String _styleLabel(String style) => switch (style) {
    'silent' => 'Silent',
    'vibrate' => 'Vibrate',
    'voice' => 'Voice',
    _ => 'Sound',
  };

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
