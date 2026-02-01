import 'package:flutter/material.dart';
import 'question_renderer.dart';

/// Renderer for Matching (Connect Two) questions
/// Implements a Duolingo-style tap-to-connect interface
class MatchingRenderer extends QuestionRenderer {
  @override
  Widget buildQuestion(BuildContext context, Map<String, dynamic> question) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 10),
      child: Text(
        'Párosítsd a kifejezéseket!',
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        textAlign: TextAlign.center,
      ),
    );
  }

  @override
  Widget buildAnswerInput(
    BuildContext context,
    Map<String, dynamic> question,
    dynamic currentAnswer,
    Function(dynamic) onAnswerChanged,
  ) {
    return MatchingInputWidget(
      question: question,
      currentAnswer: currentAnswer,
      onAnswerChanged: onAnswerChanged,
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

  const MatchingInputWidget({
    super.key,
    required this.question,
    required this.currentAnswer,
    required this.onAnswerChanged,
  });

  @override
  _MatchingInputWidgetState createState() => _MatchingInputWidgetState();
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

    final leftItems = List<String>.from(matchingData['left']);
    final rightItems = List<String>.from(matchingData['right']);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left Column
        Expanded(
          child: Column(
            children: leftItems.map((item) => _buildItem(
              item: item,
              isSelected: selectedLeft == item,
              isPaired: pairs.containsKey(item),
              onTap: () => _handleLeftTap(item),
              color: Colors.blue[50]!,
              activeColor: Colors.blue[600]!,
            )).toList(),
          ),
        ),
        const SizedBox(width: 12),
        // Right Column
        Expanded(
          child: Column(
            children: rightItems.map((item) {
              bool isPaired = false;
              pairs.forEach((k, v) {
                if (v == item) isPaired = true;
              });

              return _buildItem(
                item: item,
                isSelected: selectedRight == item,
                isPaired: isPaired,
                onTap: () => _handleRightTap(item),
                color: Colors.green[50]!,
                activeColor: Colors.green[600]!,
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildItem({
    required String item,
    required bool isSelected,
    required bool isPaired,
    required VoidCallback onTap,
    required Color color,
    required Color activeColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isPaired ? activeColor.withOpacity(0.1) : (isSelected ? activeColor : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected || isPaired ? activeColor : Colors.grey[300]!,
              width: 2,
            ),
          ),
          child: Text(
            item,
            style: TextStyle(
              fontSize: 15,
              fontWeight: isSelected || isPaired ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? Colors.white : (isPaired ? activeColor : Colors.black87),
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
