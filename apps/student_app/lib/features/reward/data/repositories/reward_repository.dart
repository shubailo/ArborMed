import 'package:student_app/features/reward/domain/entities/reward_entities.dart';
import 'package:student_app/core/network/api_client.dart';

abstract class RewardRepository {
  Future<int> getBalance(String userId);
  Future<List<ShopItem>> getShopItems();
  Future<List<UserInventoryItem>> getInventory(String userId);
  Future<int> purchaseItem(String shopItemId);
}

class RewardRepositoryImpl implements RewardRepository {
  final ApiClient apiClient;

  RewardRepositoryImpl(this.apiClient);

  @override
  Future<int> getBalance(String userId) async {
    return await apiClient.getRewardBalance(userId);
  }

  @override
  Future<List<ShopItem>> getShopItems() async {
    final itemsJson = await apiClient.getShopItems();
    return itemsJson.map((json) => ShopItem.fromJson(json)).toList();
  }

  @override
  Future<List<UserInventoryItem>> getInventory(String userId) async {
    final inventoryJson = await apiClient.getUserInventory();
    return inventoryJson
        .map((json) => UserInventoryItem.fromJson(json))
        .toList();
  }

  @override
  Future<int> purchaseItem(String shopItemId) async {
    final result = await apiClient.purchaseItem(shopItemId);
    if (result['success'] == false) {
      throw Exception(
        result['errorCode'] ?? result['error'] ?? 'Purchase failed',
      );
    }
    return result['balance'] as int;
  }
}
