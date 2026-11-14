import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/config/app_config.dart';
import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/notifications/local_notifications.dart';
import '../../../../core/storage/secure_storage.dart';
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
  String _selectedCurrency = 'BDT';
  String _dateFormat = 'MMM d, yyyy';
  String _timeFormat = '12h';
  int _defaultDueDays = 3;
  String? _userAvatarKey;
  Map<String, dynamic>? _quotaData;
  Map<String, dynamic>? _calendarFeed;
  String? _customBaseUrl;
  bool _vaultBusy = false;
  String? _vaultStatus;
  bool _vaultStatusError = false;
  bool _quietHoursEnabled = false;
  TimeOfDay _quietStart = const TimeOfDay(hour: 22, minute: 0);
  TimeOfDay _quietEnd = const TimeOfDay(hour: 7, minute: 0);

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const SessionLoaded());
    _loadAvatarAndQuotas();
  }

  Future<void> _loadAvatarAndQuotas() async {
    final storage = getIt<SecureStorage>();
    final savedAvatar = await storage.readUserAvatar();
    final customBaseUrl = await storage.readBaseUrl();
    if (mounted) {
      setState(() {
        _userAvatarKey = savedAvatar;
        _customBaseUrl = customBaseUrl;
      });
    }

    if (!getIt.isRegistered<DioClient>()) return;

    final dio = getIt<DioClient>().dio;

    try {
      final res = await dio.get<Map<String, dynamic>>('/v1/tenant/quotas');
      if (res.data != null && mounted) {
        setState(() => _quotaData = res.data);
      }
    } catch (_) {}

    try {
      final tenantRes = await dio.get<Map<String, dynamic>>('/v1/tenant');
      final payload = tenantRes.data?['data'] is Map
          ? (tenantRes.data!['data'] as Map).cast<String, dynamic>()
          : tenantRes.data;
      final settings = payload?['settings'] is Map
          ? (payload!['settings'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};
      final quiet = settings['quiet_hours'] is Map
          ? (settings['quiet_hours'] as Map).cast<String, dynamic>()
          : <String, dynamic>{};

      if (mounted) {
        setState(() {
          _selectedCurrency =
              settings['currency']?.toString() ?? _selectedCurrency;
          final loadedDate = settings['date_format']?.toString();
          _dateFormat = const [
            'MMM d, yyyy',
            'dd/MM/yyyy',
            'MM/dd/yyyy',
            'yyyy-MM-dd',
          ].contains(loadedDate)
              ? loadedDate!
              : _dateFormat;
          _timeFormat =
              settings['time_format']?.toString() == '24h' ? '24h' : '12h';
          final loadedDue = (settings['default_due_days'] as num?)?.toInt();
          _defaultDueDays = const [1, 3, 5, 7, 14].contains(loadedDue)
              ? loadedDue!
              : _defaultDueDays;
          _quietHoursEnabled = quiet['enabled'] == true;
          _quietStart = _parseTime(quiet['start']?.toString()) ?? _quietStart;
          _quietEnd = _parseTime(quiet['end']?.toString()) ?? _quietEnd;
        });
      }
    } catch (_) {}

    try {
      final feedRes = await dio.get<Map<String, dynamic>>(
        '/v1/calendar/feed-url',
      );
      if (feedRes.data?['data'] is Map && mounted) {
        setState(
          () => _calendarFeed =
              (feedRes.data!['data'] as Map).cast<String, dynamic>(),
        );
      }
    } catch (_) {}
  }

  void _openProfilePhotoPicker(User user) {
    final urlCtrl = TextEditingController(
      text: (_userAvatarKey != null && _userAvatarKey!.startsWith('http'))
          ? _userAvatarKey
          : '',
    );

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.fromLTRB(
          20,
          16,
          20,
          MediaQuery.of(ctx).viewInsets.bottom + 28,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.outline.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Choose Profile Photo',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppTheme.ink,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Select a household portrait avatar or paste a custom image URL.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 14,
              runSpacing: 14,
              children: [
                for (final preset in kPortraitAvatarPresets)
                  GestureDetector(
                    onTap: () async {
                      await getIt<SecureStorage>().saveUserAvatar(preset.key);
                      if (mounted) {
                        setState(() => _userAvatarKey = preset.key);
                      }
                      if (ctx.mounted) Navigator.of(ctx).pop();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Profile photo updated (${preset.label}).',
                            ),
                            backgroundColor: AppTheme.secondary,
                          ),
                        );
                      }
                    },
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  (_userAvatarKey ?? 'portrait_tanvir') ==
                                      preset.key
                                  ? AppTheme.secondary
                                  : Colors.transparent,
                              width: 2.5,
                            ),
                          ),
                          child: UserProfileAvatar(
                            name: user.name,
                            avatarKeyOrUrl: preset.key,
                            radius: 28,
                            showBorder: false,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          preset.label.split(' ').first,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.ink,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'Or custom photo URL (https://...)',
                hintText: 'https://example.com/photo.jpg',
                prefixIcon: Icon(Icons.link_rounded),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () async {
                  final customUrl = urlCtrl.text.trim();
                  if (customUrl.isNotEmpty) {
                    await getIt<SecureStorage>().saveUserAvatar(customUrl);
                    if (mounted) {
                      setState(() => _userAvatarKey = customUrl);
                    }
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                },
                child: const Text('Save Custom Photo URL'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: BlocConsumer<AuthBloc, AuthState>(
          listener: (context, state) {
            if (state is AuthUnauthenticated) {
              context.go('/login');
            } else if (state is AuthFailureState) {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(AppTheme.errorSnackBar(state.message));
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

              // Shimmer loading cards matching Settings cards (Point 5)
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: const [
                  ShimmerWarmCard(height: 150),
                  SizedBox(height: AppTheme.space3),
                  ShimmerWarmCard(height: 130),
                  SizedBox(height: AppTheme.space3),
                  ShimmerWarmCard(height: 110),
                  SizedBox(height: AppTheme.space3),
                  ShimmerWarmCard(height: 140),
                ],
              );
            }

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
              children: [
                _identity(user, memberships),
                const SizedBox(height: AppTheme.space3),
                _planQuotaCard(memberships),
                const SizedBox(height: AppTheme.space3),
                _localizationSettings(),
                const SizedBox(height: AppTheme.space3),
                _notifications(user),
                const SizedBox(height: AppTheme.space3),
                _calendarSync(),
                const SizedBox(height: AppTheme.space3),
                _alerts(user),
                const SizedBox(height: AppTheme.space3),
                _householdDataVault(),
                const SizedBox(height: AppTheme.space3),
                _serverConnection(),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'YOUR ACCOUNT & PROFILE',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                  color: AppTheme.muted,
                ),
              ),
              TextButton.icon(
                style: TextButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _openProfilePhotoPicker(user),
                icon: const Icon(
                  Icons.photo_camera_outlined,
                  size: 14,
                  color: AppTheme.secondary,
                ),
                label: const Text(
                  'Change Photo',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.secondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              GestureDetector(
                onTap: () => _openProfilePhotoPicker(user),
                child: Stack(
                  children: [
                    UserProfileAvatar(
                      name: user.name,
                      avatarKeyOrUrl: _userAvatarKey,
                      radius: 34,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(5),
                        decoration: BoxDecoration(
                          color: AppTheme.secondary,
                          shape: BoxShape.circle,
                          border: Border.all(color: AppTheme.surface, width: 2),
                        ),
                        child: const Icon(
                          Icons.camera_alt_rounded,
                          size: 13,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      user.email,
                      style: const TextStyle(fontSize: 13, color: AppTheme.muted),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        PriorityChip(
                          label: active?.role == 'tenant_admin'
                              ? 'Household Admin'
                              : (active?.role ?? 'Member'),
                          tone: WarmTone.primary,
                        ),
                        if (user.phoneVerified)
                          const PriorityChip(
                            label: 'Phone Verified',
                            tone: WarmTone.success,
                          ),
                        PriorityChip(
                          label: user.emailVerified
                              ? 'Email Verified'
                              : 'Email Unverified',
                          tone: user.emailVerified
                              ? WarmTone.success
                              : WarmTone.warning,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (!user.emailVerified)
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: _resendEmailVerification,
                icon: const Icon(Icons.mark_email_unread_outlined, size: 16),
                label: const Text('Resend email verification'),
              ),
            ),
          const SizedBox(height: AppTheme.space2),
          Wrap(
            spacing: 8,
            children: [
              TextButton.icon(
                onPressed: () => _editProfile(user),
                icon: const Icon(Icons.edit_outlined, size: 16),
                label: const Text('Edit profile'),
              ),
              TextButton.icon(
                onPressed: _changePassword,
                icon: const Icon(Icons.lock_outline_rounded, size: 16),
                label: const Text('Change password'),
              ),
            ],
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
                PriorityChip(
                  label: active.role == 'tenant_admin' ? 'Household Admin' : active.role,
                  tone: WarmTone.primary,
                ),
              ],
            ),
          ],
          if (memberships.length > 1) ...[
            const SizedBox(height: AppTheme.space3),
            DropdownButtonFormField<int>(
              isExpanded: true,
              initialValue: active?.tenant.id,
              decoration: const InputDecoration(labelText: 'Switch household'),
              items: [
                for (final membership in memberships)
                  DropdownMenuItem<int>(
                    value: membership.tenant.id,
                    child: Text(
                      '${membership.tenant.name} (${membership.role == 'tenant_admin' ? 'Household Admin' : membership.role})',
                      overflow: TextOverflow.ellipsis,
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

  Widget _planQuotaCard(List<Membership> memberships) {
    Membership? active;
    for (final m in memberships) {
      if (m.isActive) {
        active = m;
        break;
      }
    }
    active ??= memberships.isEmpty ? null : memberships.first;

    if (_quotaData == null) {
      return WarmCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'SAAS SUBSCRIPTION & PLAN LIMITS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
                color: AppTheme.muted,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Plan limits are unavailable right now.',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Check your connection and try again. The API is the only source of quota data.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _loadAvatarAndQuotas,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Try again'),
            ),
          ],
        ),
      );
    }

    final planMap = _quotaData!['plan'] is Map
        ? (_quotaData!['plan'] as Map).cast<String, dynamic>()
        : null;
    final planLabel =
        planMap?['label']?.toString() ??
        active?.tenant.subscriptionTier ??
        'Household plan';
    final planPrice = planMap?['price']?.toString() ?? '';

    final meters = _quotaData!['meters'] is List
        ? (_quotaData!['meters'] as List)
              .whereType<Map>()
              .map((meter) => meter.cast<String, dynamic>())
              .toList()
        : <Map<String, dynamic>>[];

    return WarmCard(
      borderColor: AppTheme.secondary.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'SAAS SUBSCRIPTION & PLAN LIMITS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                    color: AppTheme.muted,
                  ),
                ),
              ),
              if (planPrice.isNotEmpty)
                PriorityChip(label: planPrice, tone: WarmTone.primary),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            planLabel,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 12),
          if (meters.isEmpty)
            const Text(
              'No quota data available.',
              style: TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
          for (final m in meters) ...[
            Builder(
              builder: (context) {
                final used = (m['used'] as num?)?.toInt() ?? 0;
                final cap = (m['cap'] as num?)?.toInt() ?? 1;
                final ratio = cap > 0 ? (used / cap).clamp(0.0, 1.0) : 1.0;
                final atCap = cap == 0 || used >= cap;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              (m['label'] as String?) ?? '',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppTheme.ink,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Text(
                            cap >= 9999
                                ? '$used / Unlimited'
                                : '$used / $cap${atCap ? " (Limit)" : ""}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: atCap
                                  ? AppTheme.tertiary
                                  : AppTheme.secondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(999),
                        child: LinearProgressIndicator(
                          value: cap >= 9999 ? 0.15 : ratio,
                          minHeight: 6,
                          backgroundColor: AppTheme.forestSoft,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            atCap ? AppTheme.tertiary : AppTheme.secondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
          const SizedBox(height: 4),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => context.push('/billing'),
              icon: const Icon(Icons.workspace_premium_outlined, size: 18),
              label: const Text('Manage Plan & Quotas'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _localizationSettings() {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Household Currency & Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Controls the currency marker across your expense tracker, budgets, and pantry.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<String>(
            isExpanded: true,
            initialValue: _selectedCurrency,
            decoration: const InputDecoration(
              labelText: 'Global Currency Marker',
              prefixIcon: Icon(Icons.currency_exchange_rounded),
            ),
            items: const [
              DropdownMenuItem(value: 'BDT', child: Text('BDT (৳) — Bangladeshi Taka')),
              DropdownMenuItem(value: 'USD', child: Text('USD (\$) — US Dollar')),
              DropdownMenuItem(value: 'EUR', child: Text('EUR (€) — Euro')),
              DropdownMenuItem(value: 'GBP', child: Text('GBP (£) — British Pound')),
              DropdownMenuItem(value: 'CAD', child: Text('CAD (C\$) — Canadian Dollar')),
              DropdownMenuItem(value: 'AUD', child: Text('AUD (A\$) — Australian Dollar')),
              DropdownMenuItem(value: 'INR', child: Text('INR (₹) — Indian Rupee')),
            ],
            onChanged: (val) {
              if (val != null) {
                setState(() => _selectedCurrency = val);
                _saveCurrency(val);
              }
            },
          ),
          const SizedBox(height: AppTheme.space3),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _dateFormat,
                  decoration: const InputDecoration(labelText: 'Date format'),
                  items: const [
                    DropdownMenuItem(
                      value: 'MMM d, yyyy',
                      child: Text('Mar 7, 2026'),
                    ),
                    DropdownMenuItem(
                      value: 'dd/MM/yyyy',
                      child: Text('07/03/2026'),
                    ),
                    DropdownMenuItem(
                      value: 'MM/dd/yyyy',
                      child: Text('03/07/2026'),
                    ),
                    DropdownMenuItem(
                      value: 'yyyy-MM-dd',
                      child: Text('2026-03-07'),
                    ),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _dateFormat = value);
                    _savePreference({'date_format': value});
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: _timeFormat,
                  decoration: const InputDecoration(labelText: 'Time format'),
                  items: const [
                    DropdownMenuItem(value: '12h', child: Text('12-hour')),
                    DropdownMenuItem(value: '24h', child: Text('24-hour')),
                  ],
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _timeFormat = value);
                    _savePreference({'time_format': value});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppTheme.space3),
          DropdownButtonFormField<int>(
            isExpanded: true,
            initialValue: _defaultDueDays,
            decoration: const InputDecoration(
              labelText: 'Default task due window',
            ),
            items: const [
              DropdownMenuItem(value: 1, child: Text('Due in 1 day')),
              DropdownMenuItem(value: 3, child: Text('Due in 3 days')),
              DropdownMenuItem(value: 5, child: Text('Due in 5 days')),
              DropdownMenuItem(value: 7, child: Text('Due in 1 week')),
              DropdownMenuItem(value: 14, child: Text('Due in 2 weeks')),
            ],
            onChanged: (value) {
              if (value == null) return;
              setState(() => _defaultDueDays = value);
              _savePreference({'default_due_days': value});
            },
          ),
        ],
      ),
    );
  }

  Future<void> _savePreference(Map<String, dynamic> settings) async {
    try {
      await getIt<DioClient>().dio.patch<Map<String, dynamic>>(
        '/v1/tenant',
        data: {'settings': settings},
      );
      _snack('Household preferences saved.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _saveCurrency(String currency) async {
    await _savePreference({'currency': currency});
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
          const Divider(height: 24),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            value: _quietHoursEnabled,
            activeThumbColor: AppTheme.secondary,
            title: const Text('Household quiet hours'),
            subtitle: Text(
              _quietHoursEnabled
                  ? 'No calls between ${_labelTime(_quietStart)} and ${_labelTime(_quietEnd)}.'
                  : 'Off — automated calls may arrive at any hour.',
              style: const TextStyle(fontSize: 12, color: AppTheme.muted),
            ),
            onChanged: (value) {
              setState(() => _quietHoursEnabled = value);
              _saveQuietHours();
            },
          ),
          if (_quietHoursEnabled)
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickQuietHour(start: true),
                    icon: const Icon(Icons.bedtime_outlined, size: 16),
                    label: Text('Starts ${_labelTime(_quietStart)}'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickQuietHour(start: false),
                    icon: const Icon(Icons.wb_sunny_outlined, size: 16),
                    label: Text('Ends ${_labelTime(_quietEnd)}'),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _calendarSync() {
    final feedUrl = _calendarFeed?['feed_url']?.toString();
    final webcalUrl = _calendarFeed?['webcal_url']?.toString();

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.calendar_month_outlined, size: 20, color: AppTheme.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Calendar sync',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Subscribe to your errands from Google Calendar, Apple Calendar or Outlook. The feed is read-only and private to your household.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),
          if (feedUrl == null || feedUrl.isEmpty)
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: _loadCalendarFeed,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Load calendar feed'),
              ),
            )
          else ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.canvas,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
              ),
              child: SelectableText(
                feedUrl,
                style: const TextStyle(fontSize: 11, color: AppTheme.ink),
              ),
            ),
            const SizedBox(height: AppTheme.space2),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _copyText(feedUrl, 'Calendar feed URL copied.'),
                    icon: const Icon(Icons.copy_rounded, size: 16),
                    label: const Text('Copy'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: () => _openCalendar(webcalUrl ?? feedUrl),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: const Text('Subscribe'),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Future<void> _loadCalendarFeed() async {
    try {
      final response = await getIt<DioClient>().dio.get<Map<String, dynamic>>(
        '/v1/calendar/feed-url',
      );
      if (response.data?['data'] is Map && mounted) {
        setState(
          () => _calendarFeed =
              (response.data!['data'] as Map).cast<String, dynamic>(),
        );
      }
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _openCalendar(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) return;

    if (!await launchUrl(uri, mode: LaunchMode.externalApplication) &&
        mounted) {
      _snack('No calendar app accepted the subscription link.', error: true);
    }
  }

  Future<void> _pickQuietHour({required bool start}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: start ? _quietStart : _quietEnd,
    );
    if (picked == null) return;

    setState(() {
      if (start) {
        _quietStart = picked;
      } else {
        _quietEnd = picked;
      }
    });
    _saveQuietHours();
  }

  Future<void> _saveQuietHours() async {
    try {
      await getIt<DioClient>().dio.patch<Map<String, dynamic>>(
        '/v1/tenant',
        data: {
          'settings': {
            'quiet_hours': {
              'enabled': _quietHoursEnabled,
              'start': _formatTime(_quietStart),
              'end': _formatTime(_quietEnd),
            },
          },
        },
      );
      _snack(_quietHoursEnabled ? 'Quiet hours saved.' : 'Quiet hours disabled.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _resendEmailVerification() async {
    try {
      await getIt<DioClient>().dio.post<void>('/v1/auth/email/resend');
      _snack('Verification email sent.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _editProfile(User user) async {
    final name = TextEditingController(text: user.name);
    final email = TextEditingController(text: user.email);
    final phone = TextEditingController(text: user.phone ?? '');

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                decoration: const InputDecoration(labelText: 'Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  hintText: '+880...',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final nextName = name.text.trim();
              final nextEmail = email.text.trim();
              if (nextName.isEmpty || nextEmail.isEmpty) return;

              Navigator.of(ctx).pop({
                'name': nextName,
                'email': nextEmail,
                'phone': phone.text.trim(),
              });
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    name.dispose();
    email.dispose();
    phone.dispose();

    if (result == null) return;

    try {
      await getIt<DioClient>().dio.patch<Map<String, dynamic>>(
        '/v1/auth/me',
        data: result,
      );
      if (mounted) {
        context.read<AuthBloc>().add(const SessionLoaded());
        _snack('Profile updated.');
      }
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _changePassword() async {
    final current = TextEditingController();
    final next = TextEditingController();
    final confirm = TextEditingController();

    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Change password'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: current,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Current password'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: next,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'New password',
                  helperText: 'At least 8 characters',
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: confirm,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Confirm new password'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (current.text.isEmpty ||
                  next.text.length < 8 ||
                  next.text != confirm.text) {
                return;
              }

              Navigator.of(ctx).pop({
                'current_password': current.text,
                'password': next.text,
                'password_confirmation': confirm.text,
              });
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );

    current.dispose();
    next.dispose();
    confirm.dispose();

    if (result == null) return;

    try {
      await getIt<DioClient>().dio.post<Map<String, dynamic>>(
        '/v1/auth/me/password',
        data: result,
      );
      _snack('Password updated.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _copyHouseholdVault() async {
    if (_vaultBusy) return;

    setState(() => _vaultBusy = true);

    try {
      final response = await getIt<DioClient>().dio.get<dynamic>(
        '/v1/tenant/export',
      );
      final text = const JsonEncoder.withIndent('  ').convert(response.data);

      await Clipboard.setData(ClipboardData(text: text));
      if (mounted) {
        setState(() {
          _vaultStatus = 'Copied to clipboard (${text.length} characters).';
          _vaultStatusError = false;
        });
      }
      _snack('Household vault copied to clipboard (${text.length} chars).');
    } catch (error) {
      final message = _message(error);
      if (mounted) {
        setState(() {
          _vaultStatus = message;
          _vaultStatusError = true;
        });
      }
      _snack(message, error: true);
    } finally {
      if (mounted) setState(() => _vaultBusy = false);
    }
  }

  Future<void> _copyText(String value, String message) async {
    await Clipboard.setData(ClipboardData(text: value));
    _snack(message);
  }

  TimeOfDay? _parseTime(String? value) {
    if (value == null || !value.contains(':')) return null;

    final parts = value.split(':');
    final hour = int.tryParse(parts[0]);
    final minute = int.tryParse(parts[1]);
    if (hour == null || minute == null) return null;

    return TimeOfDay(hour: hour, minute: minute);
  }

  String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');

    return '$hour:$minute';
  }

  String _labelTime(TimeOfDay time) {
    final hour = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.period == DayPeriod.am ? 'AM' : 'PM';

    return '$hour:$minute $suffix';
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      error ? AppTheme.errorSnackBar(message) : AppTheme.successSnackBar(message),
    );
  }

  String _message(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map && data['message'] is String) {
        return data['message'] as String;
      }

      return error.message ?? 'Request failed.';
    }

    if (error is Exception) {
      return error.toString().replaceFirst('Exception: ', '');
    }

    return 'Something went wrong.';
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

  Widget _householdDataVault() {
    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shield_outlined, size: 20, color: AppTheme.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Household Data Vault & Portability',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'Copy your household records — errands, pantry stock, expenses and saved places — as machine-readable JSON.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space3),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _vaultBusy ? null : _copyHouseholdVault,
              icon: _vaultBusy
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.copy_all_rounded, size: 18),
              label: Text(
                _vaultBusy
                    ? 'Copying household vault…'
                    : 'Copy Household Vault (.json)',
              ),
            ),
          ),
          if (_vaultStatus != null) ...[
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  _vaultStatusError
                      ? Icons.error_outline_rounded
                      : Icons.check_circle_outline_rounded,
                  size: 15,
                  color: _vaultStatusError
                      ? AppTheme.error
                      : AppTheme.secondary,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _vaultStatus!,
                    style: TextStyle(
                      fontSize: 11,
                      color: _vaultStatusError
                          ? AppTheme.error
                          : AppTheme.secondary,
                    ),
                  ),
                ),
              ],
            ),
          ],
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: FilledButton.tonalIcon(
              onPressed: () => context.push('/billing'),
              icon: const Icon(Icons.credit_card_rounded, size: 18),
              label: const Text('Manage Plan & Quotas in Billing'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _serverConnection() {
    final effective = (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty)
        ? _customBaseUrl!.trim()
        : AppConfig.apiBaseUrl;

    return WarmCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.dns_outlined, size: 20, color: AppTheme.secondary),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Server connection',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          const Text(
            'The API host this app talks to. Change it if your household server moves to a different address.',
            style: TextStyle(fontSize: 12, color: AppTheme.muted),
          ),
          const SizedBox(height: AppTheme.space2),
          SelectableText(
            effective,
            style: const TextStyle(fontSize: 11, color: AppTheme.ink),
          ),
          const SizedBox(height: AppTheme.space2),
          OutlinedButton.icon(
            onPressed: _editServerConnection,
            icon: const Icon(Icons.edit_outlined, size: 16),
            label: const Text('Change server address'),
          ),
        ],
      ),
    );
  }

  Future<void> _editServerConnection() async {
    final controller = TextEditingController(
      text: (_customBaseUrl != null && _customBaseUrl!.trim().isNotEmpty)
          ? _customBaseUrl
          : AppConfig.apiBaseUrl,
    );

    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Server address'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.url,
          decoration: const InputDecoration(
            labelText: 'API base URL',
            hintText: 'http://192.168.0.10:8000/mobile',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );

    controller.dispose();
    if (result == null) return;

    if (result.isNotEmpty &&
        !result.startsWith('http://') &&
        !result.startsWith('https://')) {
      _snack('Use a full http:// or https:// address.', error: true);
      return;
    }

    await getIt<SecureStorage>().saveBaseUrl(result);
    if (!mounted) return;
    setState(() => _customBaseUrl = result.isEmpty ? null : result);
    await _loadAvatarAndQuotas();
    _snack('Server address saved.');
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
