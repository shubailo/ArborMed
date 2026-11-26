import 'dart:async';
import 'package:arbor_med/core/api_exceptions.dart';

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

  test('a completed failed warm-up is retried on the first foreground load', () async {
    var calls = 0;
    when(api.get(any)).thenAnswer((_) async {
      if (++calls == 1) throw StateError('temporary failure');
      return {'id': 8};
    });
    final session = cache.open('renal')..prefetch();
    await Future<void>.delayed(Duration.zero);
    expect((await session.next(prefetchNext: false))?['id'], 8);
    expect(calls, 2);
  });

  test('a foreground caller sees its own failure once and can retry', () async {
    final pending = Completer<dynamic>();
    when(api.get(any)).thenAnswer((_) => pending.future);
    final session = cache.open('renal')..prefetch();
    final check = expectLater(session.next(prefetchNext: false), throwsStateError);
    pending.completeError(StateError('temporary failure'));
    await check;
    verify(api.get(any)).called(1);
    when(api.get(any)).thenAnswer((_) async => {'id': 8});
    expect((await session.next(prefetchNext: false))?['id'], 8);
  });

  test('practice IDs use the positive int4 contract and arrive as integers', () async {
    for (final invalid in [0, -1, 2147483648, '0x10', '12.5', true, null]) {
      when(api.get(any)).thenAnswer((_) async => {'id': invalid});
      await expectLater(cache.open('renal').next(prefetchNext: false), throwsFormatException);
    }
    when(api.get(any)).thenAnswer((_) async => {'id': ' 0007 '});
    expect((await cache.open('renal').next(prefetchNext: false))?['id'], 7);
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

  test('a prefetched end-of-topic is consumed without another selection', () async {
    when(api.get(any)).thenAnswer((_) async => throw const ApiException(
        statusCode: 404, message: 'No more questions available for this topic'));
    final session = cache.open('renal')..prefetch();
    await Future<void>.delayed(Duration.zero);
    expect(await session.next(prefetchNext: false), isNull);
    verify(api.get(any)).called(1);
    when(api.get(any)).thenAnswer((_) async => {'id': 19});
    expect((await session.next(prefetchNext: false))?['id'], 19);
  });

  test('other 404s remain ordinary request failures', () async {
    when(api.get(any)).thenAnswer((_) async => throw const ApiException(
        statusCode: 404, message: 'Route not found'));
    await expectLater(cache.open('renal').next(), throwsA(isA<ApiException>()));
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
