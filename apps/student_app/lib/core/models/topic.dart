class Topic {
  final int id;
  final int? parentId;
  final String slug;
  final String nameEn;
  final String nameHu;
  final int? questionCount;

  Topic({
    required this.id,
    this.parentId,
    required this.slug,
    required this.nameEn,
    required this.nameHu,
    this.questionCount,
  });

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: json['id'],
      parentId: json['parent_id'],
      slug: json['slug'] ?? '',
      nameEn: json['name_en'] ?? '',
      nameHu: json['name_hu'] ?? '',
      questionCount: json['question_count'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'parent_id': parentId,
      'slug': slug,
      'name_en': nameEn,
      'name_hu': nameHu,
      'question_count': questionCount,
    };
  }
}
