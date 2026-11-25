import 'dart:async';

import 'package:arbor_med/features/quiz/providers/question_cache_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:arbor_med/services/api_service.dart';

@GenerateMocks([ApiService])
import 'question_cache_test.mocks.dart';

void main() {
  late MockApiService api;
  late QuestionCacheService cache;

  setUp(() {
    api = MockApiService();
    when(api.userId).thenReturn(7);
    cache = QuestionCacheService(api)..watchAccount(7);
  });

  test('ordinary selections respect SRS and exclude shown IDs', () async {
    var id = 0;
    when(api.get(any)).thenAnswer((_) async => {'id': ++id});
    final session = cache.open('renal & fluids');
    expect((await session.next())?['id'], 1);
    expect((await session.next(prefetchNext: false))?['id'], 2);
    final requests = verify(api.get(captureAny)).captured.cast<String>().map(Uri.parse).toList();
    expect(requests.map((r) => r.queryParameters), [
      {'topic': 'renal & fluids'},
      {'topic': 'renal & fluids', 'exclude': '1'},
    ]);
  });

  test('closing a topic or switching accounts discards in-flight results', () async {
    final old = Completer<dynamic>();
    when(api.get(any)).thenAnswer((_) => old.future);
    final session = cache.open('renal');
    final first = session.next();
    final secondSession = cache.open('cardiac');
    final second = secondSession.next();
    when(api.userId).thenReturn(8);
    cache.watchAccount(8);
    old.complete({'id': 1});
    await Future.wait([expectLater(first, throwsStateError), expectLater(second, throwsStateError)]);
    when(api.get(any)).thenAnswer((_) async => {'id': 2});
    expect((await cache.open('cardiac').next(prefetchNext: false))?['id'], 2);
  });

  test('a receipt replaces an in-flight selection with a fresh one', () async {
    final stale = Completer<dynamic>();
    var calls = 0;
    when(api.get(any)).thenAnswer((_) async {
      calls++;
      if (calls == 1) return await stale.future;
      return {'id': 3, 'selectionReason': 'SRS_REVIEW'};
    });
    final session = cache.open('renal', shown: 1);
    final pending = session.next(prefetchNext: false);
    session.invalidate();
    stale.complete({'id': 2});
    expect((await pending)?['id'], 3);
    expect(calls, 2);
  });

  test('duplicate responses stop after one request and allow a later retry', () async {
    final session = cache.open('renal', shown: 1);
    when(api.get(any)).thenAnswer((_) async => {'id': 1});
    await expectLater(session.next(), throwsFormatException);
    verify(api.get(any)).called(1);
    when(api.get(any)).thenAnswer((_) async => {'id': 2});
    expect((await session.next(prefetchNext: false))?['id'], 2);
  });
}
