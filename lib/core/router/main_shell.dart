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
    return Scaffold(
      key: _scaffoldKey,
      drawer: HouseholdAppDrawer(currentLocation: widget.location),
      appBar: AppBar(
        leading: _isSubRoute
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                tooltip: 'Back',
                onPressed: () => context.pop(),
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
          if (widget.location.startsWith('/budget') || widget.location.startsWith('/ledger'))
            IconButton(
              tooltip: 'Household Finances (Net Worth, Goals, Loans, Taxes)',
              icon: const Icon(Icons.analytics_outlined, color: AppTheme.secondary),
              onPressed: () {
                // Navigate to or open finances modal sheet
                context.push('/budget?open=finances');
              },
            ),
          IconButton(
            tooltip: 'AI Family Dispatcher & Chat',
            icon: const Icon(Icons.auto_awesome, color: AppTheme.secondary),
            onPressed: () => context.push('/chat'),
          ),
          IconButton(
            tooltip: 'Receipt Scanner (OCR)',
            icon: const Icon(Icons.document_scanner_outlined),
            onPressed: () => context.push('/receipt/scan'),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: widget.child,
      bottomNavigationBar: NavigationBarTheme(
        data: NavigationBarThemeData(
          indicatorColor: AppTheme.forestSoft,
          iconTheme: WidgetStateProperty.resolveWith<IconThemeData?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: AppTheme.secondary);
            }
            return const IconThemeData(color: AppTheme.muted);
          }),
          labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.secondary,
              );
            }
            return const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: AppTheme.muted,
            );
          }),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (index) =>
              context.go(MainShell.destinations[index].path),
          backgroundColor: AppTheme.surface,
          height: 68,
          destinations: [
            for (final entry in MainShell.destinations)
              NavigationDestination(
                icon: Icon(entry.icon, color: AppTheme.muted),
                selectedIcon: Icon(entry.activeIcon, color: AppTheme.secondary),
                label: entry.label,
              ),
          ],
        ),
      ),
    );
  }
}
