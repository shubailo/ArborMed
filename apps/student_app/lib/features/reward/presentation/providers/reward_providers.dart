import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/study/providers/study_providers.dart';
import 'package:student_app/features/reward/domain/entities/reward_entities.dart';
import 'package:student_app/features/reward/data/repositories/reward_repository.dart';

final rewardRepositoryProvider = Provider<RewardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return RewardRepositoryImpl(apiClient);
});

final rewardBalanceProvider = StateProvider<int>((ref) => 0);

final rewardInventoryProvider = FutureProvider<List<UserInventoryItem>>((
  ref,
) async {
  final userId = ref.watch(authStateProvider);
  if (userId == null) return [];

  final repo = ref.read(rewardRepositoryProvider);
  return await repo.getInventory(userId);
});

final rewardBalanceFetcherProvider = FutureProvider<int>((ref) async {
  final userId = ref.watch(authStateProvider);
  if (userId == null) return 0;

  final repo = ref.read(rewardRepositoryProvider);
  try {
    final balance = await repo.getBalance(userId);
    ref.read(rewardBalanceProvider.notifier).state = balance;
    return balance;
  } catch (e) {
    // Silent fail for initial fetch, the UI will show 0 or handle error
    return 0;
  }
});

final shopItemsProvider = FutureProvider<List<ShopItem>>((ref) async {
  final repo = ref.read(rewardRepositoryProvider);
  return await repo.getShopItems();
});

class RewardController {
  final Ref ref;
  RewardController(this.ref);

  Future<void> purchaseItem(String shopItemId) async {
    final repo = ref.read(rewardRepositoryProvider);
    try {
      final newBalance = await repo.purchaseItem(shopItemId);
      ref.read(rewardBalanceProvider.notifier).state = newBalance;
      // Refresh inventory after purchase to update "Owned (xN)"
      ref.invalidate(rewardInventoryProvider);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> syncBalance() async {
    final userId = ref.read(authStateProvider);
    if (userId == null) return;
    final repo = ref.read(rewardRepositoryProvider);
    try {
      final balance = await repo.getBalance(userId);
      ref.read(rewardBalanceProvider.notifier).state = balance;
    } catch (e) {
      // Log error or notify UI
    }
  }
}

final rewardControllerProvider = Provider<RewardController>((ref) {
  return RewardController(ref);
});
