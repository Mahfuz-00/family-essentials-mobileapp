import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../theme/app_theme.dart';
import '../../features/auth/presentation/bloc/auth_bloc.dart';
import '../../features/auth/presentation/bloc/auth_event.dart';

/// Persistent bottom navigation, as specified by the mobile designs:
/// Today · Shopping · Places · Settings.
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
          label: 'Shopping',
          icon: Icons.shopping_basket_outlined,
          activeIcon: Icons.shopping_basket,
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
  @override
  void initState() {
    super.initState();
    // Every tab needs the household identity, so load it once here.
    context.read<AuthBloc>().add(const SessionLoaded());
  }

  /// Pantry is a sub-screen of the shopping tab, so it keeps Shopping lit.
  static const _tabAliases = <String, int>{'/pantry': 1};

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.child,
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (index) =>
            context.go(MainShell.destinations[index].path),
        backgroundColor: AppTheme.surface,
        indicatorColor: AppTheme.forestSoft,
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
    );
  }
}
