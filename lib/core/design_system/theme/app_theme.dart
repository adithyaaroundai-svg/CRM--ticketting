import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  // Enterprise shadow presets
  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 8,
      offset: const Offset(0, 2),
    ),
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static List<BoxShadow> get elevatedShadow => [
    BoxShadow(
      color: AppColors.shadowMedium,
      blurRadius: 16,
      offset: const Offset(0, 4),
    ),
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 6,
      offset: const Offset(0, 2),
    ),
  ];

  static List<BoxShadow> get subtleShadow => [
    BoxShadow(
      color: AppColors.shadowLight,
      blurRadius: 4,
      offset: const Offset(0, 1),
    ),
  ];

  static ThemeData get lightTheme {
    return FlexThemeData.light(
      colors: const FlexSchemeColor(
        primary: AppColors.primary,
        primaryContainer: AppColors.primarySurface,
        secondary: AppColors.slate700,
        secondaryContainer: AppColors.slate100,
        tertiary: AppColors.accent,
        tertiaryContainer: AppColors.accentSurface,
        appBarColor: Colors.white,
        error: AppColors.error,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 4,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 6,
        blendOnColors: false,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        // Enterprise Card Style - refined corners
        cardElevation: 0,
        cardRadius: 12,
        defaultRadius: 10,
        inputDecoratorRadius: 10,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorBorderWidth: 1.5,
        inputDecoratorFocusedBorderWidth: 2,
        // Button styling
        elevatedButtonRadius: 10,
        outlinedButtonRadius: 10,
        textButtonRadius: 8,
        filledButtonRadius: 10,
        // Dialog styling
        dialogRadius: 16,
        dialogElevation: 8,
        // Bottom sheet
        bottomSheetRadius: 20,
        // Chip styling
        chipRadius: 8,
      ),
      visualDensity: VisualDensity.comfortable,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: AppColors.background,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 1,
        surfaceTintColor: Colors.transparent,
        shadowColor: AppColors.shadowLight,
        iconTheme: const IconThemeData(color: AppColors.slate700),
        titleTextStyle: TextStyle(
          color: AppColors.slate900,
          fontSize: 18,
          fontWeight: FontWeight.w600,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
      ),
      dividerTheme: const DividerThemeData(
        color: AppColors.border,
        thickness: 1,
      ),
      cardTheme: CardThemeData(
        color: AppColors.cardBackground,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: AppColors.border, width: 1),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.slate100,
        selectedColor: AppColors.primarySurface,
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        side: const BorderSide(color: AppColors.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.slate900,
        contentTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 14,
          fontFamily: GoogleFonts.inter().fontFamily,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        behavior: SnackBarBehavior.floating,
      ),
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.slate800,
          borderRadius: BorderRadius.circular(8),
        ),
        textStyle: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }

  static ThemeData get darkTheme {
    return FlexThemeData.dark(
      colors: const FlexSchemeColor(
        primary: AppColors.primaryLight,
        primaryContainer: AppColors.slate700,
        secondary: AppColors.slate400,
        secondaryContainer: AppColors.slate600,
        tertiary: AppColors.accentLight,
        tertiaryContainer: AppColors.slate700,
        appBarColor: Colors.transparent,
        error: AppColors.error,
      ),
      surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
      blendLevel: 10,
      subThemesData: const FlexSubThemesData(
        blendOnLevel: 15,
        useM2StyleDividerInM3: true,
        alignedDropdown: true,
        useInputDecoratorThemeInDialogs: true,
        cardElevation: 0,
        cardRadius: 12,
        defaultRadius: 10,
        inputDecoratorRadius: 10,
        inputDecoratorBorderType: FlexInputBorderType.outline,
        inputDecoratorUnfocusedBorderIsColored: false,
        inputDecoratorBorderWidth: 1.5,
        inputDecoratorFocusedBorderWidth: 2,
        elevatedButtonRadius: 10,
        outlinedButtonRadius: 10,
        textButtonRadius: 8,
        filledButtonRadius: 10,
        dialogRadius: 16,
        bottomSheetRadius: 20,
        chipRadius: 8,
      ),
      visualDensity: VisualDensity.comfortable,
      useMaterial3: true,
      swapLegacyOnMaterial3: true,
      fontFamily: GoogleFonts.inter().fontFamily,
    ).copyWith(
      scaffoldBackgroundColor: Colors.transparent,
      cardTheme: CardThemeData(
        color: Colors.white.withValues(alpha: 0.05),
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.1), width: 1),
        ),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.slate900,
        elevation: 8,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }
}


