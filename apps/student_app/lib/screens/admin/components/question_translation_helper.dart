import 'package:flutter/material.dart';
import 'matching_pair_controller_group.dart';

class QuestionTranslationHelper {
  static String stripPrefix(String? text) {
    if (text == null) return "";
    return text
        .replaceAll('[HU] ', '')
        .replaceAll('[HU]', '')
        .replaceAll('[EN] ', '')
        .replaceAll('[EN]', '');
  }

  static Map<String, dynamic> buildTranslationPayload({
    required String questionType,
    required String source,
    required String explanation,
    required String questionText,
    required List<String> options,
    required String s1,
    required String s2,
    required String linkWord,
    required List<MatchingPairControllerGroup> matchingGroups,
  }) {
    final Map<String, dynamic> srcData = {
      'explanation': explanation,
    };

    if (questionType == 'relation_analysis') {
      srcData['statement1'] = s1;
      srcData['statement2'] = s2;
      srcData['link_word'] = linkWord;
    } else if (questionType == 'matching') {
      srcData['lefts'] = matchingGroups
          .map((MatchingPairControllerGroup g) =>
              source == 'en' ? g.leftEn.text : g.leftHu.text)
          .toList();
      srcData['rights'] = matchingGroups
          .map((MatchingPairControllerGroup g) =>
              source == 'en' ? g.rightEn.text : g.rightHu.text)
          .toList();
    } else {
      srcData['questionText'] = questionText;
      srcData['options'] = options;
    }

    return srcData;
  }

  static List<String>? applyTranslationResult({
    required Map<String, dynamic> result,
    required String questionType,
    required bool isTargetHu,
    required TextEditingController explanationController,
    required TextEditingController textController,
    required TextEditingController s1Controller,
    required TextEditingController s2Controller,
    required TextEditingController linkController,
    required List<MatchingPairControllerGroup> matchingGroups,
  }) {
    if (result['explanation'] != null) {
      explanationController.text = stripPrefix(result['explanation']);
    }

    if (questionType == 'relation_analysis') {
      if (result['statement1'] != null) {
        s1Controller.text = stripPrefix(result['statement1']);
      }
      if (result['statement2'] != null) {
        s2Controller.text = stripPrefix(result['statement2']);
      }
      if (result['link_word'] != null) {
        linkController.text = stripPrefix(result['link_word']);
      }
      return null;
    } else if (questionType == 'matching') {
      if (result['lefts'] != null) {
        final list = result['lefts'] as List;
        for (int i = 0; i < list.length && i < matchingGroups.length; i++) {
          final ctrl = isTargetHu ? matchingGroups[i].leftHu : matchingGroups[i].leftEn;
          ctrl.text = stripPrefix(list[i].toString());
        }
      }
      if (result['rights'] != null) {
        final list = result['rights'] as List;
        for (int i = 0; i < list.length && i < matchingGroups.length; i++) {
          final ctrl = isTargetHu ? matchingGroups[i].rightHu : matchingGroups[i].rightEn;
          ctrl.text = stripPrefix(list[i].toString());
        }
      }
      return null;
    } else {
      if (result['questionText'] != null) {
        textController.text = stripPrefix(result['questionText']);
      }
      if (result['options'] != null) {
        return (result['options'] as List)
            .map((e) => stripPrefix(e.toString()))
            .toList();
      }
      return null;
    }
  }
}
