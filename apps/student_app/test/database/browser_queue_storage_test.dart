import 'package:arbor_med/database/connection/browser_storage.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/features/quiz/providers/submission_queue.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import '../services/quiz_controller_test.mocks.dart';

void main() {
  for (final safety in BrowserStorageSafety.values) {
    final persistent = safety == BrowserStorageSafety.sharedPersistent;
    test(
        'web storage safety determines whether an answer can be acknowledged locally ($safety)',
        () async {
      var opens = 0;
      final conn = BrowserStorageConnection(() async {
        opens++;
        return (executor: NativeDatabase.memory(), safety: safety);
      });
      final db = AppDatabase.forTesting(conn);
      final api = MockApiService();
      when(api.userId).thenReturn(1);
      final queue = SubmissionQueue(db, api);
      addTearDown(() async {
        await queue.dispose();
        await db.close();
      });
      final pending = queue.enqueue(1, 'ekg', {'questionId': 7});
      if (persistent) {
        expect(await pending, isNotEmpty);
      } else {
        await expectLater(pending, throwsStateError);
      }
      expect(
          (await db
                  .customSelect('SELECT COUNT(*) AS n FROM pending_submissions')
                  .getSingle())
              .data['n'],
          persistent ? 1 : 0);
      expect(opens, 1);
    });
  }

  test('an unsafe browser does not drain pre-existing pending answers', () async {
    final db = AppDatabase.forTesting(BrowserStorageConnection(() async =>
        (executor: NativeDatabase.memory(), safety: BrowserStorageSafety.singleTab)));
    final api = MockApiService();
    when(api.userId).thenReturn(1);
    final queue = SubmissionQueue(db, api);
    addTearDown(() async {
      await queue.dispose();
      await db.close();
    });
    await db.customStatement('''
      INSERT INTO pending_submissions(submission_id,user_id,topic_slug,payload,created_at)
      VALUES ('held',1,'ekg','{"questionId":7}',0)
    ''');
    await queue.flush();
    verifyNever(api.post('/quiz/answer', any));
    final pending = await db.customSelect('SELECT submission_id FROM pending_submissions').getSingle();
    expect(pending.read<String>('submission_id'), 'held');
  });
}
