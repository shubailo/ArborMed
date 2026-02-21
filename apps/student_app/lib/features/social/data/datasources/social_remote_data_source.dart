import 'package:student_app/core/network/api_client.dart';
import '../models/clinic_directory_dto.dart';
import '../models/room_visit_dto.dart';

abstract class SocialRemoteDataSource {
  Future<ClinicDirectoryDto> getClinicDirectory(String courseId);
  Future<RoomVisitDto> getRoomVisit(String userId, String courseId);
}

class SocialRemoteDataSourceImpl implements SocialRemoteDataSource {
  final ApiClient apiClient;

  SocialRemoteDataSourceImpl({required this.apiClient});

  @override
  Future<ClinicDirectoryDto> getClinicDirectory(String courseId) async {
    final response = await apiClient.get('/social/course/$courseId/clinic-directory');
    final Map<String, dynamic> jsonResponse = response.data;
    if (jsonResponse['success'] == true) {
      return ClinicDirectoryDto.fromJson(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to fetch clinic directory');
    }
  }

  @override
  Future<RoomVisitDto> getRoomVisit(String userId, String courseId) async {
    final response = await apiClient.get('/social/room/$userId/preview?courseId=$courseId');
    final Map<String, dynamic> jsonResponse = response.data;
    if (jsonResponse['success'] == true) {
      return RoomVisitDto.fromJson(jsonResponse['data']);
    } else {
      throw Exception(jsonResponse['message'] ?? 'Failed to visit room');
    }
  }
}
