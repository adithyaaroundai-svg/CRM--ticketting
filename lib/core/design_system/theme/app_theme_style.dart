import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ---------------------------------------------
// 1.  Enum
// ---------------------------------------------

enum AppThemeStyle {
  light,
  dark,
  purpleDark;

  String get key {
    switch (this) {
      case AppThemeStyle.light:      return 'light';
      case AppThemeStyle.dark:       return 'dark';
      case AppThemeStyle.purpleDark: return 'purple_dark';
    }
  }

  static AppThemeStyle fromKey(String key) {
    switch (key) {
      case 'dark':        return AppThemeStyle.dark;
      case 'purple_dark': return AppThemeStyle.purpleDark;
      default:            return AppThemeStyle.light;
    }
  }

  /// The Flutter ThemeMode that should be sent to MaterialApp.
  ThemeMode get themeMode {
    switch (this) {
      case AppThemeStyle.light:      return ThemeMode.light;
      case AppThemeStyle.dark:       return ThemeMode.dark;
      case AppThemeStyle.purpleDark: return ThemeMode.dark;
    }
  }

  bool get isDark => this != AppThemeStyle.light;
  bool get isPurpleDark => this == AppThemeStyle.purpleDark;
}

// ---------------------------------------------
// 2.  Riverpod Notifier
// ---------------------------------------------

class AppThemeStyleNotifier extends Notifier<AppThemeStyle> {
  static const _key = 'app_theme_style';

  @override
  AppThemeStyle build() {
    _load();
    return AppThemeStyle.light;
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      state = AppThemeStyle.fromKey(saved);
    }
  }

  Future<void> setStyle(AppThemeStyle style) async {
    state = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, style.key);
  }

  /// Cycles light -> dark -> purpleDark -> light
  Future<void> cycleTheme() async {
    switch (state) {
      case AppThemeStyle.light:
        await setStyle(AppThemeStyle.dark);
        break;
      case AppThemeStyle.dark:
        await setStyle(AppThemeStyle.purpleDark);
        break;
      case AppThemeStyle.purpleDark:
        await setStyle(AppThemeStyle.light);
        break;
    }
  }
}

final appThemeStyleProvider =
    NotifierProvider<AppThemeStyleNotifier, AppThemeStyle>(
  AppThemeStyleNotifier.new,
);

// ---------------------------------------------
// 3.  InheritedWidget
// ---------------------------------------------

class AppThemeStyleScope extends InheritedWidget {
  final AppThemeStyle style;

  const AppThemeStyleScope({
    super.key,
    required this.style,
    required super.child,
  });

  static AppThemeStyle of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<AppThemeStyleScope>();
    return scope?.style ?? AppThemeStyle.light;
  }

  @override
  bool updateShouldNotify(AppThemeStyleScope oldWidget) =>
      style != oldWidget.style;
}

// ---------------------------------------------
// 4.  BuildContext extensions
// ---------------------------------------------

extension AppThemeStyleExtension on BuildContext {
  AppThemeStyle get themeStyle => AppThemeStyleScope.of(this);
  bool get isPurpleDark => themeStyle == AppThemeStyle.purpleDark;
  bool get isAnyDark => themeStyle.isDark;
}
