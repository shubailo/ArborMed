import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/social/data/datasources/social_remote_data_source.dart';
import 'package:student_app/features/social/data/repositories/social_repository.dart';
import 'package:student_app/features/social/data/models/clinic_directory_dto.dart';
import 'package:student_app/features/social/data/models/room_visit_dto.dart';
import 'package:student_app/features/study/providers/study_providers.dart';


// Providers
final socialRemoteDataSourceProvider = Provider<SocialRemoteDataSource>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return SocialRemoteDataSourceImpl(apiClient: apiClient);
});

final socialRepositoryProvider = Provider<SocialRepository>((ref) {
  final remoteDataSource = ref.watch(socialRemoteDataSourceProvider);
  return SocialRepositoryImpl(remoteDataSource: remoteDataSource);
});

// For Clinic Directory (Needs courseId - assume we get it from an active course provider in the real app, or pass it via family)
final clinicDirectoryProvider =
    FutureProvider.family<ClinicDirectoryDto, String>((ref, courseId) async {
      final repository = ref.watch(socialRepositoryProvider);
      return repository.getClinicDirectory(courseId);
    });

// For Visiting a Room
final visitRoomProvider =
    FutureProvider.family<RoomVisitDto, ({String userId, String courseId})>((
      ref,
      args,
    ) async {
      final repository = ref.watch(socialRepositoryProvider);
      return repository.getRoomVisit(args.userId, args.courseId);
    });
