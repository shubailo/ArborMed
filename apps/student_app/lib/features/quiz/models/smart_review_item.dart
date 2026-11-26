import '../../analytics/models/study_metric.dart';

class SmartReviewItem {
  final String topic;
  final String topicHu;
  String label(bool hu) =>
      hu && topicHu.isNotEmpty ? topicHu : (topic.isEmpty ? slug : topic);
  final String slug;
  final double retention;
  final double? daysSince;
  final int mastery;

  SmartReviewItem({
    required this.topic,
    this.topicHu = '',
    required this.slug,
    required this.retention,
    required this.daysSince,
    required this.mastery,
  });

  factory SmartReviewItem.fromJson(Map<String, dynamic> json) {
    if (json['retention'] == null) {
      throw const FormatException('Missing retention');
    }
    return SmartReviewItem(
      topic: studyText(json['topic']),
      topicHu: studyText(json['topicHu']),
      slug: studyText(json['slug']),
      retention: studyNumber(json['retention'], max: 100),
      daysSince:
          json['daysSince'] == null ? null : studyNumber(json['daysSince']),
      mastery: studyNumber(json['mastery'], max: 100).toInt(),
    );
  }
}
