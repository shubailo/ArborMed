import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/cozy_palette.dart';
import '../theme/palettes/light_palette.dart';
import '../theme/palettes/dark_palette.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode_enum';

  ThemeMode _themeMode = ThemeMode.light;
  bool _hasLocalChoice = false;
  bool _disposed = false;
  Future<void> _pendingSave = Future.value();
  ThemeMode get themeMode => _themeMode;
  bool get isDark => _themeMode == ThemeMode.dark;

  CozyPalette get palette {
    if (_themeMode == ThemeMode.dark) return DarkPalette();
    return LightPalette();
  }

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (_disposed || _hasLocalChoice) return;
      if (prefs.getInt(_themeKey) == ThemeMode.dark.index) {
        _themeMode = ThemeMode.dark;
        notifyListeners();
      }
    } catch (_) {
      debugPrint('Could not load the saved theme.');
    }
  }

  Future<void> setThemeMode(ThemeMode mode) {
    if (_disposed) return Future.value();
    _hasLocalChoice = true;
    final selected = mode == ThemeMode.dark ? ThemeMode.dark : ThemeMode.light;
    _themeMode = selected;
    final saved = _pendingSave.then((_) async {
      try {
        final prefs = await SharedPreferences.getInstance();
        if (!await prefs.setInt(_themeKey, selected.index)) {
          debugPrint('Could not save the selected theme.');
        }
      } catch (_) {
        debugPrint('Could not save the selected theme.');
      }
    });
    _pendingSave = saved;
    notifyListeners();
    return saved;
  }

  Future<void> cycleTheme() async {
    final newMode =
        _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    await setThemeMode(newMode);
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
