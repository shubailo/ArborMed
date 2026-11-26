import 'study_metric.dart';

class ReadinessScore {
  final int overall;
  final List<ReadinessDetail> breakdown;

  ReadinessScore({required this.overall, required this.breakdown});

  factory ReadinessScore.fromJson(Map<String, dynamic> json) {
    final details = studyRows(json['breakdown'] ?? [], (row) {
      if (row['score'] == null) {
        throw const FormatException('Missing topic score');
      }
      return ReadinessDetail.fromJson(row);
    });
    if (details.isNotEmpty && json['overallReadiness'] == null) {
      throw const FormatException('Missing overall readiness');
    }
    return ReadinessScore(
      overall: studyNumber(json['overallReadiness'], max: 100).toInt(),
      breakdown: details,
    );
  }
}

class ReadinessDetail {
  final String topic;
  final String topicHu;
  String label(bool hu) =>
      hu && topicHu.isNotEmpty ? topicHu : (topic.isEmpty ? slug : topic);
  final String slug;
  final int score;
  final double retention;
  final int mastery;

  ReadinessDetail({
    required this.topic,
    this.topicHu = '',
    required this.slug,
    required this.score,
    required this.retention,
    required this.mastery,
  });

  factory ReadinessDetail.fromJson(Map<String, dynamic> json) {
    final metrics = json['metrics'];
    if (metrics != null && metrics is! Map) {
      throw const FormatException('Invalid readiness metrics');
    }
    return ReadinessDetail(
      topic: studyText(json['topic']),
      topicHu: studyText(json['topicHu']),
      slug: studyText(json['slug']),
      score: studyNumber(json['score'], max: 100).toInt(),
      retention: studyNumber(metrics?['retention'], max: 100),
      mastery: studyNumber(metrics?['mastery'], max: 100).toInt(),
    );
  }
}
