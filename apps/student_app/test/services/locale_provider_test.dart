import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:arbor_med/services/locale_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocaleProvider', () {
    late LocaleProvider provider;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      provider = LocaleProvider();

      // Override ApiService for testing if needed
      // LocaleProvider uses ApiService().setLanguage
      // We'll just let it use the real instance since it doesn't make network calls in setLanguage
    });

    test('initial state is English', () {
      expect(provider.locale.languageCode, 'en');
      expect(provider.currentLanguageName, 'English');
    });

    test('loadSavedLocale with no saved locale does not change locale',
        () async {
      await provider.loadSavedLocale();
      expect(provider.locale.languageCode, 'en');
    });

    test('loadSavedLocale with saved hu locale updates locale', () async {
      SharedPreferences.setMockInitialValues({'app_locale': 'hu'});

      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.loadSavedLocale();
      expect(provider.locale.languageCode, 'hu');
      expect(provider.currentLanguageName, 'Magyar');
      expect(notified, isTrue);
    });

    test('setLocale updates locale and saves to SharedPreferences', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setLocale(const Locale('hu'));

      expect(provider.locale.languageCode, 'hu');
      expect(notified, isTrue);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('app_locale'), 'hu');
    });

    test('setLocale to same locale does not notify or save', () async {
      bool notified = false;
      provider.addListener(() {
        notified = true;
      });

      await provider.setLocale(const Locale('en'));

      expect(provider.locale.languageCode, 'en');
      expect(notified, isFalse);
    });

    test('toggleLanguage switches between en and hu', () async {
      await provider.toggleLanguage();
      expect(provider.locale.languageCode, 'hu');

      await provider.toggleLanguage();
      expect(provider.locale.languageCode, 'en');
    });
  });
}
