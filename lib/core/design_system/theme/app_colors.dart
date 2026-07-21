import 'package:flutter/material.dart';

class AppColors {
  // Enterprise Neutral Palette - Refined grays with subtle warmth
  static const Color slate50 = Color(0xFFFAFAFB);
  static const Color slate100 = Color(0xFFF4F4F6);
  static const Color slate200 = Color(0xFFE4E4E9);
  static const Color slate300 = Color(0xFFD1D1DB);
  static const Color slate400 = Color(0xFF9CA3AF);
  static const Color slate500 = Color(0xFF6B7280);
  static const Color slate600 = Color(0xFF4B5563);
  static const Color slate700 = Color(0xFF374151);
  static const Color slate800 = Color(0xFF1F2937);
  static const Color slate900 = Color(0xFF111827);
  static const Color slate950 = Color(0xFF030712);

  // Enterprise Primary - Deep Professional Blue
  static const Color primary = Color(0xFF1E40AF); // Deep enterprise blue
  static const Color primaryDark = Color(0xFF1E3A8A); // Darker blue
  static const Color primaryLight = Color(0xFF3B82F6); // Lighter blue
  static const Color primarySurface = Color(0xFFEFF6FF); // Very light blue bg
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF1E3A8A), Color(0xFF1E40AF), Color(0xFF2563EB)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
  
  // Enterprise Accent - Sophisticated teal for highlights
  static const Color accent = Color(0xFF0D9488);
  static const Color accentLight = Color(0xFF14B8A6);
  static const Color accentSurface = Color(0xFFF0FDFA);

  // Semantic Colors - Refined for enterprise
  static const Color success = Color(0xFF059669); // Emerald 600 - deeper
  static const Color successLight = Color(0xFFD1FAE5); // Emerald 100
  static const Color successSurface = Color(0xFFECFDF5); // Emerald 50
  static const Color warning = Color(0xFFD97706); // Amber 600 - deeper
  static const Color warningLight = Color(0xFFFEF3C7); // Amber 100
  static const Color warningSurface = Color(0xFFFFFBEB); // Amber 50
  static const Color error = Color(0xFFDC2626); // Red 600 - deeper
  static const Color errorLight = Color(0xFFFEE2E2); // Red 100
  static const Color errorSurface = Color(0xFFFEF2F2); // Red 50
  static const Color info = Color(0xFF2563EB); // Blue 600 - deeper
  static const Color infoLight = Color(0xFFDBEAFE); // Blue 100
  static const Color infoSurface = Color(0xFFEFF6FF); // Blue 50

  // Status Colors (for tickets, deals, etc.) - Enterprise refined
  static const Color statusNew = Color(0xFF2563EB); // Blue 600
  static const Color statusOpen = Color(0xFF4F46E5); // Indigo 600
  static const Color statusInProgress = Color(0xFFD97706); // Amber 600
  static const Color statusWaiting = Color(0xFF7C3AED); // Violet 600
  static const Color statusResolved = Color(0xFF059669); // Emerald 600
  static const Color statusClosed = Color(0xFF4B5563); // Gray 600

  // Priority Colors
  static const Color priorityCritical = Color(0xFFDC2626); // Red 600
  static const Color priorityHigh = Color(0xFFF59E0B); // Amber 500
  static const Color priorityNormal = Color(0xFF3B82F6); // Blue 500
  static const Color priorityLow = Color(0xFF64748B); // Slate 500

  // Backgrounds - Enterprise surfaces
  static const Color background = Color(0xFFFAFAFB);
  static const Color surface = Colors.white;
  static const Color surfaceAlt = Color(0xFFF9FAFB);
  static const Color surfaceHover = Color(0xFFF3F4F6);
  static const Color surfaceElevated = Colors.white;
  static const Color cardBackground = Colors.white;
  static const Color sidebarBackground = Color(0xFF111827); // Dark sidebar
  static const LinearGradient sidebarGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primaryDark,
      slate900,
    ],
  );

  // Pink Theme Colors (Aubergine inspired)
  static const Color pinkThemeSidebar = Color(0xFF3F0E40); // Deep plum/aubergine for sidebars
  static const Color pinkThemeNav = Color(0xFF350D36); // Slightly darker for top nav
  static const Color pinkThemeMain = Color(0xFF1A1D21); // Dark gray for main chat/screen

  // Text
  static const Color textPrimary = slate900;
  static const Color textSecondary = slate500;
  static const Color textMuted = slate400;
  static const Color textOnPrimary = Colors.white;

  // Borders - Enterprise refined
  static const Color border = Color(0xFFE5E7EB); // Gray 200
  static const Color borderLight = Color(0xFFF3F4F6); // Gray 100
  static const Color borderFocus = primary;
  static const Color borderHover = Color(0xFFD1D5DB); // Gray 300
  static const Color borderSubtle = Color(0xFFE5E7EB);
  
  // Enterprise Shadows (use with BoxShadow)
  static const Color shadowLight = Color(0x0A000000); // 4% black
  static const Color shadowMedium = Color(0x14000000); // 8% black
  static const Color shadowDark = Color(0x1F000000); // 12% black

  // Helper methods for status colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'new':
        return statusNew;
      case 'open':
        return statusOpen;
      case 'in progress':
        return statusInProgress;
      case 'waiting for customer':
        return statusWaiting;
      case 'resolved':
      case 'billraised':
      case 'billprocessed':
        return statusResolved;
      case 'closed':
        return statusClosed;
      default:
        return slate500;
    }
  }

  static Color getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'critical':
        return priorityCritical;
      case 'high':
        return priorityHigh;
      case 'normal':
        return priorityNormal;
      case 'low':
        return priorityLow;
      default:
        return slate400;
    }
  }
}

extension ThemeColorExtension on BuildContext {
  bool get isDarkMode => Theme.of(this).brightness == Brightness.dark;

  Color get adaptiveSlate900 => isDarkMode ? AppColors.slate200 : AppColors.slate900;
  Color get adaptiveSlate800 => isDarkMode ? AppColors.slate300 : AppColors.slate800;
  Color get adaptiveSlate700 => isDarkMode ? AppColors.slate300 : AppColors.slate700;
  Color get adaptiveSlate600 => isDarkMode ? AppColors.slate400 : AppColors.slate600;
  Color get adaptiveSlate500 => isDarkMode ? AppColors.slate400 : AppColors.slate500;
  Color get adaptiveSlate400 => isDarkMode ? AppColors.slate600 : AppColors.slate400;
  Color get adaptiveSlate300 => isDarkMode ? AppColors.slate600 : AppColors.slate300;
  Color get adaptiveSlate200 => isDarkMode ? Colors.white.withValues(alpha: 0.06) : AppColors.slate200;
  Color get adaptiveSlate100 => isDarkMode ? Colors.white.withValues(alpha: 0.04) : AppColors.slate100;
  Color get adaptiveSlate50 => isDarkMode ? Colors.white.withValues(alpha: 0.02) : AppColors.slate50;
  Color get adaptiveCard => isDarkMode ? Colors.white.withValues(alpha: 0.05) : Colors.white;
  Color get adaptiveBackground => isDarkMode ? Colors.transparent : AppColors.background;
  Color get adaptiveBorder => isDarkMode ? Colors.white.withValues(alpha: 0.1) : AppColors.border;
  Color get adaptiveError => isDarkMode ? const Color(0xFFF87171) : AppColors.error;
}
