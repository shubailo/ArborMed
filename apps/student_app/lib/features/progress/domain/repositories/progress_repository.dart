import '../entities/progress.dart';

abstract class ProgressRepository {
  Future<CourseProgress> getUserCourseProgress(String userId, String courseId);
}
