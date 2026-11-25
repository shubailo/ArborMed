import '../../../core/api_endpoints.dart';
import '../../../services/api_service.dart';

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
    if (result is! Map<String, dynamic> ||
        int.tryParse(result['id'].toString()) == null) {
      throw const FormatException('Invalid practice question');
    }
    return result;
  }

  void prefetch() {
    _checkActive();
    (_pending ??= _request()).ignore();
  }

  Future<Map<String, dynamic>?> next({bool prefetchNext = true}) async {
    while (true) {
      _checkActive();
      final request = _pending ??= _request();
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
      if (!_shown.add(int.parse(question['id'].toString()))) {
        throw const FormatException('Received a previously shown question');
      }
      if (prefetchNext) prefetch();
      return question;
    }
  }

  void invalidate() => _pending = null;

  void close() {
    _closed = true;
    invalidate();
  }
}
