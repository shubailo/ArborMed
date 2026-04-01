import '../src/models/furniture_item.dart';

abstract class GameContract {
  // --- Catalog & Shop ---
  Future<List<FurnitureItem>> fetchCatalog();
  Future<bool> purchaseItem(String id);
  
  // --- Inventory & Room ---
  Future<List<FurnitureItem>> fetchInventory();
  Future<Map<String, String>> fetchRoomLayout();
  Future<void> saveRoomLayout(Map<String, String> layout);
  
  // --- State Getters (for UI consumption) ---
  List<FurnitureItem> get catalog;
  List<FurnitureItem> get ownedItems;
  Map<String, String> get currentLayout;
  bool get isLoading;
}
