import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/readiness.dart';

void main() {
  group('ReadinessDetail.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'topic': 'Cardiology',
        'slug': 'cardiology',
        'score': 85,
        'metrics': {
          'retention': 0.92,
          'mastery': 78,
        },
      };

      final detail = ReadinessDetail.fromJson(json);

      expect(detail.topic, 'Cardiology');
      expect(detail.slug, 'cardiology');
      expect(detail.score, 85);
      expect(detail.retention, 0.92);
      expect(detail.mastery, 78);
    });

    test('handles missing metrics object with defaults', () {
      final json = {
        'topic': 'Neurology',
        'slug': 'neurology',
        'score': 90,
      };

      final detail = ReadinessDetail.fromJson(json);

      expect(detail.topic, 'Neurology');
      expect(detail.slug, 'neurology');
      expect(detail.score, 90);
      expect(detail.retention, 0.0);
      expect(detail.mastery, 0);
    });

    test('handles missing top-level fields with defaults', () {
      final json = <String, dynamic>{};

      final detail = ReadinessDetail.fromJson(json);

      expect(detail.topic, '');
      expect(detail.slug, '');
      expect(detail.score, 0);
      expect(detail.retention, 0.0);
      expect(detail.mastery, 0);
    });

    test('handles numeric parsing from types appropriately', () {
       final json = {
        'topic': 'Oncology',
        'slug': 'oncology',
        'score': 85.5, // double where int is expected, toInt() handles it if it's a double
        'metrics': {
          'retention': 1, // int where double is expected, toDouble() handles it
          'mastery': 78.9, // double where int is expected
        },
      };

      final detail = ReadinessDetail.fromJson(json);

      expect(detail.topic, 'Oncology');
      expect(detail.slug, 'oncology');
      expect(detail.score, 85);
      expect(detail.retention, 1.0);
      expect(detail.mastery, 78);
    });
  });

  group('ReadinessScore.fromJson', () {
    test('parses valid JSON correctly', () {
      final json = {
        'overallReadiness': 88,
        'breakdown': [
          {
            'topic': 'Cardiology',
            'slug': 'cardiology',
            'score': 85,
            'metrics': {
              'retention': 0.92,
              'mastery': 78,
            },
          },
          {
            'topic': 'Neurology',
            'slug': 'neurology',
            'score': 90,
            'metrics': {
              'retention': 0.88,
              'mastery': 82,
            },
          }
        ],
      };

      final score = ReadinessScore.fromJson(json);

      expect(score.overall, 88);
      expect(score.breakdown.length, 2);

      expect(score.breakdown[0].topic, 'Cardiology');
      expect(score.breakdown[0].score, 85);

      expect(score.breakdown[1].topic, 'Neurology');
      expect(score.breakdown[1].score, 90);
    });

    test('handles missing overallReadiness with default', () {
      final json = {
        'breakdown': [],
      };

      final score = ReadinessScore.fromJson(json);

      expect(score.overall, 0);
      expect(score.breakdown, isEmpty);
    });

    test('handles missing breakdown list with default', () {
      final json = {
        'overallReadiness': 75,
      };

      final score = ReadinessScore.fromJson(json);

      expect(score.overall, 75);
      expect(score.breakdown, isEmpty);
    });

    test('handles null breakdown value', () {
       final json = {
        'overallReadiness': 75,
        'breakdown': null,
      };

      final score = ReadinessScore.fromJson(json);

      expect(score.overall, 75);
      expect(score.breakdown, isEmpty);
    });

     test('handles numeric parsing appropriately', () {
       final json = {
        'overallReadiness': 75.5, // double where int is expected
        'breakdown': [],
      };

      final score = ReadinessScore.fromJson(json);

      expect(score.overall, 75);
      expect(score.breakdown, isEmpty);
    });
  });
}
