import 'dart:async';
import 'dart:convert';

import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnusedDatabase extends Fake implements AppDatabase {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('a pending profile response cannot replace the next account', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final pending = Completer<http.Response>();
    final api = ApiService()..setHttpClient(MockClient((_) => pending.future));
    final auth = AuthProvider(apiService: api, db: _UnusedDatabase());
    await auth.setAuthDataFromResponse({'id': 1, 'token': 'first'});
    final refresh = auth.refreshUser();
    await auth.setAuthDataFromResponse({'id': 2, 'token': 'second'});
    pending.complete(http.Response(jsonEncode({'id': 1, 'coins': 200}), 200));
    await refresh;
    expect(auth.user?.id, 2);
    expect(auth.user?.coins, 0);
    expect(api.userId, 2);
    auth.dispose();
  });

  test(
      'a stale profile read preserves the confirmed nickname and updates other fields',
      () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final pending = Completer<http.Response>();
    final started = Completer<void>();
    final api = ApiService()
      ..setHttpClient(MockClient((request) async {
        if (request.method == 'PUT') {
          return http.Response(jsonEncode({'display_name': 'New'}), 200);
        }
        started.complete();
        return pending.future;
      }));
    final auth = AuthProvider(apiService: api, db: _UnusedDatabase());
    addTearDown(auth.dispose);
    await auth.setAuthDataFromResponse(
        {'id': 1, 'token': 'token', 'display_name': 'Old'});
    final refresh = auth.refreshUser();
    await started.future;
    await auth.updateNickname('New');
    pending.complete(http.Response(
        jsonEncode({'id': 1, 'display_name': 'Old', 'xp': 43}), 200));
    await refresh;
    expect(auth.user?.displayName, 'New');
    expect(auth.user?.xp, 43);
  });
}
