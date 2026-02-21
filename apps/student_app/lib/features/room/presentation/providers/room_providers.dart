import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';
import 'package:student_app/features/room/data/repositories/room_repository.dart';
import 'package:student_app/features/room/domain/entities/room_entities.dart';

final roomRepositoryProvider = Provider<RoomRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return RoomRepositoryImpl(api);
});

final roomStateProvider = FutureProvider<RoomState>((ref) async {
  final repo = ref.watch(roomRepositoryProvider);
  return repo.getRoomState();
});

class RoomNotifier extends StateNotifier<AsyncValue<RoomState>> {
  final RoomRepository _repository;
  final Ref _ref;

  RoomNotifier(this._repository, this._ref) : super(const AsyncLoading()) {
    _loadRoom();
  }

  Future<void> _loadRoom() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _repository.getRoomState());
  }

  Future<void> placeItem(String slotKey, String shopItemId) async {
    try {
      // 1. API Call
      await _repository.placeItem(slotKey, shopItemId);
      
      // 2. Refresh Room State
      await _loadRoom();
      
      // 3. Refresh Inventory (Usage Mode: quantity decreased)
      _ref.invalidate(rewardInventoryProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<void> clearSlot(String slotKey) async {
    try {
      await _repository.clearSlot(slotKey);
      await _loadRoom();
      
      // Usage Mode: quantity increased
      _ref.invalidate(rewardInventoryProvider);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }
}

final roomControllerProvider =
    StateNotifierProvider<RoomNotifier, AsyncValue<RoomState>>((ref) {
      final repo = ref.watch(roomRepositoryProvider);
      return RoomNotifier(repo, ref);
    });
