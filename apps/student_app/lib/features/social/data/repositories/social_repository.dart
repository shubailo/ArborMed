import '../datasources/social_remote_data_source.dart';
import '../models/clinic_directory_dto.dart';
import '../models/room_visit_dto.dart';

abstract class SocialRepository {
  Future<ClinicDirectoryDto> getClinicDirectory(String courseId);
  Future<RoomVisitDto> getRoomVisit(String userId, String courseId);
}

class SocialRepositoryImpl implements SocialRepository {
  final SocialRemoteDataSource remoteDataSource;

  SocialRepositoryImpl({required this.remoteDataSource});

  @override
  Future<ClinicDirectoryDto> getClinicDirectory(String courseId) async {
    return await remoteDataSource.getClinicDirectory(courseId);
  }

  @override
  Future<RoomVisitDto> getRoomVisit(String userId, String courseId) async {
    return await remoteDataSource.getRoomVisit(userId, courseId);
  }
}
