import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class HouseholdAppDrawer extends StatelessWidget {
  const HouseholdAppDrawer({super.key, required this.currentLocation});

  final String currentLocation;

  void _showMembersSheet(BuildContext context) {
    Navigator.of(context).pop(); // Close drawer
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
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
              const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Household Members',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.ink),
                  ),
                  Text('2 Active', style: TextStyle(fontSize: 13, color: AppTheme.muted)),
                ],
              ),
              const SizedBox(height: 14),
              _memberTile(
                name: 'Tanvir Rahman',
                email: 'tanvir@familyessentials.app',
                role: 'Household Admin',
                isAdmin: true,
              ),
              const SizedBox(height: 10),
              _memberTile(
                name: 'Sarah Rahman',
                email: 'sarah@familyessentials.app',
                role: 'Household Member',
                isAdmin: false,
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(ctx).pop();
                    _showInviteDialog(context);
                  },
                  icon: const Icon(Icons.person_add_alt_1, size: 18),
                  label: const Text('Invite Family Member'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _showInviteDialog(BuildContext context) {
    final emailCtrl = TextEditingController();
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Invite to Household'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter their email address to send a secure household invitation link.',
              style: TextStyle(fontSize: 13, color: AppTheme.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                labelText: 'Family member email',
                hintText: 'e.g. alex@example.com',
                prefixIcon: Icon(Icons.email_outlined),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Invitation sent! They can join using the link.'),
                  backgroundColor: AppTheme.secondary,
                ),
              );
            },
            child: const Text('Send Invite'),
          ),
        ],
      ),
    );
  }

  static Widget _memberTile({
    required String name,
    required String email,
    required String role,
    required bool isAdmin,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.canvas,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: isAdmin ? AppTheme.secondary : AppTheme.primaryContainer,
            foregroundColor: Colors.white,
            radius: 20,
            child: Text(name.isNotEmpty ? name[0] : 'U', style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                Text(email, style: const TextStyle(fontSize: 12, color: AppTheme.muted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: isAdmin ? AppTheme.forestSoft : AppTheme.sageSoft,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              role,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.bold,
                color: isAdmin ? AppTheme.secondary : AppTheme.muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: AppTheme.surface,
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          String userName = 'Tanvir Rahman';
          String userEmail = 'tanvir@familyessentials.app';
          String householdName = 'The Tanvir Household';

          if (state is AuthMembershipsLoaded) {
            userName = state.user.name;
            userEmail = state.user.email;
            householdName = state.activeMembership?.tenant.name ?? householdName;
          } else if (state is AuthAuthenticated) {
            userName = state.user.name;
            userEmail = state.user.email;
          }

          return Column(
            children: [
              // Header
              Container(
                width: double.infinity,
                padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 20, 20, 20),
                decoration: const BoxDecoration(
                  color: AppTheme.forestSoft,
                  border: Border(bottom: BorderSide(color: Color(0x1F2B2D42))),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 26,
                          backgroundColor: AppTheme.secondary,
                          foregroundColor: Colors.white,
                          child: Text(
                            userName.isNotEmpty ? userName[0].toUpperCase() : 'F',
                            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w800,
                                  color: AppTheme.ink,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                userEmail,
                                style: const TextStyle(fontSize: 12, color: AppTheme.muted),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppTheme.outline.withValues(alpha: 0.3)),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.home_work_outlined, size: 16, color: AppTheme.secondary),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    householdName,
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.shield, size: 12, color: Colors.white),
                              SizedBox(width: 4),
                              Text(
                                'Household Admin',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Drawer Nav Items
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  children: [
                    _sectionLabel('HOUSEHOLD ACTIVITIES'),
                    _drawerItem(
                      context,
                      icon: Icons.today_rounded,
                      label: "Today's Daily Hub",
                      path: '/today',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.shopping_basket_rounded,
                      label: 'Shopping & Errands',
                      path: '/shopping',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.auto_awesome,
                      label: 'AI Family Dispatcher & Chat',
                      path: '/chat',
                      isHighlight: true,
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.add_task_rounded,
                      label: 'Add Request / Errand',
                      path: '/requests/new',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('FINANCES & BUDGET'),
                    _drawerItem(
                      context,
                      icon: Icons.account_balance_wallet_rounded,
                      label: 'Household Expense Tracker',
                      path: '/budget',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.credit_card_rounded,
                      label: 'Billing & Subscription',
                      path: '/billing',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('PANTRY & SHOPPING'),
                    _drawerItem(
                      context,
                      icon: Icons.inventory_2_outlined,
                      label: 'Pantry Pulse & Stock',
                      path: '/pantry',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.document_scanner_outlined,
                      label: 'Receipt Scanner (OCR)',
                      path: '/receipt/scan',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.pin_drop_outlined,
                      label: 'Saved Places & Stores',
                      path: '/places',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('PEOPLE & RULES'),
                    ListTile(
                      leading: const Icon(Icons.group_outlined, size: 22, color: AppTheme.ink),
                      title: const Text('Household Members', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      onTap: () => _showMembersSheet(context),
                      dense: true,
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.event_repeat_rounded,
                      label: 'Recurring Chore Rules',
                      path: '/recurring',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('SETTINGS & SUPPORT'),
                    _drawerItem(
                      context,
                      icon: Icons.tune_rounded,
                      label: 'Reminders & Settings',
                      path: '/settings',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Feedback',
                      path: '/feedback',
                    ),
                    ListTile(
                      leading: const Icon(Icons.logout_rounded, size: 22, color: AppTheme.error),
                      title: const Text('Log out', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.error)),
                      dense: true,
                      onTap: () {
                        Navigator.of(context).pop();
                        context.read<AuthBloc>().add(const LogoutRequested());
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.8,
          color: AppTheme.muted,
        ),
      ),
    );
  }

  Widget _drawerItem(
    BuildContext context, {
    required IconData icon,
    required String label,
    required String path,
    bool isHighlight = false,
  }) {
    final isSelected = currentLocation == path;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      child: Container(
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.forestSoft
              : (isHighlight ? AppTheme.forestSoft.withValues(alpha: 0.4) : Colors.transparent),
          borderRadius: BorderRadius.circular(10),
        ),
        child: ListTile(
          dense: true,
          leading: Icon(
            icon,
            size: 22,
            color: isSelected ? AppTheme.secondary : (isHighlight ? AppTheme.secondary : AppTheme.ink),
          ),
          title: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
              color: isSelected ? AppTheme.secondary : AppTheme.ink,
            ),
          ),
          trailing: isHighlight
              ? Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppTheme.secondary,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text('AI', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.white)),
                )
              : null,
          onTap: () {
            Navigator.of(context).pop(); // Close drawer
            if (path == currentLocation) return;
            if (path == '/requests/new' ||
                path == '/billing' ||
                path == '/receipt/scan' ||
                path == '/chat' ||
                path == '/feedback') {
              context.push(path);
            } else if (path.startsWith('/')) {
              context.go(path);
            }
          },
        ),
      ),
    );
  }
}
