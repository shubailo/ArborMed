import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/admin_question.dart';

void main() {
  group('AdminQuestion.fromJson', () {
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
