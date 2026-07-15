import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TableFontSizeNotifier extends Notifier<double> {
  static const _key = 'table_font_size_scale';

  @override
  double build() {
    _loadFontSize();
    return 1.0;
  }

  Future<void> _loadFontSize() async {
    final prefs = await SharedPreferences.getInstance();
    final scale = prefs.getDouble(_key) ?? 1.0;
    state = scale;
  }

  Future<void> setScale(double scale) async {
    state = scale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, scale);
  }
}

final tableFontSizeProvider = NotifierProvider<TableFontSizeNotifier, double>(TableFontSizeNotifier.new);
