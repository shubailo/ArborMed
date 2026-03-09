import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/screens/admin/components/admin_csv_helper.dart';
import 'package:arbor_med/services/download/download_helper.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:arbor_med/models/question_stats.dart';

class MockDownloadHelper implements DownloadHelper {
  List<int>? lastBytes;
  String? lastFilename;
  String? lastMimeType;
  int callCount = 0;

  @override
  Future<void> download(
      List<int> bytes, String filename, String mimeType) async {
    callCount++;
    lastBytes = bytes;
    lastFilename = filename;
    lastMimeType = mimeType;
  }
}

void main() {
  late MockDownloadHelper mockDownloadHelper;
  late DownloadHelper originalDownloadHelper;

  setUp(() {
    originalDownloadHelper = downloadHelper;
    mockDownloadHelper = MockDownloadHelper();
    downloadHelper = mockDownloadHelper;
  });

  tearDown(() {
    downloadHelper = originalDownloadHelper;
  });

  group('AdminCsvHelper', () {
    group('downloadQuestions', () {
      test('does nothing when questions list is empty', () async {
        await AdminCsvHelper.downloadQuestions([]);
        expect(mockDownloadHelper.callCount, 0);
      });

      test('generates correct CSV and calls download when questions provided',
          () async {
        final questions = [
          AdminQuestion(
            id: 1,
            text: 'Test Question',
            questionTextHu: 'Teszt Kérdés',
            type: 'multiple_choice',
            bloomLevel: 2,
            options: [],
            correctAnswer: '',
            topicId: 1,
          ),
          AdminQuestion(
            id: 2,
            text: 'Second Q',
            questionTextHu: 'Második K',
            type: 'true_false',
            bloomLevel: 1,
            options: [],
            correctAnswer: '',
            topicId: 1,
          ),
        ];

        await AdminCsvHelper.downloadQuestions(questions);

        expect(mockDownloadHelper.callCount, 1);
        expect(mockDownloadHelper.lastFilename, 'arbor_med_questions.csv');
        expect(mockDownloadHelper.lastMimeType, 'text/csv;charset=utf-8');

        // Verify content
        final bytes = mockDownloadHelper.lastBytes!;
        expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]); // BOM

        final csvContent = utf8.decode(bytes.skip(3).toList());
        final lines = csvContent.split('\n');

        expect(lines[0], '"ID","Text (EN)","Text (HU)","Type","Bloom Level"');
        expect(lines[1],
            '"1","Test Question","Teszt Kérdés","multiple_choice","2"');
        expect(lines[2], '"2","Second Q","Második K","true_false","1"');
      });

      test('handles null fields gracefully', () async {
        final questions = [
          AdminQuestion(
            id: 3,
            text: null,
            questionTextHu: null,
            type: null,
            bloomLevel: 3,
            options: [],
            correctAnswer: '',
            topicId: 1,
          ),
        ];

        await AdminCsvHelper.downloadQuestions(questions);

        final bytes = mockDownloadHelper.lastBytes!;
        final csvContent = utf8.decode(bytes.skip(3).toList());
        final lines = csvContent.split('\n');

        expect(lines[1], '"3","","","","3"');
      });
    });

    group('downloadUserStats', () {
      test('does nothing when stats list is empty', () async {
        await AdminCsvHelper.downloadUserStats([]);
        expect(mockDownloadHelper.callCount, 0);
      });

      test('generates correct CSV and calls download when stats provided',
          () async {
        final stats = [
          QuestionStats(
            questionId: 'q1',
            questionText: 'Test text',
            topicSlug: 'topic1',
            bloomLevel: 1,
            totalAttempts: 10,
            correctCount: 8,
            avgTimeMs: 1500,
            correctPercentage: 80,
          ),
          QuestionStats(
            questionId: 'q2',
            questionText: 'Another test text',
            topicSlug: 'topic2',
            bloomLevel: 2,
            totalAttempts: 5,
            correctCount: 1,
            avgTimeMs: 2500,
            correctPercentage: 20,
          ),
        ];

        await AdminCsvHelper.downloadUserStats(stats);

        expect(mockDownloadHelper.callCount, 1);
        expect(
            mockDownloadHelper.lastFilename, 'arbor_med_user_performance.csv');
        expect(mockDownloadHelper.lastMimeType, 'text/csv;charset=utf-8');

        // Verify content
        final bytes = mockDownloadHelper.lastBytes!;
        expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]); // BOM

        final csvContent = utf8.decode(bytes.skip(3).toList());
        final lines = csvContent.split('\n');

        expect(lines[0],
            '"Question ID","Text","Attempts","Correct %","Avg Time (ms)"');
        expect(lines[1], '"q1","Test text","10","80","1500"');
        expect(lines[2], '"q2","Another test text","5","20","2500"');
      });
    });
  });
}
