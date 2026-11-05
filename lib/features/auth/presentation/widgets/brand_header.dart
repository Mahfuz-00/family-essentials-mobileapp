import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.subtitle});

  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          height: 56,
          width: 56,
          decoration: BoxDecoration(
            color: AppTheme.forestSoft,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            boxShadow: AppTheme.elev1,
            border: Border.all(
              color: AppTheme.secondary.withValues(alpha: 0.15),
              width: 1,
            ),
          ),
          alignment: Alignment.center,
          child: Stack(
            alignment: Alignment.center,
            children: [
              const Icon(
                Icons.cottage_rounded,
                size: 30,
                color: AppTheme.secondary,
              ),
              Positioned(
                top: 8,
                right: 8,
                child: Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppTheme.primary,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppTheme.space3),
        const Text(
          'Family Essentials',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.3,
            color: AppTheme.ink,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle ?? 'Household Logistics',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
            color: AppTheme.muted,
          ),
        ),
      ],
    );
  }
}
