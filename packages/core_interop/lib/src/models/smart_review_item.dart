class SmartReviewItem {
  final String topic;
  final String slug;
  final double retention;
  final double daysSince;
  final int mastery;

  SmartReviewItem({
    required this.topic,
    required this.slug,
    required this.retention,
    required this.daysSince,
    required this.mastery,
  });

  factory SmartReviewItem.fromJson(Map<String, dynamic> json) {
    return SmartReviewItem(
      topic: json['topic'] ?? '',
      slug: json['slug'] ?? '',
      retention: (json['retention'] ?? 0).toDouble(),
      daysSince: (json['daysSince'] ?? 0).toDouble(),
      mastery: (json['mastery'] ?? 0).toInt(),
    );
  }
}
