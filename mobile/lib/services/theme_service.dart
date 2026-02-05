import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../theme/cozy_palette.dart';
import '../theme/palettes/light_palette.dart';
import '../theme/palettes/dark_palette.dart';

class ThemeService extends ChangeNotifier {
  static const String _themeKey = 'theme_mode';
  
  CozyPalette _palette = LightPalette();
  bool _isDark = false;

  CozyPalette get palette => _palette;
  bool get isDark => _isDark;

  ThemeService() {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    _isDark = prefs.getBool(_themeKey) ?? false;
    _updatePalette();
    notifyListeners();
  }

  Future<void> toggleTheme() async {
    _isDark = !_isDark;
    _updatePalette();
    notifyListeners();
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_themeKey, _isDark);
  }

  void _updatePalette() {
    _palette = _isDark ? DarkPalette() : LightPalette();
  }
}
