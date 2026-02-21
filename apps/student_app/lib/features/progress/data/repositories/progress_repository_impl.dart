import 'package:student_app/core/network/api_client.dart';
import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ApiClient apiClient;

  ProgressRepositoryImpl(this.apiClient);

  @override
  Future<CourseProgress> getUserCourseProgress(
    String userId,
    String courseId,
  ) async {
    final json = await apiClient.getUserCourseProgress(userId, courseId);
    return _mapCourseProgress(json);
  }

  @override
  Future<ActivityTrends> getActivityTrends(
    String userId,
    String courseId,
    String range,
  ) async {
    final json = await apiClient.fetchActivityTrends(userId, courseId, range);
    return _mapActivityTrends(json);
  }

  CourseProgress _mapCourseProgress(Map<String, dynamic> json) {
    return CourseProgress(
      courseId: json['courseId'],
      userId: json['userId'],
      topics: (json['topics'] as List).map((topicJson) {
        return TopicProgress(
          topicId: topicJson['topicId'],
          topicName: topicJson['topicName'],
          overallMastery: (topicJson['overallMastery'] as num).toInt(),
          masteryBadge: topicJson['masteryBadge'],
          bloomLevels: (topicJson['bloomLevels'] as List).map((bloomJson) {
            return BloomLevelState(
              bloomLevel: bloomJson['bloomLevel'],
              masteryScore: (bloomJson['masteryScore'] as num).toInt(),
              achieved: bloomJson['achieved'],
            );
          }).toList(),
        );
      }).toList(),
    );
  }

  ActivityTrends _mapActivityTrends(Map<String, dynamic> json) {
    return ActivityTrends(
      overallAccuracy: (json['overallAccuracy'] as num).toDouble(),
      days: (json['days'] as List).map((dayJson) {
        return ActivityTrendDay(
          date: dayJson['date'],
          questionCount: (dayJson['questionCount'] as num).toInt(),
          correctRate: (dayJson['correctRate'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}
