import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  static const String _localeKey = 'app_locale';

  Locale get locale => _locale;

  /// Initialize and load saved locale preference
  Future<void> loadSavedLocale() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedLocale = prefs.getString(_localeKey);

      if (savedLocale != null) {
        _locale = Locale(savedLocale);
        ApiService().setLanguage(_locale.languageCode);
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error loading saved locale: $e');
    }
  }

  /// Set new locale and persist to storage
  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;

    _locale = locale;
    ApiService().setLanguage(_locale.languageCode);
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localeKey, locale.languageCode);
    } catch (e) {
      debugPrint('Error saving locale: $e');
    }
  }

  /// Toggle between English and Hungarian
  Future<void> toggleLanguage() async {
    final newLocale =
        _locale.languageCode == 'en' ? const Locale('hu') : const Locale('en');
    await setLocale(newLocale);
  }

  /// Get display name for current locale
  String get currentLanguageName {
    switch (_locale.languageCode) {
      case 'hu':
        return 'Magyar';
      case 'en':
      default:
        return 'English';
    }
  }
}
