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

/// Unified Soft UI / Claymorphism Stat Card matching Web `<StatCard>` anatomy,
/// optimized for mobile widths so values never squish or overflow:
/// 1. Top row: Full-width uppercase title on left + compact soft icon chip on right.
/// 2. Middle row: Full-width auto-scaling (`FittedBox`) bold value.
/// 3. Bottom row: Compact highlight pill (`PriorityChip`) with ellipsis protection.
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: Title + compact soft icon chip
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Text(
                  label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.4,
                    color: AppTheme.muted,
                  ),
                ),
              ),
              if (icon != null) ...[
                const SizedBox(width: 4),
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: colors.background,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 13, color: colors.foreground),
                ),
              ],
            ],
          ),
          const SizedBox(height: 6),
          // Middle row: Full-width auto-scaling value
          SizedBox(
            width: double.infinity,
            height: 26,
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
          if (badgeLabel != null) ...[
            const SizedBox(height: 6),
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
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Container(
                      width: 56,
                      height: 10,
                      decoration: BoxDecoration(
                        color: AppTheme.forestSoft.withValues(alpha: alpha),
                        borderRadius: BorderRadius.circular(5),
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppTheme.forestSoft.withValues(alpha: alpha),
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                width: 68,
                height: 22,
                decoration: BoxDecoration(
                  color: AppTheme.sageSoft.withValues(alpha: alpha),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: 52,
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
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.02 * 11,
                color: colors.foreground,
              ),
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

/// Branded App Logo widget ("Soft Sage Clay" layered emblem) used on Splash,
/// Onboarding, Login, and AppBar headers.
class FairShareLogo extends StatelessWidget {
  const FairShareLogo({super.key, this.size = 96});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF4A7C59),
            Color(0xFF376847),
            Color(0xFF285035),
          ],
        ),
        borderRadius: BorderRadius.circular(size * 0.30),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.65),
          width: 2.5,
        ),
        boxShadow: [
          BoxShadow(
            color: AppTheme.secondary.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.12),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Soft inner glow ring
          Container(
            width: size * 0.76,
            height: size * 0.76,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(size * 0.22),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.22),
                width: 1,
              ),
            ),
          ),
          // Main Cottage / Home Icon
          Icon(
            Icons.cottage_rounded,
            size: size * 0.48,
            color: Colors.white,
          ),
          // Bottom-right Warm Coral family heart badge
          Positioned(
            bottom: size * 0.12,
            right: size * 0.12,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppTheme.accent,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.18),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Icon(
                Icons.favorite_rounded,
                size: size * 0.14,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Portrait avatar presets that render reliably both online and offline using
/// custom layered portrait vector painting (plus network photo URL support).
class PortraitAvatarPreset {
  const PortraitAvatarPreset({
    required this.key,
    required this.label,
    required this.bgStart,
    required this.bgEnd,
    required this.skinColor,
    required this.hairColor,
    required this.shirtColor,
    this.hasBeard = false,
    this.hasGlasses = false,
    this.longHair = false,
  });

  final String key;
  final String label;
  final Color bgStart;
  final Color bgEnd;
  final Color skinColor;
  final Color hairColor;
  final Color shirtColor;
  final bool hasBeard;
  final bool hasGlasses;
  final bool longHair;
}

const List<PortraitAvatarPreset> kPortraitAvatarPresets = [
  PortraitAvatarPreset(
    key: 'portrait_tanvir',
    label: 'Sage Portrait (Admin)',
    bgStart: Color(0xFFD2E8D8),
    bgEnd: Color(0xFF9DD3AA),
    skinColor: Color(0xFFE5B887),
    hairColor: Color(0xFF23272A),
    shirtColor: Color(0xFF376847),
    hasBeard: true,
    hasGlasses: true,
  ),
  PortraitAvatarPreset(
    key: 'portrait_sarah',
    label: 'Warm Clay Portrait',
    bgStart: Color(0xFFFFDBD2),
    bgEnd: Color(0xFFF4A261),
    skinColor: Color(0xFFF1C69E),
    hairColor: Color(0xFF3B2314),
    shirtColor: Color(0xFF97422B),
    longHair: true,
  ),
  PortraitAvatarPreset(
    key: 'portrait_alex',
    label: 'Forest Executive',
    bgStart: Color(0xFFE4EDE7),
    bgEnd: Color(0xFFB7CCBC),
    skinColor: Color(0xFFD6A172),
    hairColor: Color(0xFF1C1E21),
    shirtColor: Color(0xFF2B2D42),
    hasBeard: false,
  ),
  PortraitAvatarPreset(
    key: 'portrait_maya',
    label: 'Golden Meadow',
    bgStart: Color(0xFFFEF6E9),
    bgEnd: Color(0xFFE9C46A),
    skinColor: Color(0xFFF5CBA7),
    hairColor: Color(0xFF5C3317),
    shirtColor: Color(0xFF4A7C59),
    longHair: true,
    hasGlasses: true,
  ),
  PortraitAvatarPreset(
    key: 'portrait_rafi',
    label: 'Terracotta Classic',
    bgStart: Color(0xFFFCECE7),
    bgEnd: Color(0xFFE07A5F),
    skinColor: Color(0xFFC68B59),
    hairColor: Color(0xFF181A1B),
    shirtColor: Color(0xFF1E5031),
    hasBeard: true,
  ),
  PortraitAvatarPreset(
    key: 'portrait_nadia',
    label: 'Lavender Mist',
    bgStart: Color(0xFFEDECFF),
    bgEnd: Color(0xFFC5C6F0),
    skinColor: Color(0xFFECC19C),
    hairColor: Color(0xFF2C1B18),
    shirtColor: Color(0xFF4D6054),
    longHair: true,
  ),
];

/// Renders a rich user profile photo (custom portrait illustration or network photo)
/// that always looks crisp on Settings, Drawer, Splash, and Household Chat.
class UserProfileAvatar extends StatelessWidget {
  const UserProfileAvatar({
    super.key,
    required this.name,
    this.avatarKeyOrUrl,
    this.radius = 30,
    this.showBorder = true,
  });

  final String name;
  final String? avatarKeyOrUrl;
  final double radius;
  final bool showBorder;

  PortraitAvatarPreset _resolvePreset() {
    if (avatarKeyOrUrl != null && avatarKeyOrUrl!.isNotEmpty) {
      for (final p in kPortraitAvatarPresets) {
        if (p.key == avatarKeyOrUrl) return p;
      }
    }
    final lower = name.toLowerCase();
    if (lower.contains('sarah') ||
        lower.contains('maya') ||
        lower.contains('nadia') ||
        lower.contains('amina')) {
      return kPortraitAvatarPresets[1];
    }
    return kPortraitAvatarPresets[0];
  }

  @override
  Widget build(BuildContext context) {
    final size = radius * 2;
    final isHttpUrl =
        avatarKeyOrUrl != null &&
        (avatarKeyOrUrl!.startsWith('http://') ||
            avatarKeyOrUrl!.startsWith('https://'));
    final preset = _resolvePreset();

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [preset.bgStart, preset.bgEnd],
        ),
        border: showBorder
            ? Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.35),
                width: 2.2,
              )
            : null,
        boxShadow: [
          BoxShadow(
            color: AppTheme.ink.withValues(alpha: 0.08),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: isHttpUrl
          ? Image.network(
              avatarKeyOrUrl!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => CustomPaint(
                size: Size(size, size),
                painter: _PortraitAvatarPainter(preset),
              ),
            )
          : CustomPaint(
              size: Size(size, size),
              painter: _PortraitAvatarPainter(preset),
            ),
    );
  }
}

class _PortraitAvatarPainter extends CustomPainter {
  _PortraitAvatarPainter(this.preset);

  final PortraitAvatarPreset preset;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final cx = w / 2;

    // Long hair back layer
    if (preset.longHair) {
      final backHairPaint = Paint()..color = preset.hairColor;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromCenter(
            center: Offset(cx, h * 0.56),
            width: w * 0.54,
            height: h * 0.52,
          ),
          Radius.circular(w * 0.24),
        ),
        backHairPaint,
      );
    }

    // Shoulders / Shirt
    final shirtPaint = Paint()..color = preset.shirtColor;
    final shirtPath = Path()
      ..moveTo(w * 0.12, h)
      ..quadraticBezierTo(cx, h * 0.62, w * 0.88, h)
      ..close();
    canvas.drawPath(shirtPath, shirtPaint);

    // Collar V-neck highlight
    final collarPaint = Paint()..color = Colors.white.withValues(alpha: 0.85);
    final collarPath = Path()
      ..moveTo(cx - w * 0.10, h * 0.72)
      ..lineTo(cx, h * 0.84)
      ..lineTo(cx + w * 0.10, h * 0.72)
      ..close();
    canvas.drawPath(collarPath, collarPaint);

    // Neck
    final skinPaint = Paint()..color = preset.skinColor;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromCenter(
          center: Offset(cx, h * 0.65),
          width: w * 0.18,
          height: h * 0.18,
        ),
        Radius.circular(w * 0.06),
      ),
      skinPaint,
    );

    // Head
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, h * 0.44),
        width: w * 0.42,
        height: h * 0.46,
      ),
      skinPaint,
    );

    // Top Hair
    final hairPaint = Paint()..color = preset.hairColor;
    final hairPath = Path()
      ..addArc(
        Rect.fromCenter(
          center: Offset(cx, h * 0.40),
          width: w * 0.46,
          height: h * 0.44,
        ),
        3.14159,
        3.14159,
      );
    canvas.drawPath(hairPath, hairPaint);

    // Beard (optional)
    if (preset.hasBeard) {
      final beardPaint = Paint()
        ..color = preset.hairColor.withValues(alpha: 0.85);
      final beardPath = Path()
        ..arcTo(
          Rect.fromCenter(
            center: Offset(cx, h * 0.46),
            width: w * 0.41,
            height: h * 0.42,
          ),
          0.15,
          2.84,
          false,
        )
        ..close();
      canvas.drawPath(beardPath, beardPaint);
    }

    // Eyes
    final eyePaint = Paint()..color = const Color(0xFF1F2421);
    canvas.drawCircle(Offset(cx - w * 0.08, h * 0.43), w * 0.025, eyePaint);
    canvas.drawCircle(Offset(cx + w * 0.08, h * 0.43), w * 0.025, eyePaint);

    // Glasses (optional)
    if (preset.hasGlasses) {
      final glassPaint = Paint()
        ..color = const Color(0xFF2B2D42)
        ..style = PaintingStyle.stroke
        ..strokeWidth = w * 0.022;
      canvas.drawCircle(Offset(cx - w * 0.08, h * 0.43), w * 0.055, glassPaint);
      canvas.drawCircle(Offset(cx + w * 0.08, h * 0.43), w * 0.055, glassPaint);
      canvas.drawLine(
        Offset(cx - w * 0.025, h * 0.43),
        Offset(cx + w * 0.025, h * 0.43),
        glassPaint,
      );
    }

    // Warm Smile
    final smilePaint = Paint()
      ..color = preset.hasBeard ? Colors.white : const Color(0xFF8D4A38)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = w * 0.026;
    canvas.drawArc(
      Rect.fromCenter(
        center: Offset(cx, h * 0.50),
        width: w * 0.14,
        height: h * 0.08,
      ),
      0.2,
      2.74,
      false,
      smilePaint,
    );
  }

  @override
  bool shouldRepaint(covariant _PortraitAvatarPainter oldDelegate) =>
      oldDelegate.preset.key != preset.key;
}

