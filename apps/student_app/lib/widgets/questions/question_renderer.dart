import 'package:flutter/material.dart';
import '../../theme/cozy_theme.dart';
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
    Function(dynamic) onAnswerChanged, {
    bool isChecked = false,
    dynamic correctAnswer,
  });

  /// Validate if the user has provided an answer
  bool hasAnswer(dynamic answer);

  /// Get the user's answer in the format expected by the backend
  dynamic formatAnswer(dynamic answer);

  /// Locally validate if the answer is correct
  bool validateAnswer(dynamic userAnswer, dynamic correctAnswer, Map<String, dynamic> question);

  /// Get the answer result for a given index (0-based)
  /// Used for keyboard shortcuts (1, 2, 3...)
  dynamic getAnswerForIndex(BuildContext context, Map<String, dynamic> question,
      int index, dynamic currentAnswer);

  /// Helper: Show full-screen zoomed image
  void showZoomedImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Scaffold(
        backgroundColor: CozyTheme.of(context, listen: false)
            .textPrimary
            .withValues(alpha: 0.9),
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
                icon: Icon(Icons.close,
                    color: CozyTheme.of(context, listen: false).textInverse,
                    size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Helper: Get localized text from question map
  String getLocalizedText(BuildContext context, Map<String, dynamic> question,
      {String? defaultText}) {
    final locale = Provider.of<LocaleProvider>(context, listen: false).locale;
    final lang = locale.languageCode;

    // 1. Try specific column (question_text_en, question_text_hu)
    if (question['question_text_$lang'] != null &&
        question['question_text_$lang'].toString().isNotEmpty) {
      return question['question_text_$lang'].toString();
    }

    // 2. Fallback to default/content
    // Note: 'text' column usually holds English or legacy text
    return defaultText ?? question['text']?.toString() ?? '';
  }

  /// Helper: Get localized content field (for deep JSON structures)
  String getLocalizedContentField(
      BuildContext context, Map<String, dynamic> question, String field,
      {String defaultVal = ''}) {
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
  List<String> getLocalizedOptions(
      BuildContext context, Map<String, dynamic> question) {
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

    String extract(dynamic e) {
      if (e == null) return '';
      if (e is String) return e;
      if (e is Map) {
        return e[lang]?.toString() ??
            e['en']?.toString() ??
            e['label']?.toString() ??
            e['text']?.toString() ??
            e.toString();
      }
      return e.toString();
    }

    List<String> result = [];

    // Handle Map (Dual Language)
    if (optionsData is Map) {
      if (optionsData.containsKey(lang)) {
        final data = optionsData[lang];
        if (data is List) {
          result = data.map((e) => extract(e)).toList();
        }
      } else if (optionsData.containsKey('en')) {
        final data = optionsData['en'];
        if (data is List) {
          result = data.map((e) => extract(e)).toList();
        }
      }
    }

    // Handle List (Legacy / Single Language)
    else if (optionsData is List) {
      result = optionsData.map((e) => extract(e)).toList();
    }

    // 3. Fallback: Check content options (Legacy)
    else {
      final content = question['content'] as Map<String, dynamic>?;
      if (content != null && content['options'] != null && content['options'] is List) {
        result = (content['options'] as List).map((e) => extract(e)).toList();
      }
    }

    // 4. Fallback: Check localized columns (options_en, options_hu)
    if (result.isEmpty) {
      final colData = question['options_$lang'] ?? question['options_en'];
      if (colData != null) {
        if (colData is List) {
          result = colData.map((e) => extract(e)).toList();
        } else if (colData is String) {
          try {
            final decoded = json.decode(colData);
            if (decoded is List) {
              result = decoded.map((e) => extract(e)).toList();
            }
          } catch (_) {}
        }
      }
    }

    // 🔥 Filter empty options
    return result.where((opt) => opt.trim().isNotEmpty).toList();
  }

  /// Shared validation logic for standard answer types with bilingual support
  bool commonValidateAnswer(dynamic userAnswer, dynamic correctAnswer, [Map<String, dynamic>? question, bool exactMatch = true]) {
    if (userAnswer == null || correctAnswer == null) return false;

    // Helper to normalize strings for comparison
    String normalize(String s) {
      final trimmed = s.trim().toLowerCase();
      // Handle bilingual boolean labels
      if (trimmed == 'igaz') return 'true';
      if (trimmed == 'hamis') return 'false';
      return trimmed;
    }

    // 1. Try Direct Comparison (Fast Path)
    final uStr = normalize(userAnswer.toString());
    final cStr = normalize(correctAnswer.toString());
    
    // Check for List/JSON structure in Correct Answer
    List<String> cList = [];
    if (correctAnswer is List) {
      cList = correctAnswer.map((e) => normalize(e.toString())).toList();
    } else {
       if (cStr.startsWith('[') && cStr.endsWith(']')) {
        try {
          final List<dynamic> list = json.decode(cStr);
          cList = list.map((e) => normalize(e.toString())).toList();
        } catch (_) {
          cList = [cStr];
        }
      } else {
        cList = [cStr];
      }
    }

    // Check for List in User Answer (Multi-Select)
    List<String> uList = [];
    if (userAnswer is List) {
      uList = userAnswer.map((e) => normalize(e.toString())).toList();
    } else {
      uList = [uStr];
    }
    
    // Direct Match Attempt
    bool directMatch = false;
    if (uList.length == cList.length) {
       directMatch = uList.every((u) => cList.contains(u));
    } else if (!exactMatch && cList.isNotEmpty && uList.length == 1) {
       // Highlighting check: Is this single user answer ONE OF the correct answers?
       directMatch = cList.contains(uList.first);
    }

    if (directMatch) return true;

    // 2. Bilingual Index-Based Comparison (Slow Path)
    if (question != null) {
      // Let's try to find indices for User Answers
      Set<int> userIndices = {};
      
      // We need strict lists of EN and HU to map indices
      List<String> enOpts = [];
      List<String> huOpts = [];
      
      void parseOpts(dynamic source, List<String> target) {
         if (source == null) return;
         dynamic data = source;
         if (data is String) {
             try { data = json.decode(data); } catch (_) { return; }
         }
         if (data is List) {
             target.addAll(data.map((e) => normalize(e.toString())));
         }
      }
      
      // Extract from 'options' map
      if (question['options'] is Map) {
          parseOpts(question['options']['en'], enOpts);
          parseOpts(question['options']['hu'], huOpts);
      }
      
      // Extract from columns if empty
      if (enOpts.isEmpty && question['options_en'] != null) {
          parseOpts(question['options_en'], enOpts);
      }
      if (huOpts.isEmpty && question['options_hu'] != null) {
          parseOpts(question['options_hu'], huOpts);
      }
      
      // Fallback: if we only have one list in 'options' (legacy)
      if (enOpts.isEmpty && huOpts.isEmpty && question['options'] is List) {
          parseOpts(question['options'], enOpts); 
      }

      int getIndex(String val) {
          int idx = enOpts.indexOf(val);
          if (idx == -1) idx = huOpts.indexOf(val);
          return idx;
      }

      for (var u in uList) {
          int idx = getIndex(u);
          if (idx != -1) userIndices.add(idx);
      }
      
      Set<int> correctIndices = {};
      for (var c in cList) {
          int idx = getIndex(c);
          if (idx != -1) correctIndices.add(idx);
      }
      
      if (correctIndices.isNotEmpty && userIndices.isNotEmpty) {
           if (exactMatch) {
               return correctIndices.length == userIndices.length && 
                      correctIndices.every((i) => userIndices.contains(i));
           } else {
               // For highlighting, check if single answer index is in correct indices
               if (userIndices.length == 1) {
                   return correctIndices.contains(userIndices.first);
               }
               return userIndices.every((i) => correctIndices.contains(i));
           }
      }
    }

    return false;
  }
}
