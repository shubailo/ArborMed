import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:arbor_med/theme/palettes/light_palette.dart';
import 'package:arbor_med/theme/palettes/dark_palette.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeService', () {
    late ThemeService service;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('initial state is light', () {
      service = ThemeService();
      expect(service.themeMode, ThemeMode.light);
      expect(service.isDark, isFalse);
      expect(service.palette, isA<LightPalette>());
    });

    test('loads saved light theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode_enum': ThemeMode.light.index,
      });

      service = ThemeService();
      // Wait for _loadTheme to complete
      await Future.delayed(Duration.zero);

      expect(service.themeMode, ThemeMode.light);
      expect(service.isDark, isFalse);
    });

    test('loads saved dark theme from SharedPreferences', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode_enum': ThemeMode.dark.index,
      });

      service = ThemeService();
      // Wait for _loadTheme to complete
      await Future.delayed(Duration.zero);

      expect(service.themeMode, ThemeMode.dark);
      expect(service.isDark, isTrue);
      expect(service.palette, isA<DarkPalette>());
    });

    test('falls back to light when system theme is saved', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode_enum': ThemeMode.system.index,
      });

      service = ThemeService();
      await Future.delayed(Duration.zero);

      expect(service.themeMode, ThemeMode.light);
    });

    test('falls back to light when invalid theme index is saved', () async {
      SharedPreferences.setMockInitialValues({
        'theme_mode_enum': 999, // Invalid index
      });

      service = ThemeService();
      await Future.delayed(Duration.zero);

      expect(service.themeMode, ThemeMode.light);
    });

    test('setThemeMode updates state, notifies listeners, and saves to SharedPreferences', () async {
      service = ThemeService();
      await Future.delayed(Duration.zero);

      bool notified = false;
      service.addListener(() {
        notified = true;
      });

      await service.setThemeMode(ThemeMode.dark);

      expect(service.themeMode, ThemeMode.dark);
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme_mode_enum'), ThemeMode.dark.index);
    });

    test('cycleTheme toggles between light and dark', () async {
      service = ThemeService();
      await Future.delayed(Duration.zero);

      expect(service.themeMode, ThemeMode.light);

      await service.cycleTheme();
      expect(service.themeMode, ThemeMode.dark);

      await service.cycleTheme();
      expect(service.themeMode, ThemeMode.light);
    });
  });
}
