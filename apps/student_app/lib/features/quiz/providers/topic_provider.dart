import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/core/models/topic.dart';

class TopicDeleteConfirmation {
  final int count;
  final String version;
  const TopicDeleteConfirmation(this.count, this.version);
}

class TopicProvider with ChangeNotifier {
  final AuthProvider authProvider;
  TopicProvider(this.authProvider)
      : _authRevision = authProvider.sessionRevision {
    authProvider.addListener(_syncSession);
  }

  int _authRevision;
  int _generation = 0;
  int _read = 0;
  int get sessionRevision => _generation;
  bool _disposed = false;
  bool _loading = false;
  bool get loading => _loading;
  bool _loadFailed = false;
  bool get loadFailed => _loadFailed;
  List<Map<String, dynamic>> _topics = const [];
  List<Map<String, dynamic>> get topics => _topics;

  void _syncSession() {
    if (_authRevision != authProvider.sessionRevision) {
      _authRevision = authProvider.sessionRevision;
      resetState();
    }
  }

  // Older admin screens also read fields outside the shared Topic model.
  Map<String, dynamic> _row(dynamic value) {
    final data = value as Map<String, dynamic>;
    return Map.unmodifiable({...data, ...Topic.fromJson(data).toJson()});
  }

  Future<void> fetchTopics() async {
    final request = ++_read;
    _loading = true;
    _loadFailed = false;
    notifyListeners();
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizTopics);
      if (_disposed || request != _read) return;
      _topics = List.unmodifiable((data as List).map(_row));
    } catch (error) {
      if (_disposed || request != _read) return;
      _loadFailed = true;
      debugPrint('Topic catalog load failed (${error.runtimeType}).');
    } finally {
      if (!_disposed && request == _read) {
        _loading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _refreshAfterWrite(int session,
      {dynamic saved, int? expectedId, int? deleted}) async {
    if (_disposed || session != _generation) return;
    Map<String, dynamic>? row;
    if (saved is Map<String, dynamic> &&
        (saved['name_en'] is String || saved['name'] is String)) {
      try {
        final receipt = _row(saved);
        if (expectedId == null || receipt['id'] == expectedId) row = receipt;
      } on FormatException {
        // Some older services return only an acknowledgement. Reload the committed row.
      } on TypeError {
        // A malformed receipt must not invite resubmitting a committed write.
      }
    }
    if (row != null || deleted != null) {
      final id = row?['id'] ?? deleted;
      final present = _topics.any((t) => t['id'] == id);
      _topics = List.unmodifiable([
        for (final t in _topics)
          if (t['id'] != id)
            t
          else if (row != null)
            Map<String, dynamic>.unmodifiable({
              ...t,
              ...row,
              'question_count': row['question_count'] ?? t['question_count']
            }),
        if (!present && row != null) row,
      ]);
    }
    await fetchTopics();
  }

  Future<void> createTopic(String nameEn, String nameHu, int? parentId) async {
    final session = _generation;
    final data =
        await authProvider.apiService.post(ApiEndpoints.quizAdminTopics, {
      'name_en': nameEn.trim(),
      'name_hu': nameHu.trim(),
      'parent_id': parentId,
    });
    await _refreshAfterWrite(session, saved: data);
  }

  Future<void> updateTopic(int id, String nameEn, String nameHu) async {
    final session = _generation;
    final data = await authProvider.apiService
        .put('${ApiEndpoints.quizAdminTopics}/$id', {
      'name_en': nameEn.trim(),
      'name_hu': nameHu.trim(),
    });
    await _refreshAfterWrite(session, saved: data, expectedId: id);
  }

  Future<TopicDeleteConfirmation?> deleteTopic(int id,
      {String? confirmation}) async {
    final session = _generation;
    final path = Uri.parse('${ApiEndpoints.quizAdminTopics}/$id');
    final uri = confirmation == null
        ? path
        : path.replace(
            queryParameters: {'force': 'true', 'confirmation': confirmation});
    try {
      await authProvider.apiService.delete(uri.toString());
    } on ConflictException catch (error) {
      if (_disposed || session != _generation) return null;
      dynamic data;
      try {
        data = jsonDecode(error.body ?? '');
      } on FormatException {/* Ordinary conflict. */}
      if (data is Map &&
          data['code'] == 'topic_questions_confirmation' &&
          data['count'] is int &&
          data['count'] > 0 &&
          data['confirmation'] is String &&
          (data['confirmation'] as String).isNotEmpty) {
        return TopicDeleteConfirmation(data['count'], data['confirmation']);
      }
      rethrow;
    }
    await _refreshAfterWrite(session, deleted: id);
    return null;
  }

  void resetState() {
    _generation++;
    _read++;
    _topics = const [];
    _loading = false;
    _loadFailed = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    authProvider.removeListener(_syncSession);
    super.dispose();
  }
}
