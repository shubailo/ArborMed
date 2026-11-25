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
    auth.setAuthDataFromResponse({'id': 1, 'token': 'first'});
    final refresh = auth.refreshUser();
    auth.setAuthDataFromResponse({'id': 2, 'token': 'second'});
    pending.complete(http.Response(jsonEncode({'id': 1, 'coins': 200}), 200));
    await refresh;
    expect(auth.user?.id, 2);
    expect(auth.user?.coins, 0);
    expect(api.userId, 2);
    auth.dispose();
  });
}
