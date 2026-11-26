String _alias(String field) => switch (field) {
      'statement1' => 'statement_1',
      'statement2' => 'statement_2',
      _ => field,
    };

String _text(Object? raw, String language) {
  final value = raw is Map
      ? raw[language]
      : language == 'en'
          ? raw
          : null;
  return value is String && value.trim().isNotEmpty ? value : '';
}

bool relationValueValid(Object? value) =>
    value == null ||
    value is String ||
    value is Map &&
        ['en', 'hu']
            .every((lang) => value[lang] == null || value[lang] is String);

Object? _field(Map content, String field) {
  final canonical = content[field];
  if (_text(canonical, 'en').isNotEmpty || _text(canonical, 'hu').isNotEmpty) {
    return canonical;
  }
  return content[_alias(field)];
}

String relationText(Map content, String field, String language,
    {bool fallback = false}) {
  final raw = _field(content, field);
  final text = _text(raw, language);
  if (text.isNotEmpty || !fallback) return text;
  return _text(raw, language == 'en' ? 'hu' : 'en');
}

bool relationContentValid(Map content, {required bool hasPrompt}) {
  for (final key in [
    'statement1',
    'statement2',
    'statement_1',
    'statement_2',
    'link_word',
    'question_text'
  ]) {
    if (!relationValueValid(content[key])) return false;
  }
  final first = relationText(content, 'statement1', 'en', fallback: true);
  final second = relationText(content, 'statement2', 'en', fallback: true);
  if (first.isEmpty && second.isEmpty) return hasPrompt;
  return first.isNotEmpty && second.isNotEmpty;
}
