class SubjectMastery {
  final String subjectEn;
  final String? subjectHu;
  final String slug;
  final int totalAnswered;
  final int correctAnswered;
  final int masteryPercent;

  SubjectMastery({
    required this.subjectEn,
    this.subjectHu,
    required this.slug,
    required this.totalAnswered,
    required this.correctAnswered,
    required this.masteryPercent,
  });

  factory SubjectMastery.fromJson(Map<String, dynamic> json) {
    return SubjectMastery(
      subjectEn: json['name_en'] ?? json['subject'] ?? 'Unknown',
      subjectHu: json['name_hu'],
      slug: json['slug'] ?? '',
      totalAnswered:
          int.tryParse(json['total_answered']?.toString() ?? '0') ?? 0,
      correctAnswered:
          int.tryParse(json['correct_answered']?.toString() ?? '0') ?? 0,
      masteryPercent:
          int.tryParse(json['mastery_percent']?.toString() ?? '0') ?? 0,
    );
  }
}
