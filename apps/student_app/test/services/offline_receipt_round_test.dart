import 'dart:async';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/features/quiz/providers/submission_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'quiz_controller_test.mocks.dart';

void main() {
  late AppDatabase db;
  late MockApiService api;
  late SubmissionQueue queue;
  late int account;
  late List<Map<String, dynamic>> events;
  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = MockApiService();
    account = 1;
    when(api.userId).thenAnswer((_) => account);
    queue = SubmissionQueue(db, api);
    events = [];
    final sub = queue.receipts.listen(events.add);
    addTearDown(() async {
      await sub.cancel();
      await queue.dispose();
      await db.close();
    });
  });
  Future<void> raw(String id, String content) => db.customStatement(
      "INSERT INTO pending_submissions(submission_id,user_id,topic_slug,payload,created_at) VALUES (?,1,'ekg',?,1000)",
      [id, content]);
  Future<List<String>> failed() async => (await db
          .customSelect(
              'SELECT submission_id FROM pending_submissions WHERE failure IS NOT NULL ORDER BY sequence')
          .get())
      .map((r) => r.read<String>('submission_id'))
      .toList();
  test(
      'a malformed row is retained for inspection and later answers still sync',
      () async {
    await raw('broken', '{');
    await raw('list', '[]');
    await raw('mismatched', '{"submissionId":"other","questionId":10}');
    await raw('legacy', '{"questionId":10,"userAnswer":"a"}');
    final sent = <Map<String, dynamic>>[];
    when(api.post(any, any)).thenAnswer((call) async {
      final payload = call.positionalArguments[1] as Map<String, dynamic>;
      sent.add(payload);
      return {'submissionId': payload['submissionId'], 'isCorrect': true};
    });
    await queue.flush();
    expect(await failed(), ['broken', 'list', 'mismatched']);
    expect(sent.single, {
      'submissionId': 'legacy',
      'submissionUserId': 1,
      'questionId': 10,
      'userAnswer': 'a'
    });
    expect(events.map((e) => e['submissionId']),
        ['broken', 'list', 'mismatched', 'legacy']);
  });
  for (final permanent in [true, false]) {
    test(
        'an outgoing account keeps its pending answer during a late reply (permanent=$permanent)',
        () async {
      final id = await queue.enqueue(1, 'ekg', {'questionId': 10});
      final received = Completer<void>();
      final reply = Completer<Map<String, dynamic>>();
      when(api.post(any, any)).thenAnswer((_) {
        received.complete();
        return reply.future;
      });
      final sending = queue.flush();
      await received.future;
      account = 2;
      queue.watchAccount(2);
      await db.clearUserCacheFor(1);
      if (permanent) {
        reply.completeError(const ApiException(
            statusCode: 422, message: 'Question was retired'));
      } else {
        reply.complete(
            {'submissionId': id, 'isCorrect': true, 'topicSlug': 'ekg'});
      }
      await sending;
      expect(events, isEmpty);
      final row = await db
          .customSelect('SELECT failure FROM pending_submissions')
          .getSingle();
      expect(row.data['failure'], isNull);
      expect(
          await db.customSelect('SELECT * FROM topic_progress').get(), isEmpty);
      account = 1;
      when(api.post(any, any)).thenAnswer((_) async {
        if (permanent) {
          throw const ApiException(
              statusCode: 422, message: 'Question was retired');
        }
        return {'submissionId': id, 'isCorrect': true, 'topicSlug': 'ekg'};
      });
      queue.watchAccount(1);
      await queue.flush();
      expect(events.single['submissionId'], id);
      expect(events.single.containsKey('error'), permanent);
    });
  }
  test('sparse acknowledgements count once without resetting known progress', () async {
    final first = await queue.enqueue(1, 'ekg', {'questionId': 10});
    await queue.enqueue(1, 'ekg', {'questionId': 11});
    when(api.post(any, any)).thenAnswer((call) async {
      final id = call.positionalArguments[1]['submissionId'];
      return {'submissionId': id, 'isCorrect': id == first, if (id == first) ...{
        'currentBloom': 4, 'streak': 3, 'mastery': 74, 'level_correct_count': 2
      }};
    });
    await queue.flush();
    await queue.flush();
    final progress = await db.select(db.topicProgress).getSingle();
    expect([progress.currentBloomLevel, progress.currentStreak, progress.masteryScore,
        progress.levelCorrectCount, progress.totalAnswered, progress.correctAnswered],
        [4, 3, 74, 2, 2, 1]);
  });

  test('malformed receipt metrics retain the original answer until a valid retry', () async {
    final id = await queue.enqueue(1, 'ekg', {'questionId': 10});
    when(api.post(any, any)).thenAnswer((_) async =>
        {'submissionId': id, 'isCorrect': true, 'currentBloom': 'high'});
    await queue.flush();
    expect(events, isEmpty);
    expect(await db.customSelect('SELECT * FROM topic_progress').get(), isEmpty);
    expect((await db.customSelect('SELECT submission_id FROM pending_submissions').getSingle()).data['submission_id'], id);
    when(api.post(any, any)).thenAnswer((_) async =>
        {'submissionId': id, 'isCorrect': true, 'currentBloom': 2});
    await queue.flush();
    expect(events.single['submissionId'], id);
    expect((await db.select(db.topicProgress).getSingle()).totalAnswered, 1);
  });

  test('an invalid network receipt leaves the local answer available to retry',
      () async {
    final id = await queue.enqueue(1, 'ekg', {'questionId': 10});
    when(api.post(any, any)).thenAnswer(
        (_) async => {'submissionId': 'unrelated', 'isCorrect': true});
    await queue.flush();
    expect(await failed(), isEmpty);
    expect(
        (await db
                .customSelect('SELECT submission_id FROM pending_submissions')
                .getSingle())
            .data['submission_id'],
        id);
    expect(events, isEmpty);
  });
}
