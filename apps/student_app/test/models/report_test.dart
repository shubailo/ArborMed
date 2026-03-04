import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/report.dart';

void main() {
  group('Report.fromJson', () {
    test('parses full valid JSON correctly', () {
      final json = {
        'id': 1,
        'question_id': 100,
        'user_id': 50,
        'reason_category': 'inaccurate',
        'description': 'The correct answer is actually B.',
        'status': 'reviewed',
        'admin_notes': 'Fixed the typo in option B.',
        'created_at': '2023-11-01T10:00:00Z',
        'reporter_email': 'student@example.com',
      };

      final report = Report.fromJson(json);

      expect(report.id, 1);
      expect(report.questionId, 100);
      expect(report.userId, 50);
      expect(report.reasonCategory, 'inaccurate');
      expect(report.description, 'The correct answer is actually B.');
      expect(report.status, 'reviewed');
      expect(report.adminNotes, 'Fixed the typo in option B.');
      expect(report.createdAt, DateTime.parse('2023-11-01T10:00:00Z'));
      expect(report.reporterEmail, 'student@example.com');
    });

    test('applies defaults when optional fields are missing', () {
      final json = {
        'id': 2,
        'question_id': 101,
        'user_id': 51,
        'created_at': '2023-11-01T11:00:00Z',
      };

      final report = Report.fromJson(json);

      expect(report.id, 2);
      expect(report.questionId, 101);
      expect(report.userId, 51);
      expect(report.reasonCategory, 'other');
      expect(report.description, '');
      expect(report.status, 'pending');
      expect(report.adminNotes, isNull);
      expect(report.createdAt, DateTime.parse('2023-11-01T11:00:00Z'));
      expect(report.reporterEmail, isNull);
    });

    test('defaults createdAt to current time when missing or null', () {
      final json = {
        'id': 3,
        'question_id': 102,
        'user_id': 52,
      };

      final before = DateTime.now();
      final report = Report.fromJson(json);
      final after = DateTime.now();

      expect(report.id, 3);
      // createdAt should be between `before` and `after`
      expect(report.createdAt.isAfter(before.subtract(const Duration(milliseconds: 1))), isTrue);
      expect(report.createdAt.isBefore(after.add(const Duration(milliseconds: 1))), isTrue);
    });

    test('handles null values for optional fields', () {
      final json = {
        'id': 4,
        'question_id': 103,
        'user_id': 53,
        'reason_category': null,
        'description': null,
        'status': null,
        'admin_notes': null,
        'reporter_email': null,
      };

      final report = Report.fromJson(json);

      expect(report.reasonCategory, 'other');
      expect(report.description, '');
      expect(report.status, 'pending');
      expect(report.adminNotes, isNull);
      expect(report.reporterEmail, isNull);
    });

    test('throws error when required fields are missing', () {
      // Missing id
      expect(
        () => Report.fromJson({
          'question_id': 104,
          'user_id': 54,
        }),
        throwsA(isA<TypeError>()),
      );

      // Missing question_id
      expect(
        () => Report.fromJson({
          'id': 5,
          'user_id': 55,
        }),
        throwsA(isA<TypeError>()),
      );

      // Missing user_id
      expect(
        () => Report.fromJson({
          'id': 6,
          'question_id': 106,
        }),
        throwsA(isA<TypeError>()),
      );
    });

    test('throws FormatException on invalid date format', () {
      final json = {
        'id': 7,
        'question_id': 107,
        'user_id': 57,
        'created_at': 'not-a-valid-date',
      };

      expect(
        () => Report.fromJson(json),
        throwsFormatException,
      );
    });
  });
}
