import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

enum AppCardVariant { elevated, outlined, filled, subtle }

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final BorderSide? border;
  final AppCardVariant variant;
  final bool isHoverable;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.variant = AppCardVariant.elevated,
    this.isHoverable = true,
  });

  const AppCard.outlined({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.isHoverable = true,
  }) : variant = AppCardVariant.outlined;

  const AppCard.filled({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.isHoverable = true,
  }) : variant = AppCardVariant.filled;

  const AppCard.subtle({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.backgroundColor,
    this.border,
    this.isHoverable = false,
  }) : variant = AppCardVariant.subtle;

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? _getBackgroundColor(context);
    final borderSide = border ?? _getBorder(context);
    final shadows = _getShadows();

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: borderSide.color,
          width: borderSide.width,
        ),
        boxShadow: shadows,
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          hoverColor: isHoverable ? (Theme.of(context).brightness == Brightness.dark ? Colors.white.withValues(alpha: 0.05) : AppColors.surfaceHover) : Colors.transparent,
          splashColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.slate200).withValues(alpha: 0.1),
          highlightColor: (Theme.of(context).brightness == Brightness.dark ? Colors.white : AppColors.slate100).withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(20),
            child: child,
          ),
        ),
      ),
    );
  }

  Color _getBackgroundColor(BuildContext context) {
    switch (variant) {
      case AppCardVariant.elevated:
        return context.adaptiveCard;
      case AppCardVariant.outlined:
        return context.adaptiveCard;
      case AppCardVariant.filled:
        return context.adaptiveSlate50;
      case AppCardVariant.subtle:
        return Colors.transparent;
    }
  }

  BorderSide _getBorder(BuildContext context) {
    switch (variant) {
      case AppCardVariant.elevated:
        return BorderSide(color: context.adaptiveSlate200, width: 1);
      case AppCardVariant.outlined:
        return BorderSide(color: context.adaptiveSlate200, width: 1.5);
      case AppCardVariant.filled:
        return BorderSide.none;
      case AppCardVariant.subtle:
        return BorderSide.none;
    }
  }

  List<BoxShadow>? _getShadows() {
    switch (variant) {
      case AppCardVariant.elevated:
        return AppTheme.cardShadow;
      case AppCardVariant.outlined:
        return AppTheme.subtleShadow;
      case AppCardVariant.filled:
        return null;
      case AppCardVariant.subtle:
        return null;
    }
  }
}

/// Enterprise-style stat card for KPIs and metrics
class EnterpriseStatCard extends StatelessWidget {
  final String title;
  final String value;
  final String? subtitle;
  final IconData? icon;
  final Color? accentColor;
  final VoidCallback? onTap;
  final Widget? trailing;
  final String? trend;
  final bool trendPositive;

  const EnterpriseStatCard({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.icon,
    this.accentColor,
    this.onTap,
    this.trailing,
    this.trend,
    this.trendPositive = true,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return AppCard(
      onTap: onTap,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 14),
              ],
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.slate500,
                    letterSpacing: 0.2,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.w700,
              color: AppColors.slate900,
              letterSpacing: -1,
              height: 1,
            ),
          ),
          if (subtitle != null || trend != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                if (trend != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: trendPositive
                          ? AppColors.successSurface
                          : AppColors.errorSurface,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          trendPositive ? Icons.trending_up : Icons.trending_down,
                          size: 14,
                          color: trendPositive ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          trend!,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: trendPositive ? AppColors.success : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (subtitle != null) const SizedBox(width: 10),
                ],
                if (subtitle != null)
                  Expanded(
                    child: Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.slate500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
