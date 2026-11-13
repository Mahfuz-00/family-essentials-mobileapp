import 'package:flutter/material.dart';

import 'app_theme.dart';

/// Shared currency symbol & formatting helper matching Web `Frontend/src/lib/money.ts`.
String currencySymbolFor(String currency) {
  switch (currency.toUpperCase()) {
    case 'BDT':
      return '৳';
    case 'USD':
      return '\$';
    case 'EUR':
      return '€';
    case 'GBP':
      return '£';
    case 'INR':
      return '₹';
    case 'CAD':
      return 'C\$';
    case 'AUD':
      return 'A\$';
    default:
      return '$currency ';
  }
}

String formatMoneyMinor(int minor, [String currency = 'USD']) {
  final isNegative = minor < 0;
  final absMinor = minor.abs();
  final whole = absMinor ~/ 100;
  final cents = (absMinor % 100).toString().padLeft(2, '0');
  final wholeStr = whole.toString().replaceAllMapped(
    RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
    (m) => '${m[1]},',
  );
  final symbol = currencySymbolFor(currency);
  return '${isNegative ? "-" : ""}$symbol$wholeStr.$cents';
}

/// Unified Soft UI / Claymorphism Stat Card matching Web `<StatCard>` anatomy:
/// 1. Full-width uppercase title at top (unobstructed by any icon).
/// 2. Middle row: auto-scaling bold value on left + inset soft icon chip on right.
/// 3. Bottom row: compact highlight pill (`subtitle` / `badgeLabel`).
class SoftStatCard extends StatelessWidget {
  const SoftStatCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.tone = WarmTone.neutral,
    this.badgeLabel,
    this.badgeTone,
    this.valueColor,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData? icon;
  final WarmTone tone;
  final String? badgeLabel;
  final WarmTone? badgeTone;
  final Color? valueColor;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = warmToneColors(tone);
    final effectiveValueColor =
        valueColor ??
        (tone == WarmTone.danger
            ? AppTheme.tertiary
            : tone == WarmTone.success || tone == WarmTone.primary
                ? AppTheme.secondary
                : AppTheme.ink);

    return WarmCard(
      onTap: onTap,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Top line: Full-width unobstructed title
          Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
              color: AppTheme.muted,
            ),
          ),
          const SizedBox(height: 8),
          // Middle row: Auto-scaling value on left + inset soft icon chip on right
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.4,
                      color: effectiveValueColor,
                    ),
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 8),
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.7),
                      width: 1,
                    ),
                  ),
                  child: Icon(icon, size: 17, color: colors.foreground),
                ),
              ],
            ],
          ),
          if (badgeLabel != null) ...[
            const SizedBox(height: 8),
            PriorityChip(
              label: badgeLabel!,
              tone: badgeTone ?? tone,
            ),
          ],
        ],
      ),
    );
  }
}

/// 1:1 Shimmer skeleton matching `SoftStatCard` anatomy.
class ShimmerStatCard extends StatefulWidget {
  const ShimmerStatCard({super.key});

  @override
  State<ShimmerStatCard> createState() => _ShimmerStatCardState();
}

class _ShimmerStatCardState extends State<ShimmerStatCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.35 + 0.3 * (0.5 - (_controller.value - 0.5).abs());
        return Container(
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.2)),
            boxShadow: AppTheme.elev1,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 72,
                height: 10,
                decoration: BoxDecoration(
                  color: AppTheme.forestSoft.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(5),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 68,
                    height: 22,
                    decoration: BoxDecoration(
                      color: AppTheme.sageSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppTheme.forestSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(11),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: 60,
                height: 16,
                decoration: BoxDecoration(
                  color: AppTheme.forestSoft.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Shimmer loading placeholder for WarmCards
class ShimmerWarmCard extends StatefulWidget {
  const ShimmerWarmCard({super.key, this.height = 110});

  final double height;

  @override
  State<ShimmerWarmCard> createState() => _ShimmerWarmCardState();
}

class _ShimmerWarmCardState extends State<ShimmerWarmCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final alpha = 0.35 + 0.3 * (0.5 - (_controller.value - 0.5).abs());
        return Container(
          height: widget.height,
          decoration: BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            border: Border.all(color: AppTheme.outline.withValues(alpha: 0.15)),
            boxShadow: AppTheme.elev1,
          ),
          padding: const EdgeInsets.all(AppTheme.space4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 140,
                    height: 14,
                    decoration: BoxDecoration(
                      color: AppTheme.forestSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  Container(
                    width: 50,
                    height: 18,
                    decoration: BoxDecoration(
                      color: AppTheme.sageSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ],
              ),
              Container(
                width: 220,
                height: 12,
                decoration: BoxDecoration(
                  color: AppTheme.canvas.withValues(alpha: alpha * 1.5),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 80,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.forestSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 60,
                    height: 12,
                    decoration: BoxDecoration(
                      color: AppTheme.sageSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
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
