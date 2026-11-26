import '../../../core/api_endpoints.dart';
import '../../../services/api_service.dart';

Map<String, dynamic> normalizePracticeQuestion(Object? result, {int? expectedId}) {
  if (result is! Map<String, dynamic>) {
    throw const FormatException('Invalid practice question');
  }
  final value = result['id'];
  final text = value is String ? value.trim() : '';
  final id = value is int
      ? value
      : RegExp(r'^[0-9]+$').hasMatch(text) ? int.tryParse(text) : null;
  if (id == null || id <= 0 || id > 2147483647 ||
      (expectedId != null && id != expectedId)) {
    throw const FormatException('Invalid practice question ID');
  }
  final type = result['question_type'] ?? result['type'];
  return {
    ...result, 'id': id,
    if (type != null) 'question_type': type == 'relational_analysis' ? 'relation_analysis' : type,
  };
}

class QuestionCacheService {
  final ApiService _api;
  QuestionSession? _session;
  int? _account;

  QuestionCacheService(this._api);

  void watchAccount(int? account) {
    if (_account == account) return;
    _account = account;
    _session?.close();
  }

  QuestionSession open(String topic, {int? shown}) {
    _session?.close();
    final session = QuestionSession._(_api, topic, _api.userId, shown);
    _session = session;
    return session;
  }
}

/// At most one ordinary server selection is prefetched. A grading receipt
/// invalidates it because scheduled reviews and the student's level may change.
class QuestionSession {
  final ApiService _api;
  final String _topic;
  final int? _account;
  final Set<int> _shown;
  Future<Map<String, dynamic>?>? _pending;
  Future<Map<String, dynamic>?>? _unclaimed;
  bool _closed = false;

  QuestionSession._(this._api, this._topic, this._account, int? shown)
      : _shown = {if (shown != null) shown};

  bool get isActive => !_closed && _api.userId == _account;

  void _checkActive() {
    if (!isActive) {
      throw StateError('The study session changed');
    }
  }

  Future<Map<String, dynamic>?> _request() async {
    final endpoint = Uri.parse(ApiEndpoints.quizNext).replace(queryParameters: {
      'topic': _topic,
      if (_shown.isNotEmpty) 'exclude': _shown.join(','),
    });
    final result = await _api.get(endpoint.toString());
    _checkActive();
    if (result == null) return null;
    return normalizePracticeQuestion(result);
  }

  void prefetch() {
    _checkActive();
    if (_pending != null) return;
    final request = _request();
    _pending = _unclaimed = request;
    request.then<void>((_) {}, onError: (Object _, StackTrace __) {
      if (identical(_unclaimed, request)) invalidate();
    });
  }

  Future<Map<String, dynamic>?> next({bool prefetchNext = true}) async {
    while (true) {
      _checkActive();
      final request = _pending ??= _request();
      _unclaimed = null;
      Map<String, dynamic>? question;
      try {
        question = await request;
      } catch (_) {
        _checkActive();
        if (!identical(_pending, request)) continue;
        _pending = null;
        rethrow;
      }
      _checkActive();
      if (!identical(_pending, request)) continue;
      _pending = null;
      if (question == null) return null;
      if (!_shown.add(question['id'] as int)) {
        throw const FormatException('Received a previously shown question');
      }
      if (prefetchNext) prefetch();
      return question;
    }
  }

  void invalidate() {
    _pending = null;
    _unclaimed = null;
  }

  void close() {
    _closed = true;
    invalidate();
  }
}
