import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'question_renderer.dart';
import '../../theme/cozy_theme.dart';
import '../../services/locale_provider.dart';

/// Renderer for Matching (Connect Two) questions
/// Implements a Duolingo-style tap-to-connect interface
class MatchingRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Párosítsd a kifejezéseket!',
        style: GoogleFonts.outfit(
          fontSize: 18, 
          fontWeight: FontWeight.w600,
          color: CozyTheme.textPrimary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged, {
    bool isChecked = false,
    dynamic correctAnswer,
  }) {
    return MatchingInputWidget(
      question: question,
      currentAnswer: currentAnswer,
      onAnswerChanged: onAnswerChanged,
      isChecked: isChecked,
      correctAnswer: correctAnswer,
    );
  }

  @override
  bool hasAnswer(dynamic answer) {
    if (answer == null) return false;
    // For matching, the answer is usually a Map of pairs
    if (answer is Map) {
      return answer.isNotEmpty;
    }
    return false;
  }

  @override
  dynamic formatAnswer(dynamic answer) {
    return answer;
  }
}

class MatchingInputWidget extends StatefulWidget {
  final Map<String, dynamic> question;
  final dynamic currentAnswer;
  final Function(dynamic) onAnswerChanged;

  final bool isChecked;
  final dynamic correctAnswer;

  const MatchingInputWidget({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
    this.isChecked = false,
    this.correctAnswer,
  });

  @override
  createState() => _MatchingInputWidgetState();
}

class _MatchingInputWidgetState extends State<MatchingInputWidget> {
  String? selectedLeft;
  String? selectedRight;
  
  // Local state to track paired items
  // Format: { leftValue: rightValue }
  Map<String, String> pairs = {};

  @override
  void initState() {
    super.initState();
    if (widget.currentAnswer != null && widget.currentAnswer is Map) {
      pairs = Map<String, String>.from(widget.currentAnswer);
    }
  }

  void _handleLeftTap(String item) {
    if (pairs.containsKey(item)) {
      // Remove connection if already paired
      setState(() {
        pairs.remove(item);
        widget.onAnswerChanged(pairs);
      });
      return;
    }

    setState(() {
      if (selectedLeft == item) {
        selectedLeft = null;
      } else {
        selectedLeft = item;
        _checkMatch();
      }
    });
  }

  void _handleRightTap(String item) {
    // Check if right item is already paired
    String? existingLeft;
    pairs.forEach((left, right) {
      if (right == item) existingLeft = left;
    });

    if (existingLeft != null) {
      // Remove connection if already paired
      setState(() {
        pairs.remove(existingLeft);
        widget.onAnswerChanged(pairs);
      });
      return;
    }

    setState(() {
      if (selectedRight == item) {
        selectedRight = null;
      } else {
        selectedRight = item;
        _checkMatch();
      }
    });
  }

  void _checkMatch() {
    if (selectedLeft != null && selectedRight != null) {
      setState(() {
        pairs[selectedLeft!] = selectedRight!;
        selectedLeft = null;
        selectedRight = null;
        widget.onAnswerChanged(pairs);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final matchingData = widget.question['matching_data'] as Map<String, dynamic>?;
    if (matchingData == null) return const Text('Error: No matching data');

    final locale = Provider.of<LocaleProvider>(context, listen: false).locale.languageCode;
    
    // Helper to get localized string from item (which is now a Map {en: ..., hu: ...})
    String getLabel(dynamic item) {
      if (item is Map) {
        return item[locale]?.toString() ?? item['en']?.toString() ?? '';
      }
      return item.toString();
    }
    
    // Use the localized text for the internal logic, or better, the English text as a stable key
    String getKey(dynamic item) {
      if (item is Map) return item['en']?.toString() ?? item.toString();
      return item.toString();
    }

    final leftItems = List<dynamic>.from(matchingData['left']);
    final rightItems = List<dynamic>.from(matchingData['right']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            children: leftItems.map((item) {
              final key = getKey(item);
              final label = getLabel(item);
              return _buildItem(
                label: label,
                isSelected: selectedLeft == key,
                isPaired: pairs.containsKey(key),
                onTap: widget.isChecked ? null : () => _handleLeftTap(key),
                color: CozyTheme.paperCream,
                activeColor: CozyTheme.primary,
              );
            }).toList(),
          ),
        ),
        const SizedBox(width: 12),
        // Right Column
        Expanded(
          child: Column(
            children: rightItems.map((item) {
              final key = getKey(item);
              final label = getLabel(item);
              bool isPaired = false;
              pairs.forEach((k, v) {
                if (v == key) isPaired = true;
              });

              return _buildItem(
                label: label,
                isSelected: selectedRight == key,
                isPaired: isPaired,
                onTap: widget.isChecked ? null : () => _handleRightTap(key),
                color: CozyTheme.paperCream,
                activeColor: CozyTheme.accent,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String label,
    required bool isSelected,
    required bool isPaired,
    VoidCallback? onTap,
    required Color color,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              color: isSelected ? activeColor : (isPaired ? activeColor.withValues(alpha: 0.1) : CozyTheme.paperCream),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isSelected || isPaired ? activeColor : CozyTheme.textPrimary.withValues(alpha: 0.1),
                width: 1.5,
              ),
              boxShadow: isSelected || isPaired ? [
                BoxShadow(color: activeColor.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4))
              ] : [
                BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 4, offset: const Offset(0, 2))
              ],
            ),
            child: Text(
              label,
              style: GoogleFonts.outfit(
                fontSize: 15,
                fontWeight: isSelected || isPaired ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? Colors.white : (isPaired ? activeColor : CozyTheme.textPrimary),
              ),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ),
      ),
    );
  }
}
