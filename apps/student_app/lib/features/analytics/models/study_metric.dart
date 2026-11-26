/// PostgreSQL numeric fields may arrive as JSON strings in older responses.
double studyNumber(Object? value, {double? max}) {
  if (value == null) return 0;
  final number =
      value is num ? value.toDouble() : double.tryParse(value.toString());
  if (number == null ||
      !number.isFinite ||
      number < 0 ||
      (max != null && number > max)) {
    throw const FormatException('Invalid study metric');
  }
  return number;
}

String studyText(Object? value) => value is String ? value.trim() : '';

List<T> studyRows<T>(Object? raw, T Function(Map<String, dynamic>) parse) {
  if (raw is! List) {
    throw const FormatException('Expected a list of study topics');
  }
  final result = <T>[];
  for (final row in raw) {
    if (row is! Map<String, dynamic> || studyText(row['slug']).isEmpty) {
      continue;
    }
    try {
      result.add(parse(row));
    } on FormatException {
      // A damaged historical row need not hide the other topics.
      continue;
    }
  }
  if (raw.isNotEmpty && result.isEmpty) {
    throw const FormatException('No usable study topics');
  }
  return result;
}
