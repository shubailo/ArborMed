import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:universal_html/html.dart' as html;
import '../../../services/stats_provider.dart';

class AdminCsvHelper {
  static void downloadQuestions(List<AdminQuestion> questions) {
    if (questions.isEmpty) return;

    final csvData = [
      ['ID', 'Text (EN)', 'Text (HU)', 'Type', 'Bloom Level'],
      ...questions.map((q) => [
            q.id,
            q.text ?? '',
            q.questionTextHu ?? '',
            q.type ?? '',
            q.bloomLevel,
          ]),
    ];

    _download(csvData, 'arbor_med_questions.csv');
  }

  static void downloadUserStats(List<QuestionStats> stats) {
    if (stats.isEmpty) return;

    final csvData = [
      ['Question ID', 'Text', 'Attempts', 'Correct %', 'Avg Time (ms)'],
      ...stats.map((s) => [
            s.questionId,
            s.questionText,
            s.totalAttempts,
            s.correctPercentage,
            s.avgTimeMs,
          ]),
    ];

    _download(csvData, 'arbor_med_user_performance.csv');
  }

  static void _download(List<List<dynamic>> rows, String filename) {
    String csv = rows.map((row) => row.map((field) => '"$field"').join(',')).join('\n');
    
    if (kIsWeb) {
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes]);
      final url = html.Url.createObjectUrlFromBlob(blob);
      html.AnchorElement(href: url)
        ..setAttribute("download", filename)
        ..click();
      html.Url.revokeObjectUrl(url);
    } else {
      // Mobile support would require path_provider and dart:io
      // For now, we focus on Web for Admin usage as per general patterns
      debugPrint("CSV Download handled: $csv");
    }
  }
}
