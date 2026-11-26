import 'package:flutter/material.dart';
import 'matching_pair_controller_group.dart';

/// A request becomes stale on the first text edit, even if the edit is undone.
/// Moving the caret or changing the selection leaves the request valid.
class TranslationTextWatch {
  final _listeners = <TextEditingController, VoidCallback>{};
  bool changed = false;

  TranslationTextWatch(Iterable<TextEditingController> controllers) {
    for (final controller in controllers) {
      final original = controller.text;
      void listen() {
        if (controller.text != original) changed = true;
      }
      _listeners[controller] = listen;
      controller.addListener(listen);
    }
  }

  void dispose() {
    for (final entry in _listeners.entries) {
      entry.key.removeListener(entry.value);
    }
  }
}

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
      'questionText': questionText,
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

  // Validate every requested nonempty source before mutating any controller.
  // Providers may return placeholders or extra keys for fields they did not translate.
  static Map<String, dynamic>? validatedResult(
      Map<String, dynamic> source, Map<String, dynamic> result) {
    String? normalize(dynamic value) {
      if (value is! String) return null;
      final text = stripPrefix(value);
      return text.trim().isEmpty ? null : text;
    }

    final checked = <String, dynamic>{};
    for (final entry in source.entries) {
      final original = entry.value;
      final value = result[entry.key];
      if (original is String) {
        if (original.trim().isEmpty) continue;
        final text = normalize(value);
        if (text == null) return null;
        checked[entry.key] = text;
      } else if (original is List<String>) {
        if (value is! List || value.length != original.length) return null;
        final values = <String?>[];
        for (var i = 0; i < original.length; i++) {
          final text = original[i].trim().isEmpty ? null : normalize(value[i]);
          if (text == null && original[i].trim().isNotEmpty) return null;
          values.add(text);
        }
        checked[entry.key] = values;
      } else {
        return null;
      }
    }
    return checked;
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
      explanationController.text = result['explanation'];
    }
    if (result['questionText'] != null) {
      textController.text = result['questionText'];
    }

    if (questionType == 'relation_analysis') {
      if (result['statement1'] != null) {
        s1Controller.text = result['statement1'];
      }
      if (result['statement2'] != null) {
        s2Controller.text = result['statement2'];
      }
      if (result['link_word'] != null) {
        linkController.text = result['link_word'];
      }
      return null;
    } else if (questionType == 'matching') {
      if (result['lefts'] != null) {
        final list = result['lefts'] as List;
        for (int i = 0; i < list.length && i < matchingGroups.length; i++) {
          final ctrl =
              isTargetHu ? matchingGroups[i].leftHu : matchingGroups[i].leftEn;
          if (list[i] is String && list[i].trim().isNotEmpty) {
            ctrl.text = list[i];
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
            ctrl.text = list[i];
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
            return value;
          }
          return i < currentOptions.length ? currentOptions[i] : '';
        });
      }
      return null;
    }
  }
}
