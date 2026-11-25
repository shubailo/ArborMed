import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api_exceptions.dart';
import '../../../database/database.dart';
import '../../../services/api_service.dart';

/// Durable FIFO for practice answers. A receipt and its local progress change
/// are acknowledged in one SQLite transaction, even after an app restart.
class SubmissionQueue {
  final AppDatabase db;
  final ApiService api;
  final _receipts = StreamController<Map<String, dynamic>>.broadcast(sync: true);
  Stream<Map<String, dynamic>> get receipts => _receipts.stream;
  Future<void> _work = Future.value();
  Timer? _retry;
  int? _account;
  bool _closed = false;

  SubmissionQueue(this.db, this.api);

  void watchAccount(int? userId) {
    if (_account == userId) return;
    _account = userId;
    _retry?.cancel();
    if (userId != null) unawaited(flush());
  }

  Future<String> enqueue(int userId, String topic, Map<String, dynamic> answer) async {
    if (_closed || api.userId != userId) {
      throw StateError('The active quiz account changed');
    }
    final id = const Uuid().v4();
    final payload = {...answer, 'submissionId': id, 'submissionUserId': userId};
    await db.customStatement(
      'INSERT INTO pending_submissions (submission_id,user_id,topic_slug,payload,created_at) VALUES (?,?,?,?,?)',
      [id, userId, topic, jsonEncode(payload), DateTime.now().millisecondsSinceEpoch],
    );
    return id;
  }

  Future<void> flush() {
    _work = _work.then((_) => _drain()).catchError((Object error) {
      debugPrint('Quiz sync paused: ${error.runtimeType}');
      _retryLater();
    });
    return _work;
  }

  void _retryLater() {
    if (_closed || (_retry?.isActive ?? false)) return;
    _retry = Timer(const Duration(seconds: 30), flush);
  }

  Future<void> _drain() async {
    final userId = api.userId;
    if (_closed || userId == null) return;
    while (!_closed && api.userId == userId) {
      final row = await db.customSelect(
        'SELECT * FROM pending_submissions WHERE user_id = ? AND failure IS NULL ORDER BY sequence LIMIT 1',
        variables: [Variable.withInt(userId)],
      ).getSingleOrNull();
      if (row == null || _closed || api.userId != userId) return;
      final id = row.read<String>('submission_id');
      final payload = jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
      late final Map<String, dynamic> receipt;
      try {
        final result = await api.post('/quiz/answer', payload);
        if (result is! Map<String, dynamic> || result['submissionId'] != id || result['isCorrect'] is! bool) {
          throw const FormatException('Invalid quiz receipt');
        }
        receipt = result;
      } on ApiException catch (e) {
        // A permanently rejected question must not block later answers.
        if (![400, 404, 409, 422].contains(e.statusCode)) rethrow;
        await db.customStatement('UPDATE pending_submissions SET failure = ? WHERE submission_id = ?', [e.message, id]);
        if (!_closed) _receipts.add({'submissionId': id, 'error': e.message});
        continue;
      }
      final acknowledged = await db.transaction(() async {
        final removed = await db.customUpdate(
          'DELETE FROM pending_submissions WHERE submission_id = ?',
          variables: [Variable.withString(id)],
        );
        if (removed == 0) return false;
        // Older receipts lack the server topic. A persisted review route is
        // a UI label, so it cannot identify a database topic.
        final topic = receipt['topicSlug'] as String? ?? row.read<String>('topic_slug');
        if (topic == 'review' || topic.isEmpty) return true;
        await db.customStatement('''
          INSERT INTO topic_progress (user_id,topic_slug,current_bloom_level,current_streak,mastery_score,
            level_correct_count,total_answered,correct_answered,last_studied_at)
          VALUES (?,?,?,?,?,?,1,?,?)
          ON CONFLICT(user_id,topic_slug) DO UPDATE SET
            current_bloom_level=excluded.current_bloom_level, current_streak=excluded.current_streak,
            mastery_score=excluded.mastery_score, level_correct_count=excluded.level_correct_count,
            total_answered=topic_progress.total_answered+1,
            correct_answered=topic_progress.correct_answered+excluded.correct_answered,
            last_studied_at=excluded.last_studied_at
        ''', [userId, topic, receipt['currentBloom'] ?? 1,
          receipt['streak'] ?? 0, receipt['mastery'] ?? 0, receipt['level_correct_count'] ?? 0,
          receipt['isCorrect'] ? 1 : 0, row.read<int>('created_at') ~/ 1000]);
        return true;
      });
      if (acknowledged && !_closed && api.userId == userId) _receipts.add(receipt);
    }
  }

  Future<void> dispose() async {
    _closed = true;
    _retry?.cancel();
    await _work;
    await _receipts.close();
  }
}
