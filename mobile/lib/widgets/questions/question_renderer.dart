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

  /// Helper: Show full-screen zoomed image
  void showZoomedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: Colors.black.withOpacity(0.9),
        body: Stack(
          children: [
            Center(
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
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

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

  /// Helper: Get localized content field (for deep JSON structures)
  String getLocalizedContentField(BuildContext context, Map<String, dynamic> question, String field, {String defaultVal = ''}) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final lang = locale.languageCode;
    
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
    
    List<String> result = [];
    
    // Handle Map (Dual Language)
    if (optionsData is Map) {
      if (optionsData.containsKey(lang)) {
        result = List<String>.from(optionsData[lang]);
      } else if (optionsData.containsKey('en')) {
         result = List<String>.from(optionsData['en']);
      }
    }
    
    // Handle List (Legacy / Single Language)
    else if (optionsData is List) {
      result = List<String>.from(optionsData);
    }
    
    // 3. Fallback: Check content options (Legacy)
    else {
      final content = question['content'] as Map<String, dynamic>?;
      if (content != null && content['options'] != null) {
         result = List<String>.from(content['options'] as List);
      }
    }

    // 4. Fallback: Check localized columns (options_en, options_hu)
    if (result.isEmpty) {
      final colData = question['options_$lang'] ?? question['options_en'];
      if (colData != null) {
        if (colData is List) {
          result = List<String>.from(colData);
        } else if (colData is String) {
          try {
            final decoded = json.decode(colData);
            if (decoded is List) result = List<String>.from(decoded);
          } catch (_) {}
        }
      }
    }

    // 🔥 Filter empty options
    return result.where((opt) => opt.trim().isNotEmpty).toList();
  }
}
