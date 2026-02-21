class ReadinessScore {
  final int overall;
  final List<ReadinessDetail> breakdown;

  ReadinessScore({required this.overall, required this.breakdown});

  factory ReadinessScore.fromJson(Map<String, dynamic> json) {
    return ReadinessScore(
      overall: (json['overallReadiness'] ?? 0).toInt(),
      breakdown: (json['breakdown'] as List?)
              ?.map((e) => ReadinessDetail.fromJson(e))
              .toList() ??
          [],
    );
  }
}

class ReadinessDetail {
  final String topic;
  final String slug;
  final int score;
  final double retention;
  final int mastery;

  ReadinessDetail({
    required this.topic,
    required this.slug,
    required this.score,
    required this.retention,
    required this.mastery,
  });

  factory ReadinessDetail.fromJson(Map<String, dynamic> json) {
    return ReadinessDetail(
      topic: json['topic'] ?? '',
      slug: json['slug'] ?? '',
      score: (json['score'] ?? 0).toInt(),
      retention: (json['metrics']?['retention'] ?? 0).toDouble(),
      mastery: (json['metrics']?['mastery'] ?? 0).toInt(),
    );
  }
}
