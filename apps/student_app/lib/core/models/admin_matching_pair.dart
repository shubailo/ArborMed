/// A stored matching pair. Keep unedited pair and term fields across admin edits.
class AdminMatchingPair {
  final Map<String, dynamic> fields;

  const AdminMatchingPair([this.fields = const {}]);

  String text(String side, String language) {
    final term = fields[side];
    final value = term is Map
        ? term[language]
        : language == 'en'
            ? term
            : null;
    return value is String ? value : '';
  }

  Map<String, dynamic> edited({
    required String leftEn,
    required String leftHu,
    required String rightEn,
    required String rightHu,
  }) {
    Map<String, dynamic> term(String side, String en, String hu) => {
          if (fields[side] is Map) ...Map<String, dynamic>.from(fields[side]),
          'en': en,
          'hu': hu,
        };
    return {
      ...fields,
      'left': term('left', leftEn, leftHu),
      'right': term('right', rightEn, rightHu)
    };
  }

  static List<AdminMatchingPair> read(
      Object? content, Object? options, Object? answer) {
    final explicit = content is Map ? content['pairs'] : null;
    if (explicit is List && explicit.isNotEmpty) {
      return [
        for (final pair in explicit)
          AdminMatchingPair(
              pair is Map ? Map<String, dynamic>.from(pair) : const {})
      ];
    }
    if (explicit != null && explicit is! List) return const [];
    final english = options is List
        ? options
        : options is Map
            ? options['en']
            : null;
    final hungarian = options is Map ? options['hu'] : null;
    final leftHu = <String, String?>{};
    final rightHu = <String, String?>{};
    final lines = <(String, String)>[];
    if (english is List) {
      final aligned = hungarian is List && hungarian.length == english.length;
      for (var i = 0; i < english.length; i++) {
        final en = _split(english[i]);
        if (en == null) {
          // An admin can repair an unreadable row if there is no stored map.
          lines.add((english[i] is String ? english[i] as String : '', ''));
          continue;
        }
        lines.add(en);
        final hu = aligned ? _split(hungarian[i]) : null;
        if (hu != null) {
          _remember(leftHu, en.$1, hu.$1);
          _remember(rightHu, en.$2, hu.$2);
        }
      }
    }
    final terms = answer is Map && answer.isNotEmpty
        ? [
            for (final entry in answer.entries)
              (
                entry.key is String ? entry.key as String : '',
                entry.value is String ? entry.value as String : ''
              )
          ]
        : answer == null || answer is Map
            ? lines
            : const <(String, String)>[];
    return [
      for (final (left, right) in terms)
        AdminMatchingPair({
          'left': {'en': left, 'hu': leftHu[left] ?? ''},
          'right': {'en': right, 'hu': rightHu[right] ?? ''},
        })
    ];
  }

  static void _remember(
      Map<String, String?> labels, String key, String translation) {
    labels.update(key, (value) => value == translation ? value : null,
        ifAbsent: () => translation);
  }

  static final _arrow = RegExp(r'\s+(?:->|→)\s+');
  static final _colon = RegExp(r':\s+');
  static (String, String)? _split(Object? line) {
    if (line is! String) return null;
    final terms = line.split(_arrow.hasMatch(line) ? _arrow : _colon);
    if (terms.length != 2 || terms.any((term) => term.trim().isEmpty)) {
      return null;
    }
    return (terms.first.trim(), terms.last.trim());
  }
}
