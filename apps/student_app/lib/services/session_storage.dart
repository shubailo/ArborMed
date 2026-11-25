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
          String token, String? refreshToken, Map<String, dynamic> user,
          {bool replaceSession = false}) =>
      _run(() async {
        final prefs = await _preferencesOrNull();
        if (replaceSession) await _invalidate(prefs);
        if (prefs == null) {
          // Keep the secure tombstone until legacy credentials can be cleaned.
          if (replaceSession) return;
          throw StateError('Session preferences are unavailable');
        }
        try {
          await _storage.write(
              key: _key,
              value: jsonEncode({
                'token': token,
                'refreshToken': refreshToken,
                'user': user,
              }));
          if (prefs.containsKey(_signedOut) &&
              !await prefs.remove(_signedOut)) {
            throw StateError('Could not persist the new sign-in');
          }
        } catch (_) {
          if (!replaceSession) rethrow;
          // Invalidation succeeded, so a memory-only session is safe.
          debugPrint('The new session could not be persisted.');
        }
        await _retryLegacyCleanup(prefs);
      });

  static Future<void> clear() => _run(() async {
        final prefs = await _preferencesOrNull();
        await _invalidate(prefs);
        if (prefs != null) await _retryLegacyCleanup(prefs);
      });

  static Future<SharedPreferences?> _preferencesOrNull() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  static Future<void> _invalidate(SharedPreferences? prefs) async {
    var marked = false;
    try {
      marked = await prefs?.setBool(_signedOut, true) ?? false;
    } catch (_) {
      // Fall back to recording sign-out in the secure store.
    }
    if (!marked) {
      await _storage.write(key: _key, value: _signedOut);
      return;
    }
    try {
      await _storage.delete(key: _key);
    } catch (_) {
      debugPrint('Secure credential cleanup will be retried after sign-out.');
    }
  }
}
