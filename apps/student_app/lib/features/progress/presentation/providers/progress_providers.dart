import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import '../../domain/entities/progress.dart';
import '../../domain/repositories/progress_repository.dart';
import '../../data/repositories/progress_repository_impl.dart';

final progressRepositoryProvider = Provider<ProgressRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProgressRepositoryImpl(apiClient);
});

// Match the courseId from courses-and-topics.json
final selectedCourseIdProvider = StateProvider<String>((ref) => 'hema');

final courseProgressProvider = FutureProvider<CourseProgress>((ref) async {
  final userId = ref.watch(authStateProvider);
  final courseId = ref.watch(selectedCourseIdProvider);
  
  if (userId == null) {
     throw Exception('User not logged in');
  }
  
  final repo = ref.read(progressRepositoryProvider);
  return await repo.getUserCourseProgress(userId, courseId);
});
