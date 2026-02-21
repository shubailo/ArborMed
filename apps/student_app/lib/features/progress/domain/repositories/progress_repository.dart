import '../entities/progress.dart';

abstract class ProgressRepository {
  Future<CourseProgress> getUserCourseProgress(String userId, String courseId);
  Future<ActivityTrends> getActivityTrends(
    String userId,
    String courseId,
    String range,
  );
}
