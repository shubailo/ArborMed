import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:convert';
import '../../services/locale_provider.dart';

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
    Function(dynamic) onAnswerChanged,
  );

  /// Validate if the user has provided an answer
  bool hasAnswer(dynamic answer);

  /// Get the user's answer in the format expected by the backend
  dynamic formatAnswer(dynamic answer);

  /// Helper: Get localized text from question map
  String getLocalizedText(BuildContext context, Map<String, dynamic> question, {String? defaultText}) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final lang = locale.languageCode;
    
    // 1. Try specific column (question_text_en, question_text_hu)
    if (question['question_text_$lang'] != null && question['question_text_$lang'].toString().isNotEmpty) {
      return question['question_text_$lang'].toString();
    }
    
    // 2. Fallback to default/content
    // Note: 'text' column usually holds English or legacy text
    return defaultText ?? question['text']?.toString() ?? '';
  }

  /// Helper: Get localized options
  List<String> getLocalizedOptions(BuildContext context, Map<String, dynamic> question) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final lang = locale.languageCode;
    
    dynamic optionsData = question['options'];
    
    // Parse if string
    if (optionsData is String) {
      try {
        optionsData = json.decode(optionsData);
      } catch (e) {
        // Fallback: it might be a single string (weird but possible legacy)
        return []; 
      }
    }
    
    // Handle Map (Dual Language)
    if (optionsData is Map) {
      if (optionsData.containsKey(lang)) {
        return List<String>.from(optionsData[lang]);
      } else if (optionsData.containsKey('en')) {
         return List<String>.from(optionsData['en']);
      }
      // If pure map but no known key?
      return [];
    }
    
    // Handle List (Legacy / Single Language)
    if (optionsData is List) {
      return List<String>.from(optionsData);
    }
    
    // Fallback: Check content options (Legacy)
    final content = question['content'] as Map<String, dynamic>?;
    if (content != null && content['options'] != null) {
       return List<String>.from(content['options'] as List);
    }

    return [];
  }
}
