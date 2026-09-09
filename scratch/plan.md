1. Modify `apps/student_app/lib/features/shop/screens/shop_screen.dart` to optimize the `_buildShopItemV2` method. Currently, it scans `provider.inventory` linearly (O(N)) using `.any()` for every item rendered in the `GridView.builder`.
   - Before the `GridView.builder`, pre-compute a set of equipped item IDs (e.g., `final equippedItemIds = provider.inventory.where((u) => u.isPlaced).map((u) => u.itemId).toSet();`).
   - Pass this `Set<String>` (or `Set<int>` depending on `itemId` type) into `_buildShopItemV2`.
   - Update `_buildShopItemV2` to check `equippedItemIds.contains(item.id)` for O(1) lookup instead of `provider.inventory.any(...)`.
2. Run format and flutter tests (`flutter format` and `flutter test`).
3. Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.
4. Submit PR with Bolt headers.
