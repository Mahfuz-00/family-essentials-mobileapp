import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String? _userName;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _scaleAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );

    _animController.forward();
    _checkAuthAndProceed();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthAndProceed() async {
    final storage = getIt<SecureStorage>();
    final session = getIt<AuthSession>();

    final token = await storage.readToken();
    final name = await storage.readUserName();
    final seenOnboarding = await storage.hasSeenOnboarding();

    final isAuthenticated = token != null && token.isNotEmpty;

    if (mounted) {
      setState(() {
        _isLoggedIn = isAuthenticated;
        _userName = name;
      });
    }

    session.isAuthenticated.value = isAuthenticated;
    session.hasSeenOnboarding.value = seenOnboarding;

    // Give user time to see the warm greeting
    await Future.delayed(const Duration(milliseconds: 1400));

    if (!mounted) return;

    if (!seenOnboarding) {
      context.go('/onboarding');
    } else if (!isAuthenticated) {
      context.go('/login');
    } else {
      context.go('/today');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surface,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Branded Logo Container
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(28),
                      border: Border.all(
                        color: AppTheme.secondary.withValues(alpha: 0.25),
                        width: 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.secondary.withValues(alpha: 0.08),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.cottage_rounded,
                      size: 52,
                      color: AppTheme.secondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'FairShare',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: AppTheme.ink,
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Household Coordination & Living',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.muted,
                    ),
                  ),
                  const Spacer(),
                  // Loading Indicator & Greeting (Point 6)
                  SizedBox(
                    height: 90,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(
                          width: 26,
                          height: 26,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            valueColor: AlwaysStoppedAnimation<Color>(AppTheme.secondary),
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          _isLoggedIn && _userName != null && _userName!.isNotEmpty
                              ? 'Logging in as $_userName…'
                              : _isLoggedIn
                              ? 'Logging in to household…'
                              : 'Starting FairShare…',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
