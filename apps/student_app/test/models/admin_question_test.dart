import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/core/models/admin_question.dart';

void main() {
  group('AdminQuestion.fromJson', () {
    test('decodes historical content and SQL counts without losing raw labels',
        () {
      final q = AdminQuestion.fromJson({
        'id': '19',
        'topic_id': '5',
        'bloom_level': '2',
        'attempts': '8',
        'report_count': '1',
        'success_rate': '62.5',
        'options': [],
        'question_text_en': ' ',
        'correct_answer': '"[42]"',
        'content':
            '{"question_text":{"en":"Prompt","hu":"Kérdés"},"options":["[42]","Other"]}',
      });
      expect([q.id, q.topicId, q.bloomLevel, q.attempts, q.reportCount],
          [19, 5, 2, 8, 1]);
      expect(q.successRate, 62.5);
      expect(q.questionLabel('en'), 'Prompt');
      expect(q.questionLabel('hu'), 'Kérdés');
      expect(q.answerKeys, ['[42]']);
      expect(q.choiceIndex(q.answerKeys.single), 0);
    });

    test('maps Hungarian-only columns and refuses ambiguous historical keys',
        () {
      final q = AdminQuestion.fromJson({
        'id': 1,
        'topic_id': 5,
        'options_en': '[]',
        'options_hu': '["Első","Második"]',
        'question_text_hu': 'Csak magyarul',
        'correct_answer': 'Második',
      });
      expect(q.questionLabel('en'), 'Csak magyarul');
      expect(q.choices.first.en, isEmpty);
      expect(q.choices.first.label('en'), 'Első');
      expect(q.choiceIndex('  MÁSODIK  '), 1);
      final aliases = AdminQuestion.fromJson({
        'id': 2,
        'topic_id': 1,
        'options': [
          {'id': 42, 'en': 'Other', 'hu': 'Válasz'},
          {'id': 'label', 'en': '42', 'hu': 'Válasz'},
        ],
      });
      expect(aliases.choiceIndex('42'), isNull);
      expect(aliases.choiceIndex('Válasz'), isNull);
      expect(aliases.choiceIndex('label'), 1);
      expect(aliases.choiceIndex('opt_73475cb40a568e8da8a045ced110137e'), 0);
    });

    test(
        'keeps structured identities in the translated column with empty source slots',
        () {
      final q = AdminQuestion.fromJson({
        'id': 2,
        'topic_id': 1,
        'options': {
          'en': ['', ''],
          'hu': [
            {'id': 42, 'label': 'Egy'},
            {'id': 5, 'hu': 'Kettő'}
          ]
        },
        'correct_answer': '42'
      });
      expect(q.choices.first.en, isEmpty);
      expect(q.choices.first.hu, 'Egy');
      expect(q.choices.first.id, 'opt_73475cb40a568e8da8a045ced110137e');
      expect(q.choiceIndex(q.answerKeys.single), 0);
    });

    test('only unambiguous historical blank-label IDs identify a choice', () {
      const oldId = 'opt_e3b0c44298fc1c149afbf4c8996fb924';
      AdminQuestion example(List<String> en) => AdminQuestion.fromJson({
            'id': 1,
            'topic_id': 3,
            'options': {
              'en': en,
              'hu': ['Első', 'Második']
            },
          });
      expect(example(['', 'Second']).choiceIndex(oldId), 0);
      expect(example(['', '']).choiceIndex(oldId), isNull);
    });

    test('boolean keys share scalar, numeric and singleton decoding across admin views', () {
      bool? parse(Object? value) => AdminQuestion.fromJson({
        'id': 1, 'topic_id': 2, 'type': 'true_false', 'correct_answer':value,
      }).booleanAnswer;
      for (final raw in [true, 'igaz', '1', '[1.0]', '[" TRUE "]']) {
        expect(parse(raw), isTrue);
      }
      for (final raw in [false, 'hamis', '0', '[0.0]', ['false']]) {
        expect(parse(raw), isFalse);
      }
      for (final raw in [null, [], [true,false], '[0.5]', 'yes', {}]) {
        expect(parse(raw), isNull);
      }
    });

    test('malformed statistics report only the field name', () {
      expect(
          () => AdminQuestion.fromJson({
                'id': 1,
                'topic_id': 1,
                'success_rate': 'private-question-text',
              }),
          throwsA(isA<FormatException>().having(
              (error) => error.message, 'message', 'Invalid success_rate')));
    });

    test('parses standard question JSON', () {
      final json = {
        'id': 1,
        'text': 'What is X?',
        'options': ['A', 'B'],
        'correct_answer': 'A',
        'topic_id': 5,
        'bloom_level': 2,
        'type': 'single_choice'
      };

      final q = AdminQuestion.fromJson(json);

      expect(q.id, 1);
      expect(q.text, 'What is X?');
      expect(q.options, ['A', 'B']);
      expect(q.correctAnswer, 'A');
      expect(q.bloomLevel, 2);
      expect(q.type, 'single_choice');
    });

    test('supports fallback keys for multilingual fields', () {
      final json = {
        'id': 2,
        'question_text_en': 'English Text', // text is missing
        'options': [],
        'correct_answer': 'X',
        'topic_id': 1,
        'name_en': 'Topic En' // topic_name missing
      };

      final q = AdminQuestion.fromJson(json);

      expect(q.text, 'English Text');
      expect(q.topicNameEn, 'Topic En');
    });

    test('calculates success rate safely from mixed types', () {
      final jsonInt = {
        'id': 1,
        'options': [],
        'correct_answer': '',
        'topic_id': 1,
        'success_rate': 50 // int
      };

      final jsonDouble = {
        'id': 2,
        'options': [],
        'correct_answer': '',
        'topic_id': 1,
        'success_rate': 0.75 // double
      };

      final jsonString = {
        'id': 3,
        'options': [],
        'correct_answer': '',
        'topic_id': 1,
        'success_rate': null // null
      };

      expect(AdminQuestion.fromJson(jsonInt).successRate, 50.0);
      expect(AdminQuestion.fromJson(jsonDouble).successRate, 0.75);
      expect(AdminQuestion.fromJson(jsonString).successRate, 0.0);
    });

    test('parses multilingual options map correctly', () {
      final json = {
        'id': 1,
        'options': {
          'en': ['Yes', 'No'],
          'hu': ['Igen', 'Nem']
        },
        'correct_answer': '',
        'topic_id': 1
      };

      final q = AdminQuestion.fromJson(json);
      expect(q.options, isA<Map>());
      expect(q.optionsHu, ['Igen', 'Nem']);
    });
  });
}
