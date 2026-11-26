import 'package:arbor_med/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'dart:convert';

/// Abstract base class for all question renderers
/// Each question type must implement this interface
abstract class QuestionRenderer {
  /// Build the question display widget
  /// This shows the question content (text, statements, images, etc.)
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question);

  /// Build the answer input widget
  /// This shows the interactive elements for answering (radio buttons, checkboxes, etc.)
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged, {
    bool isChecked = false,
    dynamic correctAnswer,
  });

  /// Validate if the user has provided an answer
  bool hasAnswer(dynamic answer);

  /// Get the user's answer in the format expected by the backend
  dynamic formatAnswer(dynamic answer);

  /// Locally validate if the answer is correct
  bool validateAnswer(
    dynamic userAnswer,
    dynamic correctAnswer,
    Map<String, dynamic> question,
  );

  /// Get the answer result for a given index (0-based)
  /// Used for keyboard shortcuts (1, 2, 3...)
  dynamic getAnswerForIndex(
    BuildContext context,
    Map<String, dynamic> question,
    int index,
    dynamic currentAnswer,
  );

  String? questionImageUrl(Map<String, dynamic> question) {
    final content = question['content'];
    final raw = content is Map ? content['image_url'] : null;
    Uri? image;
    if (raw is String && raw.trim().isNotEmpty) {
      final reference = Uri.tryParse(raw.trim());
      if (reference != null) {
        final uri = Uri.parse(ApiService.baseUrl).resolveUri(reference);
        if ((uri.scheme == 'https' || uri.scheme == 'http') &&
            uri.host.isNotEmpty) {
          image = uri;
        }
      }
    }
    return image?.toString();
  }

  /// Helper: Show full-screen zoomed image
  void showZoomedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: CozyTheme.of(
          context,
          listen: false,
        ).textPrimary.withValues(alpha: 0.9),
        body: Stack(
          children: [
            Center(
              child: Tooltip(
                message: 'Pan and zoom image',
                child: InteractiveViewer(
                  minScale: 0.5,
                  maxScale: 4.0,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    width: double.infinity,
                    height: double.infinity,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: Icon(
                  Icons.close,
                  color: CozyTheme.of(context, listen: false).textInverse,
                  size: 30,
                ),
                tooltip: 'Close',
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Get localized text from question map
  String getLocalizedText(
    BuildContext context,
    Map<String, dynamic> question, {
    String? defaultText,
  }) {
    final lang = Localizations.localeOf(context).languageCode;

    final content = question['content'];
    final prompt = content is Map ? content['question_text'] : null;
    for (final candidate in [
      question['question_text_$lang'],
      if (prompt is Map) prompt[lang],
      defaultText,
      question['question_text_en'],
      question['text'],
      if (prompt is Map) prompt['en'],
      prompt,
      question['question_text_hu'],
      if (prompt is Map) prompt['hu'],
    ]) {
      if (candidate is String && candidate.trim().isNotEmpty) return candidate;
    }
    return '';
  }

  /// Helper: Get localized content field (for deep JSON structures)
  String getLocalizedContentField(
    BuildContext context,
    Map<String, dynamic> question,
    String field, {
    String defaultVal = '',
  }) {
    final lang = Localizations.localeOf(context).languageCode;

    // 1. Check if 'content' JSON column exists and has the field
    if (question['content'] != null && question['content'] is Map) {
      final content = question['content'];
      if (content[field] != null) {
        final val = content[field];
        if (val is Map) {
          return val[lang]?.toString() ?? val['en']?.toString() ?? defaultVal;
        } else if (val is String) {
          return val;
        }
      }
    }
    return defaultVal;
  }

  // Practice choice IDs survive localization and shuffling. Older cached
  // questions still submit the label accepted by the server.
  String choiceValue(Map<String, dynamic> question, int index, String label) {
    final choices = question['choice_options'];
    return choices is List && index < choices.length
        ? choices[index]['id'] as String
        : label;
  }

  /// Helper: Get localized options
  List<String> getLocalizedOptions(
    BuildContext context,
    Map<String, dynamic> question,
  ) {
    final lang = Localizations.localeOf(context).languageCode;

    final choices = question['choice_options'];
    if (choices is List && choices.isNotEmpty) {
      return choices.map((c) => (c[lang] ?? c['en']).toString()).toList();
    }
    return _legacyOptions(question, lang)
        .where((label) => label.trim().isNotEmpty)
        .toList();
  }

  List<String> _legacyOptions(Map<String, dynamic> question, String lang) {
    dynamic decode(dynamic value) {
      if (value is! String) return value;
      try {
        return jsonDecode(value);
      } on FormatException {
        return null;
      }
    }

    final content = question['content'];
    for (final source in [
      question['options'],
      if (content is Map) content['options'],
      question['options_$lang'],
      question['options_en'],
      question['options_hu'],
    ]) {
      final options = decode(source);
      final rows = options is Map
          ? decode(options[lang] ?? options['en'] ?? options['hu'])
          : options;
      if (rows is! List || rows.isEmpty) continue;
      return rows.map((row) {
        final label = row is Map
            ? row[lang] ??
                row['en'] ??
                row['hu'] ??
                row['label'] ??
                row['text'] ??
                row['value']
            : row;
        return label?.toString() ?? '';
      }).toList();
    }
    return [];
  }

  String normalizeAnswerLabel(String value) => value.trim().toLowerCase();

  /// Shared validation logic for standard answer types with bilingual support
  bool commonValidateAnswer(
    dynamic userAnswer,
    dynamic correctAnswer, [
    Map<String, dynamic>? question,
    bool exactMatch = true,
  ]) {
    if (userAnswer == null || correctAnswer == null) return false;

    final choices = question?['choice_options'];
    List<String> labels(dynamic input) => (input is List ? input : [input])
        .map<String>((item) => normalizeAnswerLabel(item.toString()))
        .toList();

    dynamic stored = correctAnswer;
    if (stored is String && stored.trimLeft().startsWith('[')) {
      try {
        final parsed = jsonDecode(stored);
        if (parsed is List) stored = parsed;
      } on FormatException {
        // A historical option label can start with a literal bracket.
      }
    }
    final uList = labels(userAnswer);
    final cList = labels(stored);
    if (uList.isEmpty ||
        cList.isEmpty ||
        uList.contains('') ||
        cList.contains('')) {
      return false;
    }

    bool matches<T>(T? Function(String) resolve) {
      final actual = uList.map(resolve).toSet();
      final expected = cList.map(resolve).toSet();
      if (actual.contains(null) ||
          expected.contains(null) ||
          actual.length != uList.length ||
          expected.length != cList.length) {
        return false;
      }
      return expected.containsAll(actual) &&
          (!exactMatch || actual.length == expected.length);
    }

    if (choices is List && choices.isNotEmpty) {
      String? key(String value) {
        String? match;
        for (final choice in choices) {
          if (normalizeAnswerLabel(choice['id'].toString()) == value) {
            return choice['id'] as String;
          }
        }
        for (final choice in choices) {
          if (['en', 'hu'].any((field) =>
              choice[field] != null &&
              normalizeAnswerLabel(choice[field].toString()) == value)) {
            if (match != null) return null;
            match = choice['id'] as String;
          }
        }
        return match;
      }

      return matches<String>(key);
    }

    if (question != null) {
      final enOpts =
          _legacyOptions(question, 'en').map(normalizeAnswerLabel).toList();
      final huOpts =
          _legacyOptions(question, 'hu').map(normalizeAnswerLabel).toList();
      if (enOpts.isNotEmpty || huOpts.isNotEmpty) {
        int? indexOf(String value) {
          final matches = <int>{
            for (final labels in [enOpts, huOpts])
              for (var i = 0; i < labels.length; i++)
                if (labels[i] == value) i,
          };
          return matches.length == 1 ? matches.single : null;
        }

        return matches<int>(indexOf);
      }
    }
    return matches<String>((value) => value);
  }
}
