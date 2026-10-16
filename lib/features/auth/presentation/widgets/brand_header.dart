import 'package:flutter/material.dart';

import '../../../../core/theme/app_theme.dart';

class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          height: 48,
          width: 48,
          decoration: BoxDecoration(
            color: AppTheme.forestSoft,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.center,
          child: const Text(
            'FE',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: AppTheme.secondary,
            ),
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Family Essentials',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.ink,
          ),
        ),
      ],
    );
  }
}
