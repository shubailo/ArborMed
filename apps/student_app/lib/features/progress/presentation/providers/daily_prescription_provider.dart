import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/features/progress/presentation/providers/progress_providers.dart';

class DailyPrescription {
  final String date;
  final int targetQuestions;
  final int answeredToday;
  final double completionRate;

  DailyPrescription({
    required this.date,
    required this.targetQuestions,
    required this.answeredToday,
    required this.completionRate,
  });

  factory DailyPrescription.fromJson(Map<String, dynamic> json) {
    return DailyPrescription(
      date: json['date'] as String,
      targetQuestions: json['targetQuestions'] as int,
      answeredToday: json['answeredToday'] as int,
      completionRate: (json['completionRate'] as num).toDouble(),
    );
  }
}

final dailyPrescriptionProvider = FutureProvider<DailyPrescription>((ref) async {
  final userId = ref.watch(authStateProvider);
  final courseId = ref.watch(selectedCourseIdProvider);
  
  if (userId == null) {
    throw Exception('User not logged in');
  }

  final api = ref.read(apiClientProvider);
  final offset = DateTime.now().timeZoneOffset.inMinutes;

  final response = await api.get(
    '/analytics/user/$userId/course/$courseId/daily-prescription',
    queryParameters: {'timezoneOffset': offset.toString()},
  );

  return DailyPrescription.fromJson(response.data);
});
