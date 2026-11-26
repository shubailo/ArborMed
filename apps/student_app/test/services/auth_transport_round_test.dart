import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/session_storage.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _UnusedDb extends Fake implements AppDatabase {}

class _ReadingImage extends Fake implements XFile {
  final lengthReady = Completer<int>();
  @override
  String get name => 'test.png';
  @override
  Future<int> length() => lengthReady.future;
  @override
  Stream<Uint8List> openRead([int? start, int? end]) =>
      Stream.value(Uint8List.fromList([0]));
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late ApiService api;
  late AuthProvider auth;
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    api = ApiService()..setToken('');
    auth = AuthProvider(apiService: api, db: _UnusedDb());
  });
  tearDown(() {
    auth.dispose();
    api.onTokenRefreshed = null;
  });

  test('file downloads preserve the typed status and server explanation',
      () async {
    for (final entry in {
      403: isA<ForbiddenException>(),
      503: isA<ServerException>()
    }.entries) {
      api.setHttpClient(MockClient((_) async =>
          http.Response('{"message":"fixture detail"}', entry.key)));
      await expectLater(
          api.getBytes('/file'),
          throwsA(allOf(
              entry.value,
              isA<ApiException>()
                  .having((e) => e.message, 'message', 'fixture detail'))));
    }
  });
  test('finishing one operation keeps the form busy until the other finishes',
      () async {
    final responses = [Completer<http.Response>(), Completer<http.Response>()];
    var i = 0;
    api.setHttpClient(MockClient((_) => responses[i++].future));
    final first = auth.requestOTP('first@example.test');
    final second = auth.requestOTP('second@example.test');
    try {
      responses[0].complete(http.Response('{}', 200));
      await first;
      expect(auth.isLoading, isTrue);
    } finally {
      responses[1].complete(http.Response('{}', 200));
      await second;
    }
    expect(auth.isLoading, isFalse);
  });
  test('overlapping sign-ins honor the most recently requested account',
      () async {
    final replies = {
      for (final name in ['earlier', 'latest']) name: Completer<http.Response>()
    };
    api.setHttpClient(
        MockClient((req) => replies[jsonDecode(req.body)['username']]!.future));
    final first = auth.login('earlier', 'fixture');
    final last = auth.login('latest', 'fixture');
    final earlierOutcome =
        first.then<Object?>((_) => null, onError: (Object e) => e);
    final latestOutcome =
        last.then<Object?>((_) => null, onError: (Object e) => e);
    replies['earlier']!.complete(http.Response('{"id":1,"token":"one"}', 200));
    final stale = await earlierOutcome;
    replies['latest']!.complete(http.Response('{"id":2,"token":"two"}', 200));
    expect(await latestOutcome, isNull);
    expect(stale, isA<ApiException>());
    expect(auth.user?.id, 2);
    expect((await SessionStorage.read())?['token'], 'two');
  });
  test('a token refresh notifies dependants even when no profile field changes',
      () async {
    await auth.setAuthDataFromResponse(
        {'id': 7, 'token': 'before', 'refreshToken': 'refresh'});
    final observed = <String?>[];
    auth.addListener(() => observed.add(auth.token));
    api.setHttpClient(MockClient((request) async {
      if (request.url.path.endsWith('/refresh')) {
        return http.Response('{"token":"after"}', 200);
      }
      return request.headers['Authorization'] == 'Bearer after'
          ? http.Response('{}', 200)
          : http.Response('', 401);
    }));
    await api.get('/fixture');
    expect(observed, contains('after'));
    expect((await SessionStorage.read())?['token'], 'after');
  });
  test('switching account while reading image metadata cancels the upload',
      () async {
    final file = _ReadingImage();
    var uploaded = 0;
    api.setToken('first', userId: 1);
    api.setHttpClient(MockClient((_) async {
      uploaded++;
      return http.Response('{"imageUrl":"/saved.png"}', 200);
    }));
    final result = api.uploadImage(file);
    api.setToken('second', userId: 2);
    file.lengthReady.complete(1);
    expect(await result, isNull);
    expect(uploaded, 0);
  });
  test('disposing a token listener releases it and preserves a newer listener',
      () {
    final second = AuthProvider(apiService: api, db: _UnusedDb());
    final owned = api.onTokenRefreshed;
    final older = AuthProvider(apiService: api, db: _UnusedDb());
    api.onTokenRefreshed = owned;
    older.dispose();
    expect(api.onTokenRefreshed, same(owned));
    second.dispose();
    expect(api.onTokenRefreshed, isNull);
  });
}
