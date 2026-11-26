import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'question.dart';
import 'admin_matching_pair.dart';

class AdminQuestion extends CoreQuestion {
  final String? topicNameEn;
  final String? topicNameHu;
  final int attempts;
  final double successRate;
  final int reportCount;

  bool get supportsEditing => const {
        'single_choice',
        'multiple_choice',
        'matching',
        'true_false',
        'relation_analysis',
      }.contains(type);

  AdminQuestion({
    required super.id,
    super.text,
    super.questionTextHu,
    required super.options,
    super.content,
    required super.correctAnswer,
    super.explanation,
    super.explanationHu,
    required super.topicId,
    required super.bloomLevel,
    super.type,
    this.topicNameEn,
    this.topicNameHu,
    this.attempts = 0,
    this.successRate = 0.0,
    this.reportCount = 0,
  });

  String? questionLabel(String languageCode) => languageCode == 'hu'
      ? _firstText([questionTextHu, text])
      : _firstText([text, questionTextHu]);

  String? topicLabel(String languageCode) => languageCode == 'hu'
      ? _firstText([topicNameHu, topicNameEn])
      : _firstText([topicNameEn, topicNameHu]);

  String? explanationLabel(String languageCode) => languageCode == 'hu'
      ? _firstText([explanationHu, explanation])
      : _firstText([explanation, explanationHu]);

  late final List<AdminChoice> choices =
      List.unmodifiable(AdminChoice._read(options));
  late final List<Object?> answerKeys = _keys(correctAnswer);

  late final List<AdminMatchingPair> matchingPairs = List.unmodifiable(
      AdminMatchingPair.read(content, options, answerKeys.singleOrNull));

  late final bool hasMatchingKeyConflict = _matchingKeyConflicts();

  bool _matchingKeyConflicts() {
    if (type != 'matching') return false;
    final stored = _decoded(correctAnswer);
    if (stored == null || stored is Map && stored.isEmpty) return false;
    if (stored is! Map || stored.length != matchingPairs.length) return true;
    return matchingPairs.any(
        (pair) => stored[pair.text('left', 'en')] != pair.text('right', 'en'));
  }

  static List<Object?> _keys(Object? raw) {
    final value = _decoded(raw);
    return List.unmodifiable(
        value is List ? value : [if (value != null) value]);
  }

  // A null entry marks an ambiguous label or repeated ID in historical data.
  late final _ids = _indexChoices((choice) => [choice.id]);
  late final _historicalIds = _indexChoices(
      (choice) => [if (choice.previousId != null) choice.previousId!]);
  late final _labels = _indexChoices((choice) => [choice.en, choice.hu]);

  Map<String, int?> _indexChoices(Iterable<String> Function(AdminChoice) keys) {
    final result = <String, int?>{};
    for (var i = 0; i < choices.length; i++) {
      for (final value in keys(choices[i])) {
        final key = value.trim().toLowerCase();
        if (key.isEmpty) continue;
        if (!result.containsKey(key)) {
          result[key] = i;
        } else if (result[key] != i) {
          result[key] = null;
        }
      }
    }
    return result;
  }

  int? choiceIndex(Object? key) {
    if (key is! String && key is! num) return null;
    final text = key.toString().trim();
    if (text.isEmpty) return null;
    final label = text.toLowerCase();
    if (_ids.containsKey(label)) return _ids[label];
    if (_historicalIds.containsKey(label)) return _historicalIds[label];
    final authoredId = AdminChoice._stableId(text);
    final authored = _ids[authoredId];
    if (!_labels.containsKey(label)) return authored;
    final named = _labels[label];
    return !_ids.containsKey(authoredId) || authored == named ? named : null;
  }

  @override
  List<String>? get optionsHu {
    if (choices.any((choice) => choice.hu.isNotEmpty)) {
      return choices.map((choice) => choice.label('hu')).toList();
    }
    return null;
  }

  factory AdminQuestion.fromJson(Map<String, dynamic> json) {
    final rawContent = _decoded(json['content']);
    final content =
        rawContent is Map ? Map<String, dynamic>.from(rawContent) : null;
    final prompt = content?['question_text'] ?? content?['statement'];
    final top = json['text'];
    final explanation = json['explanation'];
    final options = [
      _decoded(json['options']),
      _decoded(content?['options']),
      {'en': _decoded(json['options_en']), 'hu': _decoded(json['options_hu'])}
    ].where(AdminChoice._hasLists).firstOrNull;
    return AdminQuestion(
      id: _integer(json['id'], 'id', minimum: 1),
      topicId: _integer(json['topic_id'], 'topic_id', minimum: 1),
      text: _firstText([
        top,
        json['question_text_en'],
        if (top is Map) top['en'],
        if (prompt is Map) prompt['en'] else prompt
      ]),
      questionTextHu: _firstText([
        json['question_text_hu'],
        if (top is Map) top['hu'],
        if (prompt is Map) prompt['hu']
      ]),
      options: options ?? _decoded(json['options']),
      content: content,
      correctAnswer: json['correct_answer'],
      explanation: _firstText([
        explanation,
        json['explanation_en'],
        if (explanation is Map) explanation['en']
      ]),
      explanationHu: _firstText(
          [json['explanation_hu'], if (explanation is Map) explanation['hu']]),
      topicNameEn: _firstText([json['topic_name'], json['name_en']]),
      topicNameHu: _firstText([json['topic_name_hu'], json['name_hu']]),
      bloomLevel: _integer(json['bloom_level'] ?? 1, 'bloom_level'),
      type:
          _firstText([json['question_type'], json['type']]) ?? 'single_choice',
      attempts: _integer(json['attempts'] ?? 0, 'attempts'),
      successRate: _rate(json['success_rate']),
      reportCount: _integer(json['report_count'] ?? 0, 'report_count'),
    );
  }
}

Object? _decoded(Object? raw) {
  if (raw is! String || !RegExp(r'^[\[{"]').hasMatch(raw.trimLeft())) {
    return raw;
  }
  try {
    return jsonDecode(raw);
  } on FormatException {
    return raw;
  }
}

String? _firstText(Iterable<Object?> values) =>
    values.whereType<String>().where((s) => s.trim().isNotEmpty).firstOrNull;

int _integer(Object? value, String field, {int minimum = 0}) {
  final result = value is int
      ? value
      : (value is String ? int.tryParse(value.trim()) : null);
  if (result == null || result < minimum) {
    throw FormatException('Invalid $field');
  }
  return result;
}

double _rate(Object? value) {
  if (value == null) return 0;
  final result = double.tryParse(value.toString());
  if (result == null || !result.isFinite) {
    throw const FormatException('Invalid success_rate');
  }
  return result;
}

class AdminChoice {
  final String en;
  final String hu;
  final Object? source;
  final String id;
  final String? previousId;
  AdminChoice._(this.en, this.hu, this.source, String key, String previousKey)
      : id = _stableId(key),
        previousId = previousKey == key ? null : _stableId(previousKey);

  String label(String languageCode) =>
      languageCode == 'hu' ? (hu.isEmpty ? en : hu) : (en.isEmpty ? hu : en);

  static String _stableId(String key) =>
      'opt_${sha256.convert(utf8.encode(key)).toString().substring(0, 32)}';

  static bool _hasLists(Object? value) =>
      value is List && value.isNotEmpty ||
      value is Map &&
          [value['en'], value['hu']].any((v) => v is List && v.isNotEmpty);

  static List<AdminChoice> _read(Object? raw) {
    final data = _decoded(raw);
    final english = data is List
        ? data
        : data is Map && data['en'] is List
            ? data['en'] as List
            : const [];
    final hungarian =
        data is Map && data['hu'] is List ? data['hu'] as List : const [];
    final entries = english.isEmpty ? hungarian : english;
    final result = <AdminChoice>[];
    for (int i = 0; i < entries.length; i++) {
      final raw = entries[i];
      final translated = i < hungarian.length ? hungarian[i] : null;
      final entry = raw is String && raw.trim().isEmpty && translated is Map
          ? translated
          : raw;
      final fields = entry is Map ? entry : const {};
      final primary = english.isNotEmpty && identical(raw, entry);
      final hu = _firstText([
            fields['hu'],
            if (translated is Map) ...[
              translated['hu'],
              translated['text'],
              translated['label'],
              if (translated['value'] is num)
                translated['value'].toString()
              else
                translated['value']
            ] else
              translated
          ]) ??
          '';
      final en = _firstText([
            fields['en'],
            if (primary) ...[fields['label'], fields['text'], raw],
            if (primary && _firstText([fields['hu']]) == null)
              (fields['value'] is num
                  ? fields['value'].toString()
                  : fields['value'])
          ]) ??
          '';
      if (en.isEmpty && hu.isEmpty) continue;
      final authored = _firstText([
        for (final k in [fields['id'], fields['value']])
          if (k is String || k is num) k.toString()
      ]);
      final previousKey = raw is Map
          ? raw['id'] ??
              raw['value'] ??
              raw['en'] ??
              raw['label'] ??
              raw['text'] ??
              raw['hu'] ??
              ''
          : raw is String
              ? raw
              : '';
      result.add(AdminChoice._(en, hu, entry,
          authored ?? (en.isEmpty ? hu : en), previousKey.toString()));
    }
    return result;
  }
}
