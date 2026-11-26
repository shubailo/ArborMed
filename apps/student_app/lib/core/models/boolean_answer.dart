import 'dart:convert';

bool? parseBooleanAnswer(Object? raw) {
  if (raw is bool) return raw;
  if (raw == 1) return true;
  if (raw == 0) return false;
  if (raw is! String) return null;
  return switch (raw.trim().toLowerCase()) {
    'true' || 'igaz' || '1' => true,
    'false' || 'hamis' || '0' => false,
    _ => null,
  };
}

// Historical TEXT keys may contain a JSON string or a singleton list.
bool? parseStoredBooleanAnswer(Object? raw) {
  if (raw is String) {
    final text = raw.trim();
    if (text.startsWith('[') || text.startsWith('"')) {
      try {
        raw = jsonDecode(text);
      } on FormatException {
        return null;
      }
    }
  }
  return parseBooleanAnswer(raw is List ? raw.singleOrNull : raw);
}
