class Topic {
  final int id;
  final int? parentId;
  final String slug;
  final String nameEn;
  final String nameHu;
  final int? questionCount;

  const Topic({
    required this.id,
    this.parentId,
    required this.slug,
    required this.nameEn,
    required this.nameHu,
    this.questionCount,
  });

  static int _integer(Object? value, {required int minimum, int? maximum}) {
    final n = value is int
        ? value
        : value is String && RegExp(r'^\d+$').hasMatch(value.trim())
            ? int.tryParse(value.trim())
            : null;
    if (n == null || n < minimum || (maximum != null && n > maximum)) {
      throw const FormatException('Invalid topic integer');
    }
    return n;
  }

  factory Topic.fromJson(Map<String, dynamic> json) {
    return Topic(
      id: _integer(json['id'], minimum: 1, maximum: 2147483647),
      parentId: json['parent_id'] == null
          ? null
          : _integer(json['parent_id'], minimum: 1, maximum: 2147483647),
      slug: json['slug'] as String? ?? '',
      nameEn: (json['name_en'] ?? json['name']) as String? ?? '',
      nameHu: json['name_hu'] as String? ?? '',
      questionCount: json['question_count'] == null
          ? null
          : _integer(json['question_count'], minimum: 0),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'parent_id': parentId,
        'slug': slug,
        'name_en': nameEn,
        'name_hu': nameHu,
        'question_count': questionCount,
      };
}
