import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/cozy_palette.dart';
import '../theme/palettes/light_palette.dart';
import '../theme/palettes/dark_palette.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode_enum';

  // Default to System
  ThemeMode _themeMode = ThemeMode.system;

  ThemeMode get themeMode => _themeMode;

  // Helper to know if currently dark (for manual checks if needed)
  // Note: This only works if we have context or platform dispatcher,
  // but for simple logic we might rely on themeMode checking.
  bool get isDark => _themeMode == ThemeMode.dark;
  // OR: We can check platform brightness if needed, but usually UI uses Theme.of(context).brightness

  // Deprecated: palette getter relying on internal state is tricky with system mode
  // unless we listen to platform brightness changes.
  // Better to let main.dart handle palette selection via ThemeMode.
  CozyPalette get palette {
    if (_themeMode == ThemeMode.light) return LightPalette();
    if (_themeMode == ThemeMode.dark) return DarkPalette();
    // Fallback for system checks (might be inaccurate without context)
    // verify manually or return light
    return LightPalette();
  }

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeIndex = prefs.getInt(_themeKey);
    if (modeIndex != null &&
        modeIndex >= 0 &&
        modeIndex < ThemeMode.values.length) {
      _themeMode = ThemeMode.values[modeIndex];
    } else {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
  }

  // Cycle: System -> Light -> Dark -> System
  Future<void> cycleTheme() async {
    final nextIndex = (_themeMode.index + 1) % ThemeMode.values.length;
    await setThemeMode(ThemeMode.values[nextIndex]);
  }
}
