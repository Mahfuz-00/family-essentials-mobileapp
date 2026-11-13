import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';
import '../../features/auth/presentation/bloc/auth_state.dart';
import 'household_app_drawer.dart';

/// Persistent bottom navigation & unified top app bar with Drawer menu.
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.location, required this.child});

  final String location;
  final Widget child;

  static const destinations =
      <({String path, String label, IconData icon, IconData activeIcon})>[
        (
          path: '/today',
          label: 'Today',
          icon: Icons.today_outlined,
          activeIcon: Icons.today,
        ),
        (
          path: '/shopping',
          label: 'Errands',
          icon: Icons.shopping_basket_outlined,
          activeIcon: Icons.shopping_basket,
        ),
        (
          path: '/budget',
          label: 'Money',
          icon: Icons.account_balance_wallet_outlined,
          activeIcon: Icons.account_balance_wallet,
        ),
        (
          path: '/places',
          label: 'Places',
          icon: Icons.pin_drop_outlined,
          activeIcon: Icons.pin_drop,
        ),
        (
          path: '/settings',
          label: 'Settings',
          icon: Icons.tune_outlined,
          activeIcon: Icons.tune,
        ),
      ];

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    // Load active household session
    context.read<AuthBloc>().add(const SessionLoaded());
  }

  static const _tabAliases = <String, int>{
    '/pantry': 1,
    '/recurring': 0,
    '/ledger': 2,
  };

  int get _index {
    for (final alias in _tabAliases.entries) {
      if (widget.location.startsWith(alias.key)) {
        return alias.value;
      }
    }

    final match = MainShell.destinations.indexWhere(
      (entry) => widget.location.startsWith(entry.path),
    );

    return match < 0 ? 0 : match;
  }

  String _titleFor(String loc) {
    if (loc.startsWith('/today')) return "Today's Pulse";
    if (loc.startsWith('/shopping')) return 'Errands & Tasks';
    if (loc.startsWith('/budget') || loc.startsWith('/ledger')) return 'Expenses & Money';
    if (loc.startsWith('/places')) return 'Places & Geofences';
    if (loc.startsWith('/settings')) return 'Settings';
    if (loc.startsWith('/pantry')) return 'Pantry Inventory';
    if (loc.startsWith('/recurring')) return 'Recurring Tasks';
    return 'Family Essentials';
  }

  bool get _isSubRoute {
    return widget.location == '/pantry' || widget.location == '/recurring';
  }

  @override
  Widget build(BuildContext context) {
    final isToday = widget.location.startsWith('/today');

    return PopScope(
      canPop: isToday,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          if (context.canPop()) {
            context.pop();
          } else {
            context.go('/today');
          }
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        drawer: HouseholdAppDrawer(currentLocation: widget.location),
        appBar: AppBar(
          leading: _isSubRoute
              ? IconButton(
                  icon: const Icon(Icons.arrow_back),
                  tooltip: 'Back',
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/today');
                    }
                  },
                )
              : IconButton(
                  icon: const Icon(Icons.menu),
                  tooltip: 'Open Menu',
                  onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                ),
          title: BlocBuilder<AuthBloc, AuthState>(
            builder: (context, state) {
              String hName = 'The Tanvir Household';
              if (state is AuthMembershipsLoaded) {
                hName = state.activeMembership?.tenant.name ?? hName;
              }
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _titleFor(widget.location),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.ink,
                    ),
                  ),
                  Text(
                    hName,
                    style: const TextStyle(fontSize: 11, color: AppTheme.muted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              );
            },
          ),
          actions: [
            if (_isSubRoute)
              IconButton(
                tooltip: 'Open Menu',
                icon: const Icon(Icons.menu),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
              ),
            IconButton(
              tooltip: 'Household Chat & AI',
              icon: const Icon(Icons.auto_awesome, color: AppTheme.secondary),
              onPressed: () => context.push('/chat'),
            ),
            IconButton(
              tooltip: 'Receipt Scanner',
              icon: const Icon(Icons.document_scanner_outlined),
              onPressed: () => context.push('/receipt/scan'),
            ),
            const SizedBox(width: 4),
          ],
        ),
        body: widget.child,
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            border: Border(
              top: BorderSide(color: AppTheme.outline.withValues(alpha: 0.25)),
            ),
            boxShadow: [
              BoxShadow(
                color: AppTheme.ink.withValues(alpha: 0.04),
                blurRadius: 12,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: [
                  for (var i = 0; i < MainShell.destinations.length; i++)
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        child: _BottomNavPillItem(
                          entry: MainShell.destinations[i],
                          isSelected: !_isSubRoute && _index == i,
                          onTap: () =>
                              context.go(MainShell.destinations[i].path),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom Bottom Navigation item where the green hue rounded rectangle
/// (`AppTheme.forestSoft`) encompasses BOTH the icon and the label (Point 4).
class _BottomNavPillItem extends StatelessWidget {
  const _BottomNavPillItem({
    required this.entry,
    required this.isSelected,
    required this.onTap,
  });

  final ({String path, String label, IconData icon, IconData activeIcon}) entry;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.forestSoft : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isSelected
                  ? AppTheme.secondary.withValues(alpha: 0.25)
                  : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? entry.activeIcon : entry.icon,
                size: 22,
                color: isSelected ? AppTheme.secondary : AppTheme.muted,
              ),
              const SizedBox(height: 3),
              Text(
                entry.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                  color: isSelected ? AppTheme.secondary : AppTheme.muted,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
