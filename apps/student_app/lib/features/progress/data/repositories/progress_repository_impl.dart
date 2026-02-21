import 'package:student_app/core/network/api_client.dart';
import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';

class ProgressRepositoryImpl implements ProgressRepository {
  final ApiClient apiClient;

  ProgressRepositoryImpl(this.apiClient);

  @override
  Future<CourseProgress> getUserCourseProgress(String userId, String courseId) async {
    final json = await apiClient.getUserCourseProgress(userId, courseId);
    return _mapCourseProgress(json);
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
}
