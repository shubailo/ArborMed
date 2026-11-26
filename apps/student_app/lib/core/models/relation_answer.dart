import 'dart:convert';

import '../../generated/l10n/app_localizations.dart';

enum RelationAnswer {
  a,
  b,
  c,
  d,
  e;

  String get code => name.toUpperCase();

  static RelationAnswer? fromInput(Object? raw) {
    if (raw is! String) return null;
    return switch (raw.trim().toUpperCase()) {
      'A' => a,
      'B' => b,
      'C' => c,
      'D' => d,
      'E' => e,
      _ => null,
    };
  }

  static RelationAnswer? fromStored(Object? raw) {
    if (raw is String &&
        (raw.trimLeft().startsWith('[') || raw.trimLeft().startsWith('"'))) {
      try {
        raw = jsonDecode(raw);
      } on FormatException {
        return null;
      }
    }
    return fromInput(raw is List ? raw.singleOrNull : raw);
  }

  String label(AppLocalizations l) => switch (this) {
        a => l.relationAnswerA,
        b => l.relationAnswerB,
        c => l.relationAnswerC,
        d => l.relationAnswerD,
        e => l.relationAnswerE,
      };
}
