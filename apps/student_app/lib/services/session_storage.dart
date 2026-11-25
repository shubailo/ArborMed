import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SessionStorage {
  static const _storage = FlutterSecureStorage();
  static const _key = 'arbormed_session';
  static const _signedOut = 'arbormed_signed_out';
  static Future<void> _pending = Future.value();

  static Future<T> _run<T>(Future<T> Function() action) {
    final result = _pending.then((_) => action());
    _pending = result.then<void>((_) {}, onError: (Object _) {});
    return result;
  }

  static Future<void> _clearLegacy(SharedPreferences prefs) async {
    for (final key in ['auth_token', 'refresh_token', 'user_data']) {
      if (prefs.containsKey(key) && !await prefs.remove(key)) {
        throw StateError('Could not remove a legacy session value');
      }
    }
  }

  static Future<void> _retryLegacyCleanup(SharedPreferences prefs) async {
    try {
      await _clearLegacy(prefs);
    } catch (_) {
      debugPrint('Legacy credential cleanup will be retried on the next read.');
    }
  }

  static Map<String, dynamic> _validate(dynamic value) {
    if (value is! Map<String, dynamic> ||
        value['token'] is! String ||
        (value['token'] as String).isEmpty ||
        value['user'] is! Map<String, dynamic> ||
        value['user']['id'] is! int ||
        (value['refreshToken'] != null && value['refreshToken'] is! String)) {
      throw const FormatException('Invalid stored session');
    }
    return value;
  }

  static Future<Map<String, dynamic>?> read() => _run(() async {
        final prefs = await SharedPreferences.getInstance();
        if (prefs.getBool(_signedOut) == true) {
          // The device may have been locked when sign-out tried removing the old key.
          try {
            await _storage.delete(key: _key);
          } catch (_) {
            debugPrint('Secure credential cleanup is pending.');
          }
          await _retryLegacyCleanup(prefs);
          return null;
        }
        final stored = await _storage.read(key: _key);
        if (stored != null) {
          if (stored == _signedOut) {
            await _retryLegacyCleanup(prefs);
            return null;
          }
          final session = _validate(jsonDecode(stored));
          await _retryLegacyCleanup(prefs);
          return session;
        }
        final token = prefs.getString('auth_token');
        final user = prefs.getString('user_data');
        if (token == null || user == null) return null;
        final session = _validate({
          'token': token,
          'refreshToken': prefs.getString('refresh_token'),
          'user': jsonDecode(user),
        });
        await _storage.write(key: _key, value: jsonEncode(session));
        await _retryLegacyCleanup(prefs);
        return session;
      });

  static Future<void> save(
          String token, String? refreshToken, Map<String, dynamic> user) =>
      _run(() async {
        final prefs = await SharedPreferences.getInstance();
        await _storage.write(
            key: _key,
            value: jsonEncode({
              'token': token,
              'refreshToken': refreshToken,
              'user': user,
            }));
        if (prefs.containsKey(_signedOut) && !await prefs.remove(_signedOut)) {
          throw StateError('Could not persist the new sign-in');
        }
        await _retryLegacyCleanup(prefs);
      });

  static Future<void> clear() => _run(() async {
        SharedPreferences? prefs;
        bool marked = false;
        try {
          prefs = await SharedPreferences.getInstance();
          marked = await prefs.setBool(_signedOut, true);
        } catch (_) {
          // If preferences are unavailable, the secure store records sign-out itself.
        }
        if (marked) {
          try {
            await _storage.delete(key: _key);
          } catch (_) {
            debugPrint(
                'Secure credential cleanup will be retried after sign-out.');
          }
        } else {
          // A marker prevents recovery from old preferences even after a crash.
          await _storage.write(key: _key, value: _signedOut);
        }
        if (prefs != null) await _retryLegacyCleanup(prefs);
      });
}
