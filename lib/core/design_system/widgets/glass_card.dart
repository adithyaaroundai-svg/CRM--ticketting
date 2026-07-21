import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

/// A card that shows a glassmorphism effect when the blue gradient theme
/// is active, and behaves as a normal surface card otherwise.
class GlassCard extends ConsumerWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final BorderRadius? borderRadius;
  final double blurSigma;
  final Color? forcedColor;

  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.borderRadius,
    this.blurSigma = 16,
    this.forcedColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    final isGlass = theme == AppThemeType.blueGradient;
    final cs = Theme.of(context).colorScheme;
    final br = borderRadius ?? BorderRadius.circular(12);

    if (!isGlass) {
      // Normal surface card
      return Container(
        padding: padding,
        decoration: BoxDecoration(
          color: forcedColor ?? cs.surface,
          borderRadius: br,
          border: Border.all(color: cs.outlineVariant),
        ),
        child: child,
      );
    }

    // Glassmorphism card for blue gradient theme
    return ClipRRect(
      borderRadius: br,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.08),
            borderRadius: br,
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.18),
              width: 1,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.12),
                Colors.white.withValues(alpha: 0.04),
              ],
            ),
          ),
          child: child,
        ),
      ),
    );
  }
}

/// Provides glass-aware colors based on current theme.
/// Use via: `GlassColors.of(context, ref)`
class GlassColors {
  final bool isGlass;
  final ColorScheme cs;

  const GlassColors._(this.isGlass, this.cs);

  factory GlassColors.of(BuildContext context, WidgetRef ref) {
    final theme = ref.watch(themeProvider);
    return GlassColors._(
      theme == AppThemeType.blueGradient,
      Theme.of(context).colorScheme,
    );
  }

  Color get surface =>
      isGlass ? Colors.white.withValues(alpha: 0.06) : cs.surface;

  Color get surfaceHeader =>
      isGlass ? Colors.white.withValues(alpha: 0.10) : cs.surfaceContainerHighest;

  Color get onSurface => isGlass ? Colors.white : cs.onSurface;

  Color get onSurfaceMuted =>
      isGlass ? Colors.white.withValues(alpha: 0.6) : cs.onSurface.withValues(alpha: 0.6);

  Color get onSurfaceFaint =>
      isGlass ? Colors.white.withValues(alpha: 0.35) : cs.onSurface.withValues(alpha: 0.4);

  Color get border =>
      isGlass ? Colors.white.withValues(alpha: 0.15) : cs.outlineVariant;

  Color get primary => cs.primary;
}
