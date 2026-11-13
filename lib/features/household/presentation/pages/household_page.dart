import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/household_remote_datasource.dart';

/// Tenant-facing household administration: the app counterpart of the web
/// dashboard's Members, Roles and Invitations modules.
class HouseholdPage extends StatefulWidget {
  const HouseholdPage({super.key});

  @override
  State<HouseholdPage> createState() => _HouseholdPageState();
}

class _HouseholdPageState extends State<HouseholdPage> {
  late final HouseholdRemoteDataSource _api;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _members = [];
  List<Map<String, dynamic>> _invitations = [];
  List<Map<String, dynamic>> _roles = [];
  List<Map<String, dynamic>> _capabilities = [];
  bool _canManageRoles = false;

  @override
  void initState() {
    super.initState();
    _api = HouseholdRemoteDataSource(getIt<DioClient>());
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
      final results = await Future.wait<dynamic>([
        _api.members(),
        _api.roleCatalogue(),
        _api.invitations(),
      ]);

      final catalogue = results[1] as Map<String, dynamic>;

      if (!mounted) return;

      setState(() {
        _members = results[0] as List<Map<String, dynamic>>;
        _roles = _asList(catalogue['roles']);
        _capabilities = _asList(catalogue['capabilities']);
        _canManageRoles = catalogue['can_manage_roles'] == true;
        _invitations = results[2] as List<Map<String, dynamic>>;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load the household roster. Pull to retry.';
      });
    }
  }

  int? get _currentUserId {
    final state = context.read<AuthBloc>().state;
    if (state is AuthMembershipsLoaded) return state.user.id;
    if (state is AuthAuthenticated) return state.user.id;
    return null;
  }

  String? get _currentRole {
    final id = _currentUserId;
    if (id == null) return null;

    for (final member in _members) {
      if (member['user_id'] == id) return member['role']?.toString();
    }

    return null;
  }

  bool get _canInvite {
    final role = _currentRole;
    return _canManageRoles || role == 'co_admin' || role == 'tenant_admin';
  }

  String _roleLabel(String? key) {
    for (final role in _roles) {
      if (role['key'] == key) return role['label']?.toString() ?? key ?? '—';
    }

    return key ?? '—';
  }

  List<Map<String, dynamic>> get _grantableRoles => _roles
      .where((role) => role['can_be_granted'] == true)
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: const Text('Family & Access'),
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
            : _error != null
                ? _ErrorState(message: _error!, onRetry: _load)
                : ListView(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                    children: [
                      _membersSection(),
                      const SizedBox(height: 24),
                      _invitationsSection(),
                      const SizedBox(height: 24),
                      _rolesSection(),
                    ],
                  ),
      ),
    );
  }

  Widget _sectionHeader(String title, {String? subtitle, Widget? action}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.ink,
                ),
              ),
              if (subtitle case final text?)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    text,
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                ),
            ],
          ),
        ),
        ?action,
      ],
    );
  }

  Widget _membersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Members (${_members.length})',
          subtitle: 'One named owner per errand, with roles enforced by the API.',
        ),
        const SizedBox(height: 10),
        ..._members.map(_memberCard),
      ],
    );
  }

  Widget _memberCard(Map<String, dynamic> member) {
    final userId = member['user_id'] as int?;
    final isSelf = userId != null && userId == _currentUserId;
    final role = member['role']?.toString();
    final phone = member['phone']?.toString();
    final openAssignments = member['open_assignments'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            radius: 21,
            backgroundColor: AppTheme.forestSoft,
            child: Text(
              _initials(member['name']?.toString() ?? '?'),
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        member['name']?.toString() ?? 'Member',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.ink,
                        ),
                      ),
                    ),
                    if (isSelf)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Text(
                          'You',
                          style: TextStyle(fontSize: 10, color: AppTheme.muted),
                        ),
                      ),
                  ],
                ),
                if (member['email'] != null)
                  Text(
                    member['email'].toString(),
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                if (phone != null && phone.isNotEmpty)
                  Text(
                    phone,
                    style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                  ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _chip(_roleLabel(role), AppTheme.sageSoft, AppTheme.secondary),
                    _chip(
                      '$openAssignments open',
                      AppTheme.canvas,
                      AppTheme.muted,
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (_canManageRoles && !isSelf)
            PopupMenuButton<String>(
              tooltip: 'Change role',
              icon: const Icon(Icons.more_vert_rounded, size: 20),
              onSelected: (nextRole) => _changeRole(userId, member, nextRole),
              itemBuilder: (context) => _roles
                  .where((role) => role['can_be_granted'] == true)
                  .map(
                    (role) => PopupMenuItem<String>(
                      value: role['key']?.toString() ?? '',
                      child: Text(role['label']?.toString() ?? ''),
                    ),
                  )
                  .toList(),
            ),
          if (_canManageRoles && !isSelf)
            IconButton(
              tooltip: 'Remove member',
              visualDensity: VisualDensity.compact,
              icon: const Icon(
                Icons.person_remove_outlined,
                size: 20,
                color: AppTheme.error,
              ),
              onPressed: () => _confirmRemove(userId, member),
            ),
        ],
      ),
    );
  }

  Widget _invitationsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Invitations (${_invitations.length})',
          subtitle: 'A pending invitation holds a seat under the plan cap.',
          action: _canInvite
              ? TextButton.icon(
                  onPressed: _showInviteDialog,
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Invite'),
                )
              : null,
        ),
        const SizedBox(height: 8),
        if (_invitations.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No pending invitations.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
          )
        else
          ..._invitations.map(_invitationCard),
      ],
    );
  }

  Widget _invitationCard(Map<String, dynamic> invitation) {
    final expires = DateTime.tryParse(
      invitation['expires_at']?.toString() ?? '',
    )?.toLocal();
    final pending = invitation['status'] == 'pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mail_outline_rounded, size: 20, color: AppTheme.secondary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation['email']?.toString() ?? '—',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                Text(
                  '${_roleLabel(invitation['role']?.toString())}'
                  '${expires == null ? '' : ' · expires ${_date(expires)}'}'
                  '${pending ? '' : ' · ${invitation['status']}'}',
                  style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                ),
              ],
            ),
          ),
          if (pending)
            IconButton(
              tooltip: 'Revoke invitation',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.close_rounded, size: 18, color: AppTheme.error),
              onPressed: () => _revokeInvitation(invitation),
            ),
        ],
      ),
    );
  }

  Widget _rolesSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          'Roles & permissions',
          subtitle: 'Served from the same declaration the API enforces.',
        ),
        const SizedBox(height: 10),
        ..._roles.map(
          (role) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppTheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.outline.withValues(alpha: 0.18)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          role['label']?.toString() ?? '',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                        Text(
                          role['detail']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                        ),
                      ],
                    ),
                  ),
                  _chip(
                    '${role['member_count'] ?? 0}',
                    AppTheme.forestSoft,
                    AppTheme.secondary,
                  ),
                ],
              ),
            ),
          ),
        ),
        if (_capabilities.isNotEmpty) ...[
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowHeight: 34,
              dataRowMinHeight: 34,
              dataRowMaxHeight: 44,
              columnSpacing: 18,
              columns: [
                const DataColumn(
                  label: Text(
                    'Permission',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
                  ),
                ),
                ..._roles.map(
                  (role) => DataColumn(
                    label: Text(
                      role['label']?.toString() ?? '',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                    ),
                  ),
                ),
              ],
              rows: _capabilities.map((capability) {
                final access = (capability['access'] as Map?) ?? const {};

                return DataRow(
                  cells: [
                    DataCell(
                      SizedBox(
                        width: 160,
                        child: Text(
                          capability['label']?.toString() ?? '',
                          style: const TextStyle(fontSize: 11),
                        ),
                      ),
                    ),
                    ..._roles.map(
                      (role) => DataCell(
                        access[role['key']] == true
                            ? const Icon(
                                Icons.check_circle_rounded,
                                size: 16,
                                color: AppTheme.secondary,
                              )
                            : const Icon(
                                Icons.remove_rounded,
                                size: 16,
                                color: AppTheme.outline,
                              ),
                      ),
                    ),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _changeRole(
    int? userId,
    Map<String, dynamic> member,
    String role,
  ) async {
    if (userId == null || role.isEmpty) return;

    try {
      await _api.updateRole(userId, role);
      await _load();
      _snack('${member['name'] ?? 'Member'} is now ${_roleLabel(role)}.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _confirmRemove(int? userId, Map<String, dynamic> member) async {
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Remove member?'),
        content: Text(
          '${member['name'] ?? 'This member'} will lose access to this household.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Remove'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _api.removeMember(userId);
      await _load();
      _snack('Member removed.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _revokeInvitation(Map<String, dynamic> invitation) async {
    final id = invitation['id'] as int?;
    if (id == null) return;

    try {
      await _api.revokeInvitation(id);
      await _load();
      _snack('Invitation revoked.');
    } catch (error) {
      _snack(_message(error), error: true);
    }
  }

  Future<void> _showInviteDialog() async {
    final emailController = TextEditingController();
    final available = _grantableRoles;
    var role = available.isNotEmpty ? available.first['key']?.toString() ?? '' : '';

    await showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: const Text('Invite to household'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email address',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role.isEmpty ? null : role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: available
                    .map(
                      (item) => DropdownMenuItem<String>(
                        value: item['key']?.toString() ?? '',
                        child: Text(item['label']?.toString() ?? ''),
                      ),
                    )
                    .toList(),
                onChanged: (value) => setDialogState(() => role = value ?? ''),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () async {
                final email = emailController.text.trim();
                if (email.isEmpty || role.isEmpty) return;

                Navigator.of(ctx).pop();

                try {
                  await _api.invite(email, role);
                  await _load();
                  _snack('Invitation sent to $email.');
                } catch (error) {
                  _snack(_message(error), error: true);
                }
              },
              child: const Text('Send invite'),
            ),
          ],
        ),
      ),
    );
  }

  void _snack(String message, {bool error = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      error ? AppTheme.errorSnackBar(message) : AppTheme.successSnackBar(message),
    );
  }

  String _message(Object error) {
    if (error is Exception) {
      final text = error.toString().replaceFirst('Exception: ', '');
      return text.isEmpty ? 'Something went wrong.' : text;
    }

    return 'Something went wrong.';
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return '?';
    if (parts.length == 1) return parts.first[0].toUpperCase();
    return (parts.first[0] + parts.last[0]).toUpperCase();
  }

  String _date(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }

  Widget _chip(String label, Color background, Color foreground) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: foreground),
      ),
    );
  }

  List<Map<String, dynamic>> _asList(dynamic value) {
    return (value as List? ?? const [])
        .whereType<Map>()
        .map((item) => item.cast<String, dynamic>())
        .toList();
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        const Icon(Icons.cloud_off_rounded, size: 42, color: AppTheme.muted),
        const SizedBox(height: 12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13, color: AppTheme.muted),
        ),
        const SizedBox(height: 16),
        Center(
          child: FilledButton(onPressed: onRetry, child: const Text('Try again')),
        ),
      ],
    );
  }
}
