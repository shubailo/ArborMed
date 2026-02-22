import 'dart:convert';
import '../../../services/download/download_helper.dart';
import '../../../services/stats_provider.dart';

class AdminCsvHelper {
  static Future<void> downloadQuestions(List<AdminQuestion> questions) async {
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

    await _download(csvData, 'arbor_med_questions.csv');
  }

  static Future<void> downloadUserStats(List<QuestionStats> stats) async {
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

    await _download(csvData, 'arbor_med_user_performance.csv');
  }

  static Future<void> _download(List<List<dynamic>> rows, String filename) async {
    String csv =
        rows.map((row) => row.map((field) => '"$field"').join(',')).join('\n');
    
    // Use the download helper which handles web/native internally
    // Add BOM for Excel compatibility with UTF-8
    final bytes = [0xEF, 0xBB, 0xBF, ...utf8.encode(csv)];
    await downloadHelper.download(bytes, filename, 'text/csv;charset=utf-8');
  }
}
