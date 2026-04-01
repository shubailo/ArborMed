class QuestionChoice {
  final String id;
  final String text;

  const QuestionChoice({
    required this.id,
    required this.text,
  });

  factory QuestionChoice.fromJson(Map<String, dynamic> json) {
    return QuestionChoice(
      id: json['id']?.toString() ?? '',
      text: json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
  };
}

class Question {
  final int id;
  final String text;
  final String? explanation;
  final List<QuestionChoice> choices;
  final String correctAnswer; // ID of the correct choice
  final int topicId;
  final String? topicName;
  final String type; // single_choice, multiple_choice
  final int bloomLevel;
  final String difficulty;

  const Question({
    required this.id,
    required this.text,
    this.explanation,
    required this.choices,
    required this.correctAnswer,
    required this.topicId,
    this.topicName,
    this.type = 'single_choice',
    this.bloomLevel = 1,
    this.difficulty = 'Medium',
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    final optionsData = json['options'];
    List<QuestionChoice> choices = [];
    
    if (optionsData is List) {
      choices = optionsData.map((e) => QuestionChoice.fromJson(e)).toList();
    } else if (optionsData is Map && optionsData.containsKey('en')) {
      final enOptions = optionsData['en'] as List;
      choices = enOptions.asMap().entries.map((entry) {
        return QuestionChoice(id: entry.key.toString(), text: entry.value.toString());
      }).toList();
    }

    return Question(
      id: json['id'],
      text: json['text'] ?? json['question_text_en'] ?? '',
      explanation: json['explanation'] ?? json['explanation_en'],
      choices: choices,
      correctAnswer: json['correct_answer']?.toString() ?? '',
      topicId: json['topic_id'] ?? 0,
      topicName: json['topic_name'] ?? json['topic_name_en'],
      type: json['type'] ?? 'single_choice',
      bloomLevel: json['bloom_level'] ?? 1,
      difficulty: json['difficulty'] ?? 'Medium',
    );
  }
}
