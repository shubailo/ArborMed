import 'package:arbor_med/core/models/relation_answer.dart';
import 'package:arbor_med/core/models/relation_content.dart';
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
  }) {
    if (question == null) return;
    final content = question.content is Map ? question.content as Map : const {};
    if (questionType == 'relation_analysis') {
      s1EnController.text = relationText(content, 'statement1', 'en');
      s1HuController.text = relationText(content, 'statement1', 'hu');
      s2EnController.text = relationText(content, 'statement2', 'en');
      s2HuController.text = relationText(content, 'statement2', 'hu');
      final useDefaultLink = content['link_word'] == null &&
          (s1EnController.text.isNotEmpty || s1HuController.text.isNotEmpty) &&
          (s2EnController.text.isNotEmpty || s2HuController.text.isNotEmpty);
      linkEnController.text = useDefaultLink ? 'because' : relationText(content, 'link_word', 'en');
      linkHuController.text = useDefaultLink ? 'mert' : relationText(content, 'link_word', 'hu');
      final answer = RelationAnswer.fromStored(question.correctAnswer);
      if (answer != null) setCorrectIndex(answer.index);
    } else if (questionType == 'true_false') {
      final en = relationText(content, 'statement', 'en');
      final hu = relationText(content, 'statement', 'hu');
      if (en.isNotEmpty) textControllerEn.text = en;
      if (hu.isNotEmpty) textControllerHu.text = hu;
      final answer = question.booleanAnswer;
      if (answer != null) setCorrectIndex(answer ? 0 : 1);
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
    Object? originalMatchingOptions,
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
    List<dynamic> optionsHu = currentOptionsHu.map((v) => v.trim().isEmpty ? '' : v).toList();
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

    Map<String, dynamic> localized(Object? old, String en, String hu) => {
      if (old is Map) ...Map<String, dynamic>.from(old),
      'en': en,
      'hu': hu,
    };

    if (questionType == 'relation_analysis') {
      if (contentPayload.containsKey('question_text')) {
        contentPayload['question_text'] = localized(
            contentPayload['question_text'], textControllerEn.text, textControllerHu.text);
      }
      for (final (field, alias, en, hu) in [
        ('statement1', 'statement_1', s1EnController.text, s1HuController.text),
        ('statement2', 'statement_2', s2EnController.text, s2HuController.text),
        ('link_word', 'link_word', linkEnController.text, linkHuController.text),
      ]) {
        final legacy = alias == field ? null : contentPayload.remove(alias);
        final original = contentPayload[field];
        if (original != null || legacy != null || en.trim().isNotEmpty || hu.trim().isNotEmpty) {
          contentPayload[field] = localized({
            if (legacy is Map) ...Map<String, dynamic>.from(legacy),
            if (original is Map) ...Map<String, dynamic>.from(original),
          }, en, hu);
        }
      }
      correctAnswerPayload = RelationAnswer.values[correctIndex!].code;
    } else if (questionType == 'matching') {
      // These legacy columns can contain extra distractors and unaligned translations.
      // The current editor writes the pairing definition to content.pairs.
      final legacy = originalMatchingOptions;
      final en = legacy is Map ? legacy['en'] : legacy;
      final hu = legacy is Map ? legacy['hu'] : null;
      optionsEn = en is List ? en : const [];
      optionsHu = hu is List ? hu : const [];
      final List<Map<String, dynamic>> pairs = [];
      final Map<String, String> correctMap = {};
      for (var group in matchingGroups) {
        pairs.add(group.toJson());
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
      contentPayload['statement'] = localized(
          contentPayload['statement'], textControllerEn.text, textControllerHu.text);
      correctAnswerPayload = const ['true', 'false'][correctIndex!];
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
