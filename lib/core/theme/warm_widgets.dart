import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared Warm Sage widgets for the mobile app.
///
/// These are the mobile equivalents of the React kit in
/// `frontend/src/components/ui/`, so both surfaces render the same vocabulary.

/// Resting surface: white on the warm cream canvas with a Level-1 shadow.
class WarmCard extends StatelessWidget {
  const WarmCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(AppTheme.space4),
    this.onTap,
    this.highlighted = false,
    this.borderColor,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool highlighted;
  final Color? borderColor;

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(AppTheme.radiusLg);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: radius,
        border: Border.all(
          color:
              borderColor ??
              (highlighted ? AppTheme.secondary : const Color(0x0D2B2D42)),
          width: highlighted ? 2 : 1,
        ),
        boxShadow: AppTheme.elev1,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: radius,
        child: InkWell(
          onTap: onTap,
          borderRadius: radius,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Priority / status pill, 6px vertical padding with a leading dot.
class PriorityChip extends StatelessWidget {
  const PriorityChip({
    super.key,
    required this.label,
    this.tone = WarmTone.neutral,
    this.dot = false,
  });

  final String label;
  final WarmTone tone;
  final bool dot;

  @override
  Widget build(BuildContext context) {
    final colors = warmToneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dot) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.02 * 11,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

enum WarmTone { neutral, primary, success, warning, danger, info }

({Color background, Color foreground}) warmToneColors(WarmTone tone) {
  switch (tone) {
    case WarmTone.primary:
    case WarmTone.success:
      return (background: AppTheme.forestSoft, foreground: AppTheme.secondary);
    case WarmTone.warning:
      return (background: AppTheme.sageSoft, foreground: AppTheme.primary);
    case WarmTone.danger:
      return (background: AppTheme.coralSoft, foreground: AppTheme.tertiary);
    case WarmTone.info:
      return (
        background: AppTheme.surfaceContainer,
        foreground: AppTheme.primary,
      );
    case WarmTone.neutral:
      return (
        background: AppTheme.surfaceContainerLow,
        foreground: AppTheme.onSurfaceVariant,
      );
  }
}

/// Metric pill used in the summary strip.
class StatPill extends StatelessWidget {
  const StatPill({
    super.key,
    required this.value,
    required this.label,
    this.tone = WarmTone.neutral,
    this.icon,
  });

  final int value;
  final String label;
  final WarmTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = warmToneColors(tone);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null)
            Icon(icon, size: 15, color: colors.foreground)
          else
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: colors.foreground,
                shape: BoxShape.circle,
              ),
            ),
          const SizedBox(width: 8),
          Text(
            '$value',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.foreground,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.foreground,
            ),
          ),
        ],
      ),
    );
  }
}

/// Section heading with a count.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    required this.count,
    this.dotColor,
  });

  final String title;
  final int count;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        if (dotColor != null) ...[
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.ink,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          ),
          child: Text(
            '$count',
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppTheme.muted,
            ),
          ),
        ),
      ],
    );
  }
}

/// Warm empty state: what belongs here, why it matters, what fills it.
class WarmEmptyState extends StatelessWidget {
  const WarmEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.icon = Icons.home_outlined,
    this.action,
  });

  final String title;
  final String description;
  final IconData icon;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppTheme.space5),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLg),
        border: Border.all(color: AppTheme.outline),
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.forestSoft,
              borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            ),
            child: Icon(icon, color: AppTheme.secondary),
          ),
          const SizedBox(height: AppTheme.space3),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.ink,
            ),
          ),
          const SizedBox(height: AppTheme.space2),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: AppTheme.muted,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: AppTheme.space4),
            action!,
          ],
        ],
      ),
    );
  }
}
