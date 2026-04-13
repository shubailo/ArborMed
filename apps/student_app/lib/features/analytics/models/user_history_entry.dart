class UserHistoryEntry {
  final int id;
  final DateTime createdAt;
  final bool isCorrect;
  final int responseTimeMs;
  final String questionText;
  final int bloomLevel;
  final String sectionName;
  final String subjectName;
  final String subjectSlug;

  UserHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.isCorrect,
    required this.responseTimeMs,
    required this.questionText,
    required this.bloomLevel,
    required this.sectionName,
    required this.subjectName,
    required this.subjectSlug,
  });

  factory UserHistoryEntry.fromJson(Map<String, dynamic> json) {
    return UserHistoryEntry(
      id: json['id'],
      createdAt: DateTime.parse(json['created_at']),
      isCorrect: json['is_correct'] ?? false,
      responseTimeMs: json['response_time_ms'] ?? 0,
      questionText: json['question_text_en'] ?? '',
      bloomLevel: json['bloom_level'] ?? 1,
      sectionName: json['section_name'] ?? '',
      subjectName: json['subject_name'] ?? '',
      subjectSlug: json['subject_slug'] ?? '',
    );
  }
}
