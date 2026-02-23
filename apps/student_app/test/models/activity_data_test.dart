import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/activity_data.dart';

void main() {
  group('ActivityData.fromJson', () {
    test('parses valid full JSON correctly', () {
      final json = {
        'date': '2023-10-27T12:00:00Z',
        'day_label': 'Mon',
        'count': 10,
        'correct_count': 5,
      };

      final activityData = ActivityData.fromJson(json);

      expect(activityData.date, DateTime.parse('2023-10-27T12:00:00Z'));
      expect(activityData.dayLabel, 'Mon');
      expect(activityData.count, 10);
      expect(activityData.correctCount, 5);
    });

    test('handles null/missing day_label', () {
      final json = {
        'date': '2023-10-27T12:00:00Z',
        'count': 10,
        'correct_count': 5,
      };

      final activityData = ActivityData.fromJson(json);

      expect(activityData.dayLabel, null);
    });

    test('handles missing count and correct_count (defaults to 0)', () {
      final json = {
        'date': '2023-10-27T12:00:00Z',
      };

      final activityData = ActivityData.fromJson(json);

      expect(activityData.count, 0);
      expect(activityData.correctCount, 0);
    });

    test('handles string values for numeric fields', () {
      final json = {
        'date': '2023-10-27T12:00:00Z',
        'count': '20',
        'correct_count': '15',
      };

      final activityData = ActivityData.fromJson(json);

      expect(activityData.count, 20);
      expect(activityData.correctCount, 15);
    });

    test('throws FormatException on invalid date format', () {
      final json = {
        'date': 'invalid-date',
        'count': 10,
        'correct_count': 5,
      };

      expect(() => ActivityData.fromJson(json), throwsFormatException);
    });

     test('throws Error on missing date', () {
      final json = {
        'count': 10,
        'correct_count': 5,
      };

      // Since json['date'] is null, DateTime.parse(null) throws in Dart.
      // Depending on the Dart version/config, it might be a specific error.
      // Usually ArgumentError or similar if null safety is enforced, or just a crash.
      // Actually DateTime.parse(null) is a compile error in sound null safety if the argument is nullable.
      // But json['date'] is dynamic, so it passes at compile time.
      // At runtime: DateTime.parse(null) throws.
      // Let's just catch any error.
      expect(() => ActivityData.fromJson(json), throwsA(anything));
    });
  });
}
