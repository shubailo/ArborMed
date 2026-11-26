import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/audio_provider.dart';
import 'package:arbor_med/generated/l10n/app_localizations.dart';
import 'package:arbor_med/theme/cozy_theme.dart';
import 'question_renderer.dart';

Object? _decode(Object? raw) {
  if (raw is! String) return raw;
  try {
    return jsonDecode(raw);
  } on FormatException {
    return null;
  }
}

Map<String, String>? _answerMap(Object? raw) {
  final value = _decode(raw);
  if (value is! Map) return null;
  final pairs = <String, String>{};
  for (final entry in value.entries) {
    final key = entry.key, answer = entry.value;
    if (key is! String ||
        key.trim().isEmpty ||
        answer is! String ||
        answer.trim().isEmpty) {
      return null;
    }
    pairs[key] = answer;
  }
  return pairs;
}

// Keys are the stored English labels. Translation and display order are independent on each side.
class _MatchingBoard {
  final Map<String, String> left;
  final Map<String, String> right;
  const _MatchingBoard(this.left, this.right);

  static _MatchingBoard? read(Object? raw) {
    final data = _decode(raw);
    if (data is! Map) return null;
    final left = _side(data['left']), right = _side(data['right']);
    if (left == null || right == null || left.length != right.length) {
      return null;
    }
    return _MatchingBoard(left, right);
  }

  static Map<String, String>? _side(Object? items) {
    if (items is! List || items.length < 2) return null;
    final result = <String, String>{};
    final enLabels = <String>{}, huLabels = <String>{};
    for (final item in items) {
      final key = item is Map ? item['en'] : item;
      if (key is! String ||
          key.trim().isEmpty ||
          !enLabels.add(key.trim().toLowerCase())) {
        return null;
      }
      final translation = item is Map ? item['hu'] : null;
      final label = translation is String && translation.trim().isNotEmpty
          ? translation
          : key;
      if (!huLabels.add(label.trim().toLowerCase())) return null;
      result[key] = label;
    }
    return result;
  }

  bool complete(Map<String, String> pairs) =>
      pairs.length == left.length &&
      pairs.keys.every(left.containsKey) &&
      pairs.values.toSet().length == right.length &&
      pairs.values.every(right.containsKey);
}

class MatchingRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    final text = getLocalizedText(context, question);
    return Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Text(
            text.isEmpty ? AppLocalizations.of(context)!.quizMatchPairs : text,
            style: GoogleFonts.outfit(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: CozyTheme.of(context).textPrimary),
            textAlign: TextAlign.center));
  }

  @override
  Widget buildAnswerInput(BuildContext context, Map<String, dynamic> question,
          dynamic currentAnswer, Function(dynamic) onAnswerChanged,
          {bool isChecked = false, dynamic correctAnswer}) =>
      MatchingInputWidget(
          key: ValueKey(question['id']),
          question: question,
          currentAnswer: currentAnswer,
          onAnswerChanged: onAnswerChanged,
          isChecked: isChecked,
          correctAnswer: correctAnswer);

  @override
  bool hasAnswer(dynamic answer) => _answerMap(answer)?.isNotEmpty == true;

  @override
  bool canSubmit(Map<String, dynamic> question, dynamic answer) {
    final pairs = _answerMap(answer);
    return pairs != null &&
        _MatchingBoard.read(question['matching_data'])?.complete(pairs) == true;
  }

  @override
  dynamic formatAnswer(dynamic answer) => _answerMap(answer);

  @override
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer,
      Map<String, dynamic> question) {
    final actual = _answerMap(userAnswer), expected = _answerMap(correctAnswer);
    if (actual == null ||
        expected == null ||
        actual.length != expected.length ||
        _MatchingBoard.read(question['matching_data'])?.complete(expected) !=
            true) {
      return false;
    }
    return expected.entries
        .every((entry) => actual[entry.key]?.trim() == entry.value.trim());
  }

  @override
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
          int index, dynamic currentAnswer) =>
      currentAnswer;
}

class MatchingInputWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final dynamic currentAnswer;
  final ValueChanged<dynamic> onAnswerChanged;
  final bool isChecked;
  final dynamic correctAnswer;
  const MatchingInputWidget(
      {super.key,
      required this.question,
      required this.currentAnswer,
      required this.onAnswerChanged,
      this.isChecked = false,
      this.correctAnswer});
  @override
  State<MatchingInputWidget> createState() => _MatchingInputWidgetState();
}

class _MatchingInputWidgetState extends State<MatchingInputWidget> {
  Map<String, String> _pairs = const {};
  Map<String, String> _rightToLeft = const {};
  String? _pending;
  bool _pendingLeft = false;
  _MatchingBoard? _board;

  @override
  void initState() {
    super.initState();
    _board = _MatchingBoard.read(widget.question['matching_data']);
    _replacePairs(_answerMap(widget.currentAnswer) ?? {});
  }

  void _replacePairs(Map<String, String> pairs) {
    final leftToRight = <String, String>{};
    final rightToLeft = <String, String>{};
    final board = _board;
    if (board != null) {
      for (final entry in pairs.entries) {
        if (board.left.containsKey(entry.key) &&
            board.right.containsKey(entry.value) &&
            !rightToLeft.containsKey(entry.value)) {
          leftToRight[entry.key] = entry.value;
          rightToLeft[entry.value] = entry.key;
        }
      }
    }
    _pairs = Map.unmodifiable(leftToRight);
    _rightToLeft = rightToLeft;
  }

  @override
  void didUpdateWidget(MatchingInputWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    final newQuestion = widget.question['id'] != oldWidget.question['id'];
    final newBoard = newQuestion ||
        oldWidget.question['matching_data'] != widget.question['matching_data'];
    if (newBoard) {
      _board = _MatchingBoard.read(widget.question['matching_data']);
      _replacePairs(_pairs);
      final side = _pendingLeft ? _board?.left : _board?.right;
      if (side?.containsKey(_pending) != true) _pending = null;
    }
    if (newQuestion || oldWidget.currentAnswer != widget.currentAnswer) {
      final incoming = _answerMap(widget.currentAnswer) ?? {};
      if (newQuestion || !mapEquals(incoming, _pairs)) {
        _replacePairs(incoming);
        _pending = null;
      }
    }
    if (widget.isChecked) _pending = null;
  }

  void _tap(bool left, String key) {
    if (widget.isChecked) return;
    final linked =
        left ? (_pairs.containsKey(key) ? key : null) : _rightToLeft[key];
    if (linked != null) {
      _publish({..._pairs}..remove(linked));
    } else if (_pending == null || _pendingLeft == left) {
      setState(() {
        _pending = (_pendingLeft == left && _pending == key) ? null : key;
        _pendingLeft = left;
      });
    } else {
      final leftKey = left ? key : _pending!;
      final rightKey = left ? _pending! : key;
      _publish({..._pairs, leftKey: rightKey});
    }
  }

  void _publish(Map<String, String> pairs) {
    setState(() {
      _replacePairs(pairs);
      _pending = null;
    });
    widget.onAnswerChanged(_pairs);
  }

  @override
  Widget build(BuildContext context) {
    final board = _board;
    if (board == null) {
      return Center(child: Text(AppLocalizations.of(context)!.quizNoOptions));
    }
    final hu = Localizations.localeOf(context).languageCode == 'hu';
    final palette = CozyTheme.of(context);
    final expected = widget.isChecked ? _answerMap(widget.correctAnswer) : null;
    String rightLabel(String key) => hu ? board.right[key] ?? key : key;
    Widget column(bool left) {
      final items = left ? board.left : board.right;
      return Expanded(
          child: Column(children: [
        for (final entry in items.entries)
          _buildItem(
              context: context,
              label: hu ? entry.value : entry.key,
              isSelected: _pendingLeft == left && _pending == entry.key,
              isPaired: left
                  ? _pairs.containsKey(entry.key)
                  : _rightToLeft.containsKey(entry.key),
              partner: left && _pairs[entry.key] != null
                  ? rightLabel(_pairs[entry.key]!)
                  : null,
              correction: left &&
                      expected?[entry.key] != null &&
                      expected![entry.key] != _pairs[entry.key]
                  ? rightLabel(expected[entry.key]!)
                  : null,
              onTap: widget.isChecked ? null : () => _tap(left, entry.key),
              activeColor: left ? palette.primary : palette.secondary),
      ]));
    }

    return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [column(true), const SizedBox(width: 12), column(false)]);
  }

  Widget _buildItem({
    required BuildContext context,
    required String label,
    required bool isSelected,
    required bool isPaired,
    VoidCallback? onTap,
    String? partner,
    String? correction,
    required Color activeColor,
  }) {
    final palette = CozyTheme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap == null
              ? null
              : () {
                  Provider.of<AudioProvider>(context, listen: false)
                      .playSfx('click');
                  onTap();
                },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedScale(
            scale: isSelected ? 1.05 : 1.0,
            duration: const Duration(milliseconds: 400),
            curve: Curves.elasticOut,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutCubic,
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              decoration: BoxDecoration(
                color: isSelected
                    ? activeColor
                    : (isPaired
                        ? activeColor.withValues(alpha: 0.1)
                        : palette.paperCream),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected || isPaired
                      ? activeColor
                      : palette.textPrimary.withValues(alpha: 0.1),
                  width: isSelected || isPaired ? 2.5 : 1.5,
                ),
                boxShadow: isSelected || isPaired
                    ? [
                        BoxShadow(
                            color: activeColor.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 5))
                      ]
                    : [
                        BoxShadow(
                            color: palette.textPrimary.withValues(alpha: 0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2))
                      ],
              ),
              child: Column(children: [
                Text(label,
                    style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: isSelected || isPaired
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isSelected
                            ? palette.textInverse
                            : palette.textPrimary),
                    textAlign: TextAlign.center),
                if (partner != null)
                  Text(AppLocalizations.of(context)!.quizPairedWith(partner),
                      textAlign: TextAlign.center),
                if (correction != null)
                  Text(
                      '${AppLocalizations.of(context)!.correctAnswer}: $correction',
                      style: TextStyle(color: palette.error),
                      textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      ),
    );
  }
}
