

class CoreQuestion {
  final int id;
  final String? text; // Default/English text
  final String? questionTextHu; // Hungarian text
  final dynamic options; // String or List or Map ({"en": [], "hu": []})
  final dynamic content;
  final dynamic correctAnswer;
  final String? explanation; // Default/English explanation
  final String? explanationHu; // Hungarian explanation
  final int topicId;
  final int bloomLevel;
  final String? type;

  CoreQuestion({
    required this.id,
    this.text,
    this.questionTextHu,
    required this.options,
    this.content,
    required this.correctAnswer,
    this.explanation,
    this.explanationHu,
    required this.topicId,
    required this.bloomLevel,
    this.type,
  });

  factory CoreQuestion.fromJson(Map<String, dynamic> json) {
    return CoreQuestion(
      id: json['id'],
      text: json['text'] ?? json['question_text_en'] ?? '',
      questionTextHu: json['question_text_hu'],
      options: json['options'],
      content: json['content'],
      correctAnswer: json['correct_answer'],
      explanation: json['explanation'] ?? json['explanation_en'],
      explanationHu: json['explanation_hu'],
      topicId: json['topic_id'],
      bloomLevel: json['bloom_level'] ?? 1,
      type: json['type'] ?? 'single_choice',
    );
  }

  // Helper to extract options list for a specific language
  List<String>? get optionsHu {
    if (options is Map) {
      final map = options as Map;
      if (map.containsKey('hu')) {
        return (map['hu'] as List).map((e) => e?.toString() ?? '').toList();
      }
    }
    return null;
  }
}
