import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeType {
  white,
  blueGradient,
  pink,
}

class ThemeNotifier extends Notifier<AppThemeType> {
  static const _themeKey = 'app_theme_type';
  // Legacy key for migration if needed
  static const _legacyThemeKey = 'theme_mode';

  @override
  AppThemeType build() {
    _loadTheme();
    return AppThemeType.white; // Default until loaded
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check for legacy theme setting first if new setting is not found
    final String? themeTypeString = prefs.getString(_themeKey);
    
    if (themeTypeString != null) {
      state = AppThemeType.values.firstWhere(
        (e) => e.toString() == themeTypeString,
        orElse: () => AppThemeType.white,
      );
    } else {
      // Migrate from old bool if it exists
      final isDark = prefs.getBool(_legacyThemeKey);
      if (isDark != null) {
        state = isDark ? AppThemeType.blueGradient : AppThemeType.white;
        // Save using the new format
        await prefs.setString(_themeKey, state.toString());
      }
    }
  }

  Future<void> setTheme(AppThemeType type) async {
    state = type;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_themeKey, type.toString());
  }
}

final themeProvider = NotifierProvider<ThemeNotifier, AppThemeType>(ThemeNotifier.new);
