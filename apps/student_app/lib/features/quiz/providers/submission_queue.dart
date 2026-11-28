import 'dart:async';
import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

import '../../../core/api_exceptions.dart';
import '../../../database/database.dart';
import '../../../database/connection/browser_storage.dart';
import '../../../services/api_service.dart';

/// Durable FIFO for practice answers. A receipt and its local progress change
/// are acknowledged in one SQLite transaction, even after an app restart.
class SubmissionQueue {
  final AppDatabase db;
  final ApiService api;
  final _receipts =
      StreamController<Map<String, dynamic>>.broadcast(sync: true);
  Stream<Map<String, dynamic>> get receipts => _receipts.stream;
  Future<void> _work = Future.value();
  Timer? _retry;
  int? _account;
  int _generation = 0;
  bool _closed = false;

  SubmissionQueue(this.db, this.api);

  void watchAccount(int? userId) {
    if (_account == userId) return;
    _account = userId;
    _generation++;
    _retry?.cancel();
    if (userId != null) unawaited(flush());
  }

  Future<String> enqueue(
      int userId, String topic, Map<String, dynamic> answer) async {
    if (_closed || api.userId != userId) {
      throw StateError('The active quiz account changed');
    }
    final id = const Uuid().v4();
    final payload = {...answer, 'submissionId': id, 'submissionUserId': userId};
    final encoded = jsonEncode(payload);
    final generation = _generation;
    await db.ensureSubmissionStorage();
    if (!_active(userId, generation)) {
      throw StateError('The active quiz account changed');
    }
    await db.customStatement(
      'INSERT INTO pending_submissions (submission_id,user_id,topic_slug,payload,created_at) VALUES (?,?,?,?,?)',
      [id, userId, topic, encoded, DateTime.now().millisecondsSinceEpoch],
    );
    return id;
  }

  Future<void> flush() {
    _work = _work.then((_) => _drain()).catchError((Object error) {
      if (error is SubmissionStorageUnavailable) return;
      debugPrint('Quiz sync paused: ${error.runtimeType}');
      _retryLater();
    });
    return _work;
  }

  void _retryLater() {
    if (_closed || (_retry?.isActive ?? false)) return;
    _retry = Timer(const Duration(seconds: 30), flush);
  }

  Future<void> _reject(
      String id, int userId, String message, int generation) async {
    final changed = await db.customUpdate(
      'UPDATE pending_submissions SET failure = ? WHERE submission_id = ? AND user_id = ? AND failure IS NULL',
      variables: [
        Variable.withString(message),
        Variable.withString(id),
        Variable.withInt(userId)
      ],
    );
    if (changed == 1 && _active(userId, generation)) {
      _receipts.add({'submissionId': id, 'error': message});
    }
  }

  bool _active(int userId, int generation) =>
      !_closed && api.userId == userId && _generation == generation;

  Future<Map<String, dynamic>?> readReceipt(int userId, String id) async {
    final generation = _generation;
    if (!_active(userId, generation)) return null;
    final row = await db.customSelect(
      '''SELECT payload, NULL AS failure FROM submission_receipts
         WHERE submission_id = ?1 AND user_id = ?2
         UNION ALL
         SELECT NULL, failure FROM pending_submissions
         WHERE submission_id = ?1 AND user_id = ?2 AND failure IS NOT NULL''',
      variables: [Variable.withString(id), Variable.withInt(userId)],
    ).getSingleOrNull();
    if (row == null || !_active(userId, generation)) return null;
    final failure = row.readNullable<String>('failure');
    if (failure != null) return {'submissionId': id, 'error': failure};
    return jsonDecode(row.read<String>('payload')) as Map<String, dynamic>;
  }

  Future<void> _drain() async {
    final userId = api.userId;
    if (_closed || userId == null) return;
    final generation = _generation;
    await db.ensureSubmissionStorage();
    while (_active(userId, generation)) {
      final row = await db.customSelect(
        'SELECT * FROM pending_submissions WHERE user_id = ? AND failure IS NULL ORDER BY sequence LIMIT 1',
        variables: [Variable.withInt(userId)],
      ).getSingleOrNull();
      if (row == null || !_active(userId, generation)) return;
      final id = row.read<String>('submission_id');
      late final Map<String, dynamic> payload;
      try {
        final data = jsonDecode(row.read<String>('payload'));
        if (data is! Map<String, dynamic> ||
            (data['submissionId'] != null && data['submissionId'] != id) ||
            (data['submissionUserId'] != null &&
                data['submissionUserId'] != userId)) {
          throw const FormatException('Invalid queued answer');
        }
        payload = {...data, 'submissionId': id, 'submissionUserId': userId};
      } on FormatException {
        await _reject(id, userId, 'Invalid stored answer.', generation);
        continue;
      }
      late final Map<String, dynamic> receipt;
      try {
        final result = await api.post('/quiz/answer', payload);
        if (result is! Map<String, dynamic> ||
            result['submissionId'] != id ||
            result['isCorrect'] is! bool ||
            (result['topicSlug'] != null && result['topicSlug'] is! String) ||
            const ['currentBloom', 'streak', 'mastery', 'level_correct_count'].any(
                (key) => result[key] != null && result[key] is! int)) {
          throw const FormatException('Invalid quiz receipt');
        }
        receipt = result;
      } on ApiException catch (e) {
        // A permanently rejected question must not block later answers.
        if (![400, 404, 409, 422].contains(e.statusCode)) rethrow;
        if (!_active(userId, generation)) return;
        await _reject(id, userId, e.message, generation);
        continue;
      }
      if (!_active(userId, generation)) return;
      final acknowledged = await db.transaction(() async {
        if (!_active(userId, generation)) return false;
        final removed = await db.customUpdate(
          'DELETE FROM pending_submissions WHERE submission_id = ? AND user_id = ? AND failure IS NULL',
          variables: [Variable.withString(id), Variable.withInt(userId)],
        );
        if (removed == 0) return false;
        await db.customStatement(
          'INSERT INTO submission_receipts (submission_id, user_id, payload) VALUES (?, ?, ?)',
          [id, userId, jsonEncode(receipt)],
        );
        await db.customStatement('''
          DELETE FROM submission_receipts WHERE sequence <= (
            SELECT sequence FROM submission_receipts ORDER BY sequence DESC LIMIT 1 OFFSET 256
          )
        ''');
        // Older receipts lack the server topic. A persisted review route is
        // a UI label, so it cannot identify a database topic.
        final topic =
            receipt['topicSlug'] as String? ?? row.read<String>('topic_slug');
        if (topic == 'review' || topic.isEmpty) return true;
        await db.customStatement('''
          INSERT INTO topic_progress (user_id,topic_slug,current_bloom_level,current_streak,mastery_score,
            level_correct_count,total_answered,correct_answered,last_studied_at)
          VALUES (?,?,?,?,?,?,1,?,?)
          ON CONFLICT(user_id,topic_slug) DO UPDATE SET
            current_bloom_level=COALESCE(?,topic_progress.current_bloom_level),
            current_streak=COALESCE(?,topic_progress.current_streak),
            mastery_score=COALESCE(?,topic_progress.mastery_score),
            level_correct_count=COALESCE(?,topic_progress.level_correct_count),
            total_answered=topic_progress.total_answered+1,
            correct_answered=topic_progress.correct_answered+excluded.correct_answered,
            last_studied_at=excluded.last_studied_at
        ''', [
          userId,
          topic,
          receipt['currentBloom'] ?? 1,
          receipt['streak'] ?? 0,
          receipt['mastery'] ?? 0,
          receipt['level_correct_count'] ?? 0,
          receipt['isCorrect'] ? 1 : 0,
          row.read<int>('created_at') ~/ 1000,
          receipt['currentBloom'],
          receipt['streak'],
          receipt['mastery'],
          receipt['level_correct_count'],
        ]);
        return true;
      });
      if (acknowledged && _active(userId, generation)) _receipts.add(receipt);
    }
  }

  Future<void> dispose() async {
    _closed = true;
    _retry?.cancel();
    await _work;
    await _receipts.close();
  }
}
