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
    required List<String> currentOptionsEn,
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
    final content = question.content;
    if (content == null || content is! Map) return;

    if (questionType == 'relation_analysis') {
      s1EnController.text = content['statement1']?['en'] ?? '';
      s1HuController.text = content['statement1']?['hu'] ?? '';
      s2EnController.text = content['statement2']?['en'] ?? '';
      s2HuController.text = content['statement2']?['hu'] ?? '';
      linkEnController.text = content['link_word']?['en'] ?? 'because';
      linkHuController.text = content['link_word']?['hu'] ?? 'mert';

      final corr = question.correctAnswer;
      if (corr is String) {
        final idx = corr.toUpperCase().codeUnitAt(0) - 'A'.codeUnitAt(0);
        if (idx >= 0 && idx < 5) setCorrectIndex(idx);
      }
    } else if (questionType == 'true_false') {
      textControllerEn.text = content['statement']?['en'] ?? '';
      textControllerHu.text = content['statement']?['hu'] ?? '';
      final corr = question.correctAnswer.toString().toLowerCase();
      setCorrectIndex((corr == 'true') ? 0 : 1);
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
      final corr = question.correctAnswer;
      if (corr is List) {
        for (var val in corr) {
          final idx = currentOptionsEn.indexOf(val.toString());
          if (idx != -1) addMultipleCorrectIndex(idx);
        }
      }
    }
  }

  static Map<String, dynamic> buildPayload({
    required String questionType,
    required String? existingImageUrl,
    required int? correctIndex,
    required List<int> multipleCorrectIndices,
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
    Map<String, dynamic> contentPayload = {'image_url': existingImageUrl};
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
          multipleCorrectIndices.map((idx) => currentOptionsEn[idx]).toList();
      contentPayload['is_multi'] = true;
    } else if (questionType == 'true_false') {
      contentPayload['statement'] = {
        'en': textControllerEn.text,
        'hu': textControllerHu.text
      };
      correctAnswerPayload = (correctIndex == 0) ? 'true' : 'false';
    } else {
      correctAnswerPayload = currentOptionsEn[correctIndex ?? 0];
    }

    return {
      'question_text_en': textControllerEn.text,
      'question_text_hu': textControllerHu.text,
      'options_en': currentOptionsEn,
      'options_hu': currentOptionsHu,
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
