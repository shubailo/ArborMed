import 'package:flutter/material.dart';
import 'matching_pair_controller_group.dart';

class QuestionTranslationHelper {
  static String stripPrefix(String? text) {
    if (text == null) return "";
    return text.replaceFirst(RegExp(r'^\[(HU|EN)\] ?'), '');
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
      if (questionType != 'matching') 'questionText': questionText,
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
    } else if (questionType == 'single_choice' ||
        questionType == 'multiple_choice') {
      srcData['options'] = List<String>.of(options);
    }

    return srcData;
  }

  // A partial response must never replace a valid draft with missing fields.
  static bool isComplete(
      Map<String, dynamic> source, Map<String, dynamic> result) {
    bool valid(String original, dynamic translated) => original.trim().isEmpty
        ? translated == null || translated is String
        : translated is String && translated.trim().isNotEmpty;
    for (final entry in source.entries) {
      final original = entry.value, translated = result[entry.key];
      if (original is String && !valid(original, translated)) return false;
      if (original is List<String>) {
        if (translated is! List || translated.length != original.length) {
          return false;
        }
        for (var i = 0; i < original.length; i++) {
          if (!valid(original[i], translated[i])) return false;
        }
      }
    }
    return true;
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
    required List<String> currentOptions,
  }) {
    if (result['explanation'] != null) {
      explanationController.text = stripPrefix(result['explanation']);
    }
    if (result['questionText'] != null) {
      textController.text = stripPrefix(result['questionText']);
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
          final ctrl =
              isTargetHu ? matchingGroups[i].leftHu : matchingGroups[i].leftEn;
          if (list[i] is String && list[i].trim().isNotEmpty) {
            ctrl.text = stripPrefix(list[i]);
          }
        }
      }
      if (result['rights'] != null) {
        final list = result['rights'] as List;
        for (int i = 0; i < list.length && i < matchingGroups.length; i++) {
          final ctrl = isTargetHu
              ? matchingGroups[i].rightHu
              : matchingGroups[i].rightEn;
          if (list[i] is String && list[i].trim().isNotEmpty) {
            ctrl.text = stripPrefix(list[i]);
          }
        }
      }
      return null;
    } else {
      if (result['options'] != null) {
        final values = result['options'] as List;
        return List.generate(values.length, (i) {
          final value = values[i];
          if (value is String && value.trim().isNotEmpty) {
            return stripPrefix(value);
          }
          return i < currentOptions.length ? currentOptions[i] : '';
        });
      }
      return null;
    }
  }
}
