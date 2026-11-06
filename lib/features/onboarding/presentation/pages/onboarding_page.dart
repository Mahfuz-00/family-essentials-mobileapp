import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injector.dart';
import '../../../../core/session/auth_session.dart';
import '../../../../core/storage/secure_storage.dart';
import '../../../../core/theme/app_theme.dart';

class OnboardingPage extends StatefulWidget {
  const OnboardingPage({super.key});

  @override
  State<OnboardingPage> createState() => _OnboardingPageState();
}

class _OnboardingPageState extends State<OnboardingPage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const List<_OnboardingSlideData> _slides = [
    _OnboardingSlideData(
      icon: Icons.view_kanban_rounded,
      badge: 'ACCOUNTABILITY',
      title: 'One Task, One Owner',
      subtitle:
          'Eliminate bystander apathy. Every grocery run and household errand has one named owner with clear status, urgency tags, and no dropped balls.',
      accentColor: AppTheme.secondary,
    ),
    _OnboardingSlideData(
      icon: Icons.map_rounded,
      badge: 'OPENSTREETMAP GEOFENCING',
      title: 'Store Arrival Triggers',
      subtitle:
          'Never leave Costco or Trader Joe’s empty-handed again. Your device uses OpenStreetMap coordinates to wake up with your pending store checklist the moment you park.',
      accentColor: AppTheme.primary,
    ),
    _OnboardingSlideData(
      icon: Icons.inventory_2_rounded,
      badge: 'PANTRY CADENCE',
      title: 'Predictable Staples',
      subtitle:
          'Milk, coffee, diapers, and laundry detergent replenish on your family’s real consumption rhythms with safety-stock buffers before you run dry.',
      accentColor: Color(0xFF3B6B55),
    ),
    _OnboardingSlideData(
      icon: Icons.phone_in_talk_rounded,
      badge: 'DIRECT PHONE ESCALATION',
      title: 'Direct Carrier Calling',
      subtitle:
          'Need an urgent pharmacy pickup or real-time brand substitution? Call the errand runner directly through your mobile phone dialer with zero robocalls or middleman fees.',
      accentColor: AppTheme.secondary,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  Future<void> _completeOnboarding() async {
    final storage = getIt<SecureStorage>();
    final session = getIt<AuthSession>();

    await storage.setSeenOnboarding(true);
    session.hasSeenOnboarding.value = true;

    if (!mounted) return;

    if (session.isAuthenticated.value) {
      context.go('/today');
    } else {
      context.go('/login');
    }
  }

  void _nextPage() {
    if (_currentPage < _slides.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _completeOnboarding();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: _completeOnboarding,
            child: const Text(
              'Skip',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: AppTheme.muted,
                fontSize: 15,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: _slides.length,
                onPageChanged: (index) {
                  setState(() => _currentPage = index);
                },
                itemBuilder: (context, index) {
                  final slide = _slides[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 140,
                          height: 140,
                          decoration: BoxDecoration(
                            color: slide.accentColor.withValues(alpha: 0.12),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: slide.accentColor.withValues(alpha: 0.25),
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: slide.accentColor.withValues(alpha: 0.1),
                                blurRadius: 24,
                                spreadRadius: 4,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Icon(
                            slide.icon,
                            size: 68,
                            color: slide.accentColor,
                          ),
                        ),
                        const SizedBox(height: 36),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(100),
                          ),
                          child: Text(
                            slide.badge,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.2,
                              color: AppTheme.secondary,
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          slide.title,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.5,
                            color: AppTheme.ink,
                          ),
                        ),
                        const SizedBox(height: 14),
                        Text(
                          slide.subtitle,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 15,
                            height: 1.5,
                            color: AppTheme.muted,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 12, 28, 28),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_slides.length, (index) {
                      final isActive = _currentPage == index;
                      return AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        height: 7,
                        width: isActive ? 24 : 7,
                        decoration: BoxDecoration(
                          color: isActive
                              ? AppTheme.secondary
                              : AppTheme.muted.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _nextPage,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _currentPage == _slides.length - 1
                                ? 'Get Started'
                                : 'Continue',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(
                            _currentPage == _slides.length - 1
                                ? Icons.check_circle_outline_rounded
                                : Icons.arrow_forward_rounded,
                            size: 18,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingSlideData {
  const _OnboardingSlideData({
    required this.icon,
    required this.badge,
    required this.title,
    required this.subtitle,
    required this.accentColor,
  });

  final IconData icon;
  final String badge;
  final String title;
  final String subtitle;
  final Color accentColor;
}
