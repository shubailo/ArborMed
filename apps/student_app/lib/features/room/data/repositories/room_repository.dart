import 'package:student_app/core/network/api_client.dart';
import 'package:student_app/features/room/domain/entities/room_entities.dart';

abstract class RoomRepository {
  Future<RoomState> getRoomState();
  Future<void> placeItem(String slotKey, String shopItemId);
  Future<void> clearSlot(String slotKey);
}

class RoomRepositoryImpl implements RoomRepository {
  final ApiClient _apiClient;

  RoomRepositoryImpl(this._apiClient);

  @override
  Future<RoomState> getRoomState() async {
    final data = await _apiClient.getRoomState();
    return RoomState.fromJson(data);
  }

  @override
  Future<void> placeItem(String slotKey, String shopItemId) async {
    final result = await _apiClient.placeRoomItem(slotKey, shopItemId);
    if (result['success'] == false) {
      throw Exception(result['error'] ?? 'Failed to place item');
    }
  }

  @override
  Future<void> clearSlot(String slotKey) async {
    final result = await _apiClient.clearRoomSlot(slotKey);
    if (result['success'] == false) {
      throw Exception(result['error'] ?? 'Failed to clear slot');
    }
  }
}
