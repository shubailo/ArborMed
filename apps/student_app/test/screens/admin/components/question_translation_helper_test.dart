import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/screens/admin/components/matching_pair_controller_group.dart';
import 'package:arbor_med/screens/admin/components/question_translation_helper.dart';

void main() {
  group('QuestionTranslationHelper', () {
    test('stripPrefix removes [HU] and [EN] tags correctly', () {
      expect(QuestionTranslationHelper.stripPrefix('[HU] Text in Hungarian'), 'Text in Hungarian');
      expect(QuestionTranslationHelper.stripPrefix('[HU]Text without space'), 'Text without space');
      expect(QuestionTranslationHelper.stripPrefix('[EN] English text'), 'English text');
      expect(QuestionTranslationHelper.stripPrefix('[EN]No space'), 'No space');
      expect(QuestionTranslationHelper.stripPrefix('No prefix'), 'No prefix');
      expect(QuestionTranslationHelper.stripPrefix('Keep [EN] inside'), 'Keep [EN] inside');
      expect(QuestionTranslationHelper.stripPrefix(null), '');
    });
    test('rejects a partial provider response before updating the draft', () {
      bool complete(Map<String, dynamic> source, Map<String, dynamic> response) =>
          QuestionTranslationHelper.validatedResult(source, response) != null;
      final original = {'questionText':'Example', 'options':<String>['A','B','']};
      expect(complete(original, {'questionText':'Példa','options':['Egy','Kettő',null]}), isTrue);
      expect(complete(original, {'options':['Egy','Kettő',null]}), isFalse);
      expect(complete(original, {'questionText':'Példa','options':['Egy']}), isFalse);
      expect(complete(original, {'questionText':'Példa','options':['Egy',null,'']}), isFalse);
    });

    test('selection changes remain eligible while an edit followed by undo invalidates the watch', () {
      final controller = TextEditingController(text:'Example');
      final watch = TranslationTextWatch([controller]);
      controller.selection = const TextSelection(baseOffset:0, extentOffset:3);
      expect(watch.changed, isFalse);
      controller.text = 'Edited';
      controller.text = 'Example';
      expect(watch.changed, isTrue);
      watch.dispose();
      controller.dispose();
    });

    test('validated result writes only requested nonempty sources, after prefix removal', () {
      const request = {'questionText':'Question', 'explanation':' ', 'options':<String>['A','']};
      final result = QuestionTranslationHelper.validatedResult(request, {
        'questionText':'[HU] Kérdés', 'explanation':'Injected', 'options':['[HU] Egy','Injected'], 'statement1':'Unexpected',
      });
      expect(result,{'questionText':'Kérdés','options':['Egy',null]});
      expect(QuestionTranslationHelper.validatedResult(request,{
        'questionText':'Kérdés','options':['[HU] ',null],
      }), isNull);
    });

    test('buildTranslationPayload formats relation analysis correctly', () {
      final payload = QuestionTranslationHelper.buildTranslationPayload(
        questionType: 'relation_analysis',
        source: 'en',
        explanation: 'Some explanation',
        questionText: 'Question stem',
        options: ['A', 'B'],
        s1: 'Statement 1',
        s2: 'Statement 2',
        linkWord: 'because',
        matchingGroups: [],
      );

      expect(payload['explanation'], 'Some explanation');
      expect(payload['statement1'], 'Statement 1');
      expect(payload['statement2'], 'Statement 2');
      expect(payload['link_word'], 'because');
      expect(payload['questionText'], 'Question stem');
    });

    test('buildTranslationPayload formats matching pairs correctly', () {
      final group1 = MatchingPairControllerGroup(
        leftEn: TextEditingController(text: 'Left 1'),
        leftHu: TextEditingController(text: 'Bal 1'),
        rightEn: TextEditingController(text: 'Right 1'),
        rightHu: TextEditingController(text: 'Jobb 1'),
      );

      final payload = QuestionTranslationHelper.buildTranslationPayload(
        questionType: 'matching',
        source: 'en',
        explanation: 'Exp',
        questionText: '',
        options: [],
        s1: '',
        s2: '',
        linkWord: '',
        matchingGroups: [group1],
      );

      expect(payload['explanation'], 'Exp');
      expect(payload['lefts'], ['Left 1']);
      expect(payload['rights'], ['Right 1']);

      final payloadHu = QuestionTranslationHelper.buildTranslationPayload(
        questionType: 'matching',
        source: 'hu',
        explanation: 'Exp Hu',
        questionText: '',
        options: [],
        s1: '',
        s2: '',
        linkWord: '',
        matchingGroups: [group1],
      );

      expect(payloadHu['lefts'], ['Bal 1']);
      expect(payloadHu['rights'], ['Jobb 1']);

      group1.dispose();
    });

    test('buildTranslationPayload formats standard questions (single/multiple choice) correctly', () {
      final payload = QuestionTranslationHelper.buildTranslationPayload(
        questionType: 'single_choice',
        source: 'en',
        explanation: 'Why it is right',
        questionText: 'What is cardiology?',
        options: ['Heart', 'Lungs'],
        s1: '',
        s2: '',
        linkWord: '',
        matchingGroups: [],
      );

      expect(payload['explanation'], 'Why it is right');
      expect(payload['questionText'], 'What is cardiology?');
      expect(payload['options'], ['Heart', 'Lungs']);
    });
  });
}

