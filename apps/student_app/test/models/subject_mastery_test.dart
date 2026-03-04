import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/subject_mastery.dart';

void main() {
  group('SubjectMastery.fromJson', () {
    test('parses valid JSON with integer values correctly', () {
      final json = {
        'name_en': 'Anatomy',
        'name_hu': 'Anatómia',
        'slug': 'anatomy',
        'total_answered': 100,
        'correct_answered': 80,
        'mastery_percent': 80,
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.subjectEn, 'Anatomy');
      expect(mastery.subjectHu, 'Anatómia');
      expect(mastery.slug, 'anatomy');
      expect(mastery.totalAnswered, 100);
      expect(mastery.correctAnswered, 80);
      expect(mastery.masteryPercent, 80);
    });

    test('parses numeric fields from strings correctly', () {
      final json = {
        'name_en': 'Physiology',
        'slug': 'physiology',
        'total_answered': '50',
        'correct_answered': '25',
        'mastery_percent': '50',
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.totalAnswered, 50);
      expect(mastery.correctAnswered, 25);
      expect(mastery.masteryPercent, 50);
    });

    test('uses "subject" key if "name_en" is missing', () {
      final json = {
        'subject': 'Biochemistry',
        'slug': 'biochem',
        'total_answered': 10,
        'correct_answered': 10,
        'mastery_percent': 100,
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.subjectEn, 'Biochemistry');
    });

    test('defaults "subjectEn" to "Unknown" if both keys are missing', () {
      final json = {
        'slug': 'unknown-subject',
        'total_answered': 0,
        'correct_answered': 0,
        'mastery_percent': 0,
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.subjectEn, 'Unknown');
    });

    test('handles missing numeric fields with defaults', () {
      final json = {
        'name_en': 'Empty',
        'slug': 'empty',
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.totalAnswered, 0);
      expect(mastery.correctAnswered, 0);
      expect(mastery.masteryPercent, 0);
    });

    test('handles invalid numeric strings with defaults', () {
      final json = {
        'name_en': 'Invalid',
        'slug': 'invalid',
        'total_answered': 'not-a-number',
        'correct_answered': 'abc',
        'mastery_percent': '',
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.totalAnswered, 0);
      expect(mastery.correctAnswered, 0);
      expect(mastery.masteryPercent, 0);
    });

    test('handles null values for numeric fields with defaults', () {
      final json = {
        'name_en': 'NullValues',
        'slug': 'null-values',
        'total_answered': null,
        'correct_answered': null,
        'mastery_percent': null,
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.totalAnswered, 0);
      expect(mastery.correctAnswered, 0);
      expect(mastery.masteryPercent, 0);
    });

    test('handles null value for subjectHu', () {
      final json = {
        'name_en': 'English only',
        'name_hu': null,
        'slug': 'en-only',
        'total_answered': 1,
        'correct_answered': 1,
        'mastery_percent': 100,
      };

      final mastery = SubjectMastery.fromJson(json);

      expect(mastery.subjectHu, null);
    });
  });
}
