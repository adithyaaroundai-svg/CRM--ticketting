import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/theme_provider.dart';

enum AppButtonVariant { primary, secondary, ghost, destructive, success }
enum AppButtonSize { small, medium, large }

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? icon;
  final IconData? trailingIcon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
  });

  const AppButton.secondary({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.secondary;

  const AppButton.ghost({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.ghost;

  const AppButton.destructive({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.destructive;

  const AppButton.success({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.trailingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.size = AppButtonSize.medium,
  }) : variant = AppButtonVariant.success;

  EdgeInsets get _padding {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 14, vertical: 10);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 20, vertical: 14);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 28, vertical: 18);
    }
  }

  double get _fontSize {
    switch (size) {
      case AppButtonSize.small:
        return 13;
      case AppButtonSize.medium:
        return 14;
      case AppButtonSize.large:
        return 16;
    }
  }

  double get _iconSize {
    switch (size) {
      case AppButtonSize.small:
        return 16;
      case AppButtonSize.medium:
        return 18;
      case AppButtonSize.large:
        return 20;
    }
  }

  @override
  Widget build(BuildContext context) {
    final widget = isLoading
        ? SizedBox(
            height: _iconSize,
            width: _iconSize,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: variant == AppButtonVariant.primary ||
                      variant == AppButtonVariant.destructive ||
                      variant == AppButtonVariant.success
                  ? Colors.white
                  : AppColors.primary,
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: _iconSize),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: _fontSize,
                  letterSpacing: -0.2,
                ),
              ),
              if (trailingIcon != null) ...[
                const SizedBox(width: 8),
                Icon(trailingIcon, size: _iconSize),
              ],
            ],
          );

    final style = _getButtonStyle(context);

    Widget button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: style,
      child: widget,
    );

    if (variant == AppButtonVariant.primary) {
      final radius = BorderRadius.circular(10);
      button = Container(
        decoration: BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: radius,
          boxShadow: onPressed != null ? [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ] : null,
        ),
        child: ClipRRect(
          borderRadius: radius,
          child: button,
        ),
      );
    }

    return isFullWidth
        ? SizedBox(width: double.infinity, child: button)
        : button;
  }

  ButtonStyle _getButtonStyle(BuildContext context) {
    final borderRadius = BorderRadius.circular(10);
    
    switch (variant) {
      case AppButtonVariant.primary:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
          padding: _padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
      case AppButtonVariant.secondary:
        return ElevatedButton.styleFrom(
          backgroundColor: context.isDarkMode ? context.adaptiveSlate100 : Colors.white,
          foregroundColor: context.adaptiveSlate800,
          elevation: 0,
          padding: _padding,
          side: BorderSide(color: context.adaptiveBorder, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(context.adaptiveSlate200),
        );
      case AppButtonVariant.ghost:
        return ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: context.adaptiveSlate700,
          elevation: 0,
          padding: _padding,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        ).copyWith(
          overlayColor: WidgetStateProperty.all(context.adaptiveSlate200),
        );
      case AppButtonVariant.destructive:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.error,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: _padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
      case AppButtonVariant.success:
        return ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: _padding,
          shape: RoundedRectangleBorder(borderRadius: borderRadius),
        );
    }
  }
}
