import 'dart:async';
import 'dart:convert';
import 'dart:collection';

import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _DeviceKeys extends MapBase<String, String> {
  final _values = <String, String>{};
  bool locked = false;

  @override
  String? operator [](Object? key) => _values[key];
  @override
  void operator []=(String key, String value) {
    if (locked) throw StateError('Device locked');
    _values[key] = value;
  }

  @override
  Iterable<String> get keys => _values.keys;
  @override
  String? remove(Object? key) {
    if (locked) throw StateError('Device locked');
    return _values.remove(key);
  }

  @override
  void clear() => _values.clear();
}

class _Cache extends Fake implements AppDatabase {
  final cleared = <int>[];
  @override
  Future<void> clearUserCacheFor(int userId) async {
    cleared.add(userId);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const secure = FlutterSecureStorage();
  const key = 'arbormed_session';
  late ApiService api;
  late _Cache cache;
  late AuthProvider auth;
  setUp(() {
    FlutterSecureStorage.setMockInitialValues({});
    SharedPreferences.setMockInitialValues({});
    api = ApiService()..setToken('');
    cache = _Cache();
    auth = AuthProvider(db: cache, apiService: api);
  });
  tearDown(() async {
    await SessionStorage.clear();
    api.onTokenRefreshed = null;
    auth.dispose();
  });

  test(
      'migrates the complete session and removes legacy credentials after writing it',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'old',
      'refresh_token': 'renew',
      'user_data': jsonEncode({'id': 7}),
    });
    final session = await SessionStorage.read();
    expect(session, {
      'token': 'old',
      'refreshToken': 'renew',
      'user': {'id': 7}
    });
    expect(jsonDecode((await secure.read(key: key))!), session);
    expect((await SharedPreferences.getInstance()).getKeys(),
        isNot(contains('auth_token')));
    expect(await SessionStorage.read(), session);
  });

  test('failed migration can retry from the untouched legacy session',
      () async {
    final keys = _DeviceKeys()..locked = true;
    FlutterSecureStorage.setMockInitialValues(keys);
    SharedPreferences.setMockInitialValues({
      'auth_token': 'legacy',
      'user_data': jsonEncode({'id': 7}),
    });
    await expectLater(SessionStorage.read(), throwsStateError);
    expect((await SharedPreferences.getInstance()).getString('auth_token'),
        'legacy');
    keys.locked = false;
    expect((await SessionStorage.read())?['token'], 'legacy');
    expect((await SharedPreferences.getInstance()).containsKey('auth_token'),
        isFalse);
  });

  test(
      'logout stays effective when key removal fails and cleanup retries after unlock',
      () async {
    final keys = _DeviceKeys();
    FlutterSecureStorage.setMockInitialValues(keys);
    await SessionStorage.save('expired', 'refresh', {'id': 7});
    keys.locked = true;
    await SessionStorage.clear();
    expect(keys.containsKey(key), isTrue);
    expect(await SessionStorage.read(), isNull);
    keys.locked = false;
    expect(await SessionStorage.read(), isNull);
    expect(keys.containsKey(key), isFalse);
    await SessionStorage.save('new', 'new-refresh', {'id': 8});
    expect((await SessionStorage.read())?['token'], 'new');
  });

  test('a corrupt secure value does not destroy intact recovery data',
      () async {
    SharedPreferences.setMockInitialValues({
      'auth_token': 'old',
      'refresh_token': 'renew',
      'user_data': jsonEncode({'id': 7}),
    });
    await secure.write(key: key, value: '{');
    await expectLater(SessionStorage.read(), throwsFormatException);
    expect(
        (await SharedPreferences.getInstance()).getString('auth_token'), 'old');
  });

  test(
      'refresh outage during restoration preserves the signed-in user and their cache',
      () async {
    await SessionStorage.save('expired', 'renew', {'id': 7});
    api.setHttpClient(MockClient((request) async =>
        request.url.path == ApiEndpoints.authRefresh
            ? http.Response('Unavailable', 503)
            : http.Response('Expired', 401)));
    await auth.tryAutoLogin();
    expect(auth.user?.id, 7);
    expect((await SessionStorage.read())?['refreshToken'], 'renew');
    expect(cache.cleared, isEmpty);
  });

  test('slow revocation cannot erase the next login or its cache', () async {
    final started = Completer<void>();
    final delayed = Completer<http.Response>();
    api.setHttpClient(MockClient((request) async {
      expect(request.url.path, ApiEndpoints.authLogout);
      expect(request.headers['Authorization'], 'Bearer access-A');
      expect(jsonDecode(request.body)['refreshToken'], 'refresh-A');
      started.complete();
      return delayed.future;
    }));
    auth.setAuthDataFromResponse(
        {'id': 1, 'token': 'access-A', 'refreshToken': 'refresh-A'});
    final signOut = auth.logout();
    await started.future;
    expect(auth.user, isNull);
    auth.setAuthDataFromResponse(
        {'id': 2, 'token': 'access-B', 'refreshToken': 'refresh-B'});
    delayed.complete(http.Response('{}', 200));
    await signOut;
    expect(auth.user?.id, 2);
    expect((await SessionStorage.read())?['token'], 'access-B');
    expect(cache.cleared, [1]);
  });

  test(
      'a late refresh from another session cannot retry the request with the new identity',
      () async {
    final refreshing = Completer<void>();
    final delayed = Completer<http.Response>();
    final tokens = <String?>[];
    api.setToken('access-A', refreshToken: 'refresh-A', userId: 1);
    api.setHttpClient(MockClient((request) async {
      if (request.url.path == ApiEndpoints.authRefresh) {
        refreshing.complete();
        return delayed.future;
      }
      tokens.add(request.headers['Authorization']);
      return http.Response('Expired', 401);
    }));
    final original = expectLater(
        api.post('/quiz/answer', {'id': 17}),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'cancelled', 0)));
    await refreshing.future;
    api.setToken('access-B', refreshToken: 'refresh-B', userId: 2);
    delayed.complete(http.Response('{"token":"reissued-A"}', 200));
    await original;
    expect(api.token, 'access-B');
    expect(tokens, ['Bearer access-A']);
  });

  test('a late successful response is discarded after logout', () async {
    final inFlight = Completer<http.Response>();
    api.setToken('access-A', refreshToken: 'refresh-A', userId: 1);
    api.setHttpClient(MockClient((_) => inFlight.future));
    final request = expectLater(
        api.get('/ecg/cases'),
        throwsA(
            isA<ApiException>().having((e) => e.statusCode, 'cancelled', 0)));
    api.setToken('');
    inFlight.complete(http.Response('[]', 200));
    await request;
  });

  test('a second 401 terminates the retry with exactly one token refresh',
      () async {
    api.setToken('access-A', refreshToken: 'refresh-A', userId: 1);
    int refreshes = 0;
    int attempts = 0;
    api.setHttpClient(MockClient((request) async {
      if (request.url.path == ApiEndpoints.authRefresh) {
        refreshes++;
        return http.Response('{"token":"new-access"}', 200);
      }
      attempts++;
      return http.Response('Rejected', 401);
    }));
    await expectLater(api.get('/profile-test'), throwsA(isA<AuthException>()));
    expect(refreshes, 1);
    expect(attempts, 2);
  });
}
