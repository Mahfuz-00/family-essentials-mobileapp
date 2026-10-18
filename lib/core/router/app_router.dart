import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/verify_phone_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/pantry/presentation/pages/pantry_page.dart';
import '../../features/places/presentation/pages/places_page.dart';
import '../../features/requests/presentation/pages/quick_add_page.dart';
import '../../features/requests/presentation/pages/request_detail_page.dart';
import '../../features/requests/presentation/pages/shopping_page.dart';
import '../../features/requests/presentation/pages/today_page.dart';
import '../session/auth_session.dart';
import 'main_shell.dart';

class AppRouter {
  AppRouter(AuthSession session)
    : router = GoRouter(
        initialLocation: '/today',
        refreshListenable: session.isAuthenticated,
        redirect: (context, state) {
          final loggedIn = session.isAuthenticated.value;
          final isAuthRoute =
              state.matchedLocation == '/login' ||
              state.matchedLocation == '/register';

          if (!loggedIn && !isAuthRoute) {
            return '/login';
          }

          if (loggedIn && isAuthRoute) {
            return '/today';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/login',
            builder: (context, state) => const LoginPage(),
          ),
          GoRoute(
            path: '/register',
            builder: (context, state) => const RegisterPage(),
          ),
          GoRoute(
            path: '/verify-phone',
            builder: (context, state) => const VerifyPhonePage(),
          ),

          // Superseded by /today; kept so older links keep working.
          GoRoute(path: '/home', redirect: (context, state) => '/today'),

          // Full-screen flows: these sit outside the tab shell.
          // Declared before the :id route so "new" is not treated as an id.
          GoRoute(
            path: '/requests/new',
            builder: (context, state) => const QuickAddPage(),
          ),
          GoRoute(
            path: '/requests/:id',
            builder: (context, state) =>
                RequestDetailPage(id: int.parse(state.pathParameters['id']!)),
          ),

          // Feedback is a full-screen flow, reached from Settings.
          GoRoute(
            path: '/feedback',
            builder: (context, state) => const FeedbackPage(),
          ),

          // Tab shell: Today · Shopping · Places · Settings.
          // Pantry is a sub-screen of the shopping tab.
          ShellRoute(
            builder: (context, state, child) =>
                MainShell(location: state.matchedLocation, child: child),
            routes: [
              GoRoute(
                path: '/today',
                builder: (context, state) => TodayPage(
                  focusedPlaceId: int.tryParse(
                    state.uri.queryParameters['place_id'] ?? '',
                  ),
                ),
              ),
              GoRoute(
                path: '/shopping',
                builder: (context, state) => const ShoppingPage(),
              ),
              GoRoute(
                path: '/pantry',
                builder: (context, state) => const PantryPage(),
              ),
              GoRoute(
                path: '/places',
                builder: (context, state) => const PlacesPage(),
              ),
              GoRoute(
                path: '/settings',
                builder: (context, state) => const SettingsPage(),
              ),
            ],
          ),
        ],
      );

  final GoRouter router;
}
