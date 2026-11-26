import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:arbor_med/core/models/admin_question.dart';
import 'matching_pair_controller_group.dart';

class QuestionPayloadBuilder {
  static void loadTypeSpecificData({
    required AdminQuestion? question,
    required String questionType,
    required TextEditingController s1EnController,
    required TextEditingController s1HuController,
    required TextEditingController s2EnController,
    required TextEditingController s2HuController,
    required TextEditingController linkEnController,
    required TextEditingController linkHuController,
    required TextEditingController textControllerEn,
    required TextEditingController textControllerHu,
    required void Function(int) setCorrectIndex,
    required void Function(int) addMultipleCorrectIndex,
    required void Function({
      required String leftE,
      required String leftH,
      required String rightE,
      required String rightH,
    }) addMatchingGroup,
  }) {
    if (question == null) return;
    final content = question.content is Map ? question.content as Map : const {};
    dynamic answer = question.correctAnswer;
    if (answer is String && (answer.trimLeft().startsWith('[') || answer.trimLeft().startsWith('"'))) {
      try {
        answer = jsonDecode(answer);
      } on FormatException {
        // A choice label can itself begin with a bracket or quotation mark.
      }
    }

    if (questionType == 'relation_analysis') {
      s1EnController.text = content['statement1']?['en'] ?? '';
      s1HuController.text = content['statement1']?['hu'] ?? '';
      s2EnController.text = content['statement2']?['en'] ?? '';
      s2HuController.text = content['statement2']?['hu'] ?? '';
      linkEnController.text = content['link_word']?['en'] ?? 'because';
      linkHuController.text = content['link_word']?['hu'] ?? 'mert';

      final letter = answer.toString().trim().toUpperCase();
      if (RegExp(r'^[A-E]$').hasMatch(letter)) setCorrectIndex(letter.codeUnitAt(0) - 65);
    } else if (questionType == 'true_false') {
      textControllerEn.text = content['statement']?['en'] ?? textControllerEn.text;
      textControllerHu.text = content['statement']?['hu'] ?? textControllerHu.text;
      final key = answer.toString().trim().toLowerCase();
      if (const {'true', 'igaz', '1'}.contains(key)) setCorrectIndex(0);
      if (const {'false', 'hamis', '0'}.contains(key)) setCorrectIndex(1);
    } else if (questionType == 'matching') {
      final List<dynamic>? pairs = content['pairs'];
      if (pairs != null) {
        for (var p in pairs) {
          addMatchingGroup(
            leftE: p['left']?['en'] ?? '',
            leftH: p['left']?['hu'] ?? '',
            rightE: p['right']?['en'] ?? '',
            rightH: p['right']?['hu'] ?? '',
          );
        }
      }
    } else if (questionType == 'multiple_choice') {
      final indices = question.answerKeys.map(question.choiceIndex).toList();
      if (indices.isNotEmpty && indices.every((i) => i != null)) {
        for (final index in indices.whereType<int>().toSet()) {
          addMultipleCorrectIndex(index);
        }
      }
    }
  }

  static Map<String, dynamic> buildPayload({
    required String questionType,
    required String? existingImageUrl,
    required int? correctIndex,
    required List<int> multipleCorrectIndices,
    List<AdminChoice?> originalChoices = const [],
    Map<String, dynamic> originalContent = const {},
    required List<String> currentOptionsEn,
    required List<String> currentOptionsHu,
    required List<MatchingPairControllerGroup> matchingGroups,
    required TextEditingController textControllerEn,
    required TextEditingController textControllerHu,
    required TextEditingController explanationControllerEn,
    required TextEditingController explanationControllerHu,
    required TextEditingController s1EnController,
    required TextEditingController s1HuController,
    required TextEditingController s2EnController,
    required TextEditingController s2HuController,
    required TextEditingController linkEnController,
    required TextEditingController linkHuController,
    required int? selectedTopicId,
    required int bloomLevel,
  }) {
    final contentPayload = {...originalContent, 'image_url': existingImageUrl};
    List<dynamic> optionsEn = currentOptionsEn;
    // Drop whitespace-only translations while retaining the authored text of nonempty choices.
    final optionsHu = currentOptionsHu.map((v) => v.trim().isEmpty ? '' : v).toList();
    final choiceFormat = questionType == 'single_choice' || questionType == 'multiple_choice';
    if (choiceFormat) {
      optionsEn = List.generate(currentOptionsEn.length, (i) {
        final original = i < originalChoices.length ? originalChoices[i] : null;
        final source = original?.source;
        final en = currentOptionsEn[i].trim().isEmpty ? '': currentOptionsEn[i];
        final hu = optionsHu[i];
        if (source is Map || (original != null && original.en != en) || (en.isEmpty && hu.isNotEmpty)) {
          final key = source is Map ? source['id'] ?? source['value'] : null;
          final fields = source is Map ? Map<String, dynamic>.from(source) : <String, dynamic>{};
          fields.remove('en');
          fields.remove('hu');
          if (en.trim().isEmpty) {
            // The authored key is retained as id. Old display aliases must not revive cleared text.
            fields.remove('label');
            fields.remove('text');
            fields.remove('value');
          }
          return {
            ...fields,
            if (original != null) 'id': key ?? original.label('en'),
            if (en.isNotEmpty) 'en': en,
            if (hu.isNotEmpty) 'hu': hu,
          };
        }
        return en;
      });
      if (contentPayload.containsKey('options')) {
        contentPayload['options'] = {'en': optionsEn, 'hu': optionsHu};
      }
      if (contentPayload.containsKey('question_text')) {
        contentPayload['question_text'] = {'en': textControllerEn.text, 'hu': textControllerHu.text};
      }
    }

    late final draft = AdminQuestion(
      id: 0,
      topicId: selectedTopicId ?? 0,
      bloomLevel: bloomLevel,
      options: {'en': optionsEn, 'hu': optionsHu},
      correctAnswer: null,
    );
    String answerKey(int i) {
      final original = i < originalChoices.length ? originalChoices[i] : null;
      if (original != null && optionsEn[i] is Map) return original.id;
      final label = currentOptionsEn[i].trim().isNotEmpty ? currentOptionsEn[i] : currentOptionsHu[i];
      // The historical TEXT column also stores JSON-encoded answer keys.
      final looksEncoded = RegExp(r'^[\[{"]').hasMatch(label.trimLeft());
      return !looksEncoded && draft.choiceIndex(label) == i ? label : draft.choices[i].id;
    }

    dynamic correctAnswerPayload;

    if (questionType == 'relation_analysis') {
      contentPayload['statement1'] = {
        'en': s1EnController.text,
        'hu': s1HuController.text
      };
      contentPayload['statement2'] = {
        'en': s2EnController.text,
        'hu': s2HuController.text
      };
      contentPayload['link_word'] = {
        'en': linkEnController.text,
        'hu': linkHuController.text
      };
      correctAnswerPayload =
          String.fromCharCode('A'.codeUnitAt(0) + (correctIndex ?? 0));
    } else if (questionType == 'matching') {
      final List<Map<String, dynamic>> pairs = [];
      final Map<String, String> correctMap = {};
      for (var group in matchingGroups) {
        pairs.add({
          'left': {'en': group.leftEn.text, 'hu': group.leftHu.text},
          'right': {'en': group.rightEn.text, 'hu': group.rightHu.text}
        });
        if (group.leftEn.text.isNotEmpty) {
          correctMap[group.leftEn.text] = group.rightEn.text;
        }
      }
      contentPayload['pairs'] = pairs;
      correctAnswerPayload = correctMap;
    } else if (questionType == 'multiple_choice') {
      correctAnswerPayload =
          multipleCorrectIndices.map(answerKey).toList();
      contentPayload['is_multi'] = true;
    } else if (questionType == 'true_false') {
      contentPayload['statement'] = {
        'en': textControllerEn.text,
        'hu': textControllerHu.text
      };
      correctAnswerPayload = (correctIndex == 0) ? 'true' : 'false';
    } else {
      correctAnswerPayload = answerKey(correctIndex!);
    }

    return {
      'question_text_en': textControllerEn.text,
      'question_text_hu': textControllerHu.text,
      'options_en': optionsEn,
      'options_hu': optionsHu,
      'explanation_en': explanationControllerEn.text,
      'explanation_hu': explanationControllerHu.text,
      'correct_answer': correctAnswerPayload,
      'question_type': questionType,
      'topic_id': selectedTopicId,
      'bloom_level': bloomLevel,
      'content': contentPayload,
    };
  }
}
