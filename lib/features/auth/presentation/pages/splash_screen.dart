import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:dio/dio.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/network/dio_client.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/warm_widgets.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../widgets/brand_header.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  String? _userName;
  String? _userAvatar;
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

    _scaleAnimation = Tween<double>(begin: 0.88, end: 1.0).animate(
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
    var name = await storage.readUserName();
    final avatar = await storage.readUserAvatar();
    final seenOnboarding = await storage.hasSeenOnboarding();

    var isAuthenticated = token != null && token.isNotEmpty;

    // A stored token is not a session: validate it before opening the app.
    if (isAuthenticated && getIt.isRegistered<DioClient>()) {
      try {
        final res = await getIt<DioClient>().dio.get<Map<String, dynamic>>(
          '/v1/auth/me',
        );
        final data = (res.data?['data'] ?? res.data) as Map<String, dynamic>?;
        if (data != null && data['name'] is String) {
          name = data['name'] as String;
          await storage.saveUserName(name);
        }
      } on DioException catch (error) {
        if (error.response?.statusCode == 401 ||
            error.response?.statusCode == 403) {
          await storage.deleteToken();
          isAuthenticated = false;
          name = null;
        }
      } catch (_) {
        // Network failure: keep the session and let the screens retry.
      }
    }

    if (mounted) {
      setState(() {
        _isLoggedIn = isAuthenticated;
        _userName = name;
        _userAvatar = avatar;
      });
      if (isAuthenticated) {
        context.read<AuthBloc>().add(const SessionLoaded());
      }
    }

    session.isAuthenticated.value = isAuthenticated;
    session.hasSeenOnboarding.value = seenOnboarding;

    // Give user time to see the branded splash logo and "Logging in as {User Name}..."
    await Future<void>.delayed(const Duration(milliseconds: 1600));

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
    final resolvedName = (_userName != null && _userName!.trim().isNotEmpty)
        ? _userName!.trim()
        : 'Household member';

    return Scaffold(
      backgroundColor: AppTheme.canvas,
      body: SafeArea(
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Spacer(),
                    const FairShareEmblem(size: 108),
                    const SizedBox(height: 24),
                    const Text(
                      'FairShare',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                        color: AppTheme.ink,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Household Coordination & Living',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.muted,
                      ),
                    ),
                    const Spacer(),
                    // Loading Indicator & "Logging in as {User Name}" Card (Point 1)
                    WarmCard(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 16,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_isLoggedIn) ...[
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                UserProfileAvatar(
                                  name: resolvedName,
                                  avatarKeyOrUrl: _userAvatar,
                                  radius: 18,
                                ),
                                const SizedBox(width: 12),
                                Flexible(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Logging in as $resolvedName…',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w800,
                                          color: AppTheme.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 2),
                                      const Text(
                                        'Syncing household workspace & quotas',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: AppTheme.muted,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                          ] else ...[
                            const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.4,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      AppTheme.secondary,
                                    ),
                                  ),
                                ),
                                SizedBox(width: 12),
                                Text(
                                  'Starting FairShare…',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: AppTheme.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],
                          ClipRRect(
                            borderRadius: BorderRadius.circular(999),
                            child: const LinearProgressIndicator(
                              minHeight: 5,
                              backgroundColor: AppTheme.forestSoft,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                AppTheme.secondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
