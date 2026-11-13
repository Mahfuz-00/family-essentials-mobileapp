import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../theme/warm_widgets.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';

class HouseholdAppDrawer extends StatelessWidget {
  const HouseholdAppDrawer({super.key, required this.currentLocation});

  final String currentLocation;

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
                        UserProfileAvatar(
                          name: userName,
                          radius: 26,
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
                      label: "Today's Pulse",
                      path: '/today',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.shopping_basket_rounded,
                      label: 'Errands & Tasks',
                      path: '/shopping',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.auto_awesome,
                      label: 'Household Chat & AI',
                      path: '/chat',
                      isHighlight: true,
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.ring_volume_outlined,
                      label: 'Voice Escalations',
                      path: '/voice-escalations',
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
                      label: 'Expenses & Money',
                      path: '/budget',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.credit_card_rounded,
                      label: 'Plan & Billing',
                      path: '/billing',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('PANTRY & SHOPPING'),
                    _drawerItem(
                      context,
                      icon: Icons.inventory_2_outlined,
                      label: 'Pantry Inventory',
                      path: '/pantry',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.document_scanner_outlined,
                      label: 'Receipt Scanner',
                      path: '/receipt/scan',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.pin_drop_outlined,
                      label: 'Places & Geofences',
                      path: '/places',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('PEOPLE & RULES'),
                    _drawerItem(
                      context,
                      icon: Icons.group_outlined,
                      label: 'Family & Access',
                      path: '/household',
                    ),
                    _drawerItem(
                      context,
                      icon: Icons.event_repeat_rounded,
                      label: 'Recurring Tasks',
                      path: '/recurring',
                    ),

                    const Divider(height: 16),
                    _sectionLabel('SETTINGS & SUPPORT'),
                    _drawerItem(
                      context,
                      icon: Icons.tune_rounded,
                      label: 'Settings',
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
                path == '/feedback' ||
                path == '/household' ||
                path == '/voice-escalations' ||
                path == '/pantry' ||
                path == '/recurring') {
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
