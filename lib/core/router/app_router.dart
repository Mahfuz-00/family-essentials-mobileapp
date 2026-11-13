import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/register_page.dart';
import '../../features/auth/presentation/pages/settings_page.dart';
import '../../features/auth/presentation/pages/splash_screen.dart';
import '../../features/auth/presentation/pages/verify_phone_page.dart';
import '../../features/billing/presentation/pages/billing_page.dart';
import '../../features/feedback/presentation/pages/feedback_page.dart';
import '../../features/ledger/presentation/pages/ledger_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/pantry/presentation/pages/pantry_page.dart';
import '../../features/places/presentation/pages/places_page.dart';
import '../../features/recurring/presentation/pages/recurring_page.dart';
import '../../features/household/presentation/pages/household_page.dart';
import '../../features/requests/presentation/pages/ai_chat_page.dart';
import '../../features/voice/presentation/pages/voice_escalations_page.dart';
import '../../features/requests/presentation/pages/quick_add_page.dart';
import '../../features/requests/presentation/pages/receipt_scan_page.dart';
import '../../features/requests/presentation/pages/request_detail_page.dart';
import '../../features/requests/presentation/pages/shopping_page.dart';
import '../../features/requests/presentation/pages/today_page.dart';
import '../session/auth_session.dart';
import 'main_shell.dart';

CustomTransitionPage<void> _buildFadeSlidePage({
  required LocalKey key,
  required Widget child,
}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: const Duration(milliseconds: 260),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      );
      return FadeTransition(
        opacity: curved,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.04, 0),
            end: Offset.zero,
          ).animate(curved),
          child: child,
        ),
      );
    },
  );
}

class AppRouter {
  AppRouter(AuthSession session)
    : router = GoRouter(
        initialLocation: '/splash',
        refreshListenable: Listenable.merge([
          session.isAuthenticated,
          session.hasSeenOnboarding,
        ]),
        redirect: (context, state) {
          final isSplash = state.matchedLocation == '/splash';
          if (isSplash) return null;

          final loggedIn = session.isAuthenticated.value;
          final seenOnboarding = session.hasSeenOnboarding.value;
          final isAuthRoute =
              state.matchedLocation == '/login' ||
              state.matchedLocation == '/register';
          final isVerifyPhone = state.matchedLocation == '/verify-phone';
          final isOnboardingRoute = state.matchedLocation == '/onboarding';

          // First launch: must see the onboarding carousel
          if (!seenOnboarding) {
            return isOnboardingRoute ? null : '/onboarding';
          }

          // If onboarding is already seen, prevent accessing onboarding page
          if (isOnboardingRoute) {
            return loggedIn ? '/today' : '/login';
          }

          // Unauthenticated users must log in
          if (!loggedIn && !isAuthRoute && !isVerifyPhone) {
            return '/login';
          }

          // Authenticated users skipping login/register routes
          if (loggedIn && isAuthRoute) {
            return '/today';
          }

          return null;
        },
        routes: [
          GoRoute(
            path: '/splash',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const SplashScreen(),
            ),
          ),
          GoRoute(
            path: '/onboarding',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const OnboardingPage(),
            ),
          ),
          GoRoute(
            path: '/login',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const LoginPage(),
            ),
          ),
          GoRoute(
            path: '/register',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const RegisterPage(),
            ),
          ),
          GoRoute(
            path: '/verify-phone',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const VerifyPhonePage(),
            ),
          ),

          // Superseded by /today; kept so older links keep working.
          GoRoute(path: '/home', redirect: (context, state) => '/today'),

          // Full-screen flows: these sit outside the tab shell.
          GoRoute(
            path: '/requests/new',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const QuickAddPage(),
            ),
          ),
          GoRoute(
            path: '/requests/:id',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: RequestDetailPage(
                id: int.parse(state.pathParameters['id']!),
              ),
            ),
          ),

          // Voice escalation quota and call history.
          GoRoute(
            path: '/voice-escalations',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const VoiceEscalationsPage(),
            ),
          ),

          // Household administration: members, roles and invitations.
          GoRoute(
            path: '/household',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const HouseholdPage(),
            ),
          ),

          // Feedback is a full-screen flow, reached from Settings.
          GoRoute(
            path: '/feedback',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const FeedbackPage(),
            ),
          ),

          GoRoute(
            path: '/receipt/scan',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const ReceiptScanPage(),
            ),
          ),

          // Household Chat & AI Dispatcher
          GoRoute(
            path: '/chat',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: AiChatPage(
                initialTab: state.uri.queryParameters['tab'] ?? 'ai',
              ),
            ),
          ),

          // Billing & Plan Management
          GoRoute(
            path: '/billing',
            pageBuilder: (context, state) => _buildFadeSlidePage(
              key: state.pageKey,
              child: const BillingPage(),
            ),
          ),

          // Tab shell: Today · Shopping · Places · Settings.
          ShellRoute(
            builder: (context, state, child) =>
                MainShell(location: state.matchedLocation, child: child),
            routes: [
              GoRoute(
                path: '/today',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: TodayPage(
                    focusedPlaceId: int.tryParse(
                      state.uri.queryParameters['place_id'] ?? '',
                    ),
                  ),
                ),
              ),
              GoRoute(
                path: '/shopping',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: const ShoppingPage(),
                ),
              ),
              GoRoute(
                path: '/budget',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: const LedgerPage(),
                ),
              ),
              GoRoute(
                path: '/ledger',
                redirect: (context, state) => '/budget',
              ),
              GoRoute(
                path: '/pantry',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: const PantryPage(),
                ),
              ),
              GoRoute(
                path: '/recurring',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: const RecurringPage(),
                ),
              ),
              GoRoute(
                path: '/places',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: const PlacesPage(),
                ),
              ),
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => _buildFadeSlidePage(
                  key: state.pageKey,
                  child: const SettingsPage(),
                ),
              ),
            ],
          ),
        ],
      );

  final GoRouter router;
}
