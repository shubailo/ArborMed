1. **Modify `lib/features/shop/providers/shop_provider.dart` to add O(1) Cache for Equipped Items**:
   - Apply the following diff to `lib/features/shop/providers/shop_provider.dart`:
```
<<<<<<< SEARCH
  List<ShopUserItem> _inventory = [];
  List<ShopUserItem> _visitedInventory = [];
  bool _isLoading = false;
=======
  List<ShopUserItem> _inventory = [];
  final Map<int, ShopUserItem> _equippedItemsMap = {};
  List<ShopUserItem> _visitedInventory = [];
  bool _isLoading = false;
>>>>>>> REPLACE
```
```
<<<<<<< SEARCH
  List<ShopItem> get catalog => _catalog;
  List<ShopUserItem> get inventory => _inventory;
  bool get isLoading => _isLoading;
=======
  List<ShopItem> get catalog => _catalog;
  List<ShopUserItem> get inventory => _inventory;
  Map<int, ShopUserItem> get equippedItemsMap => _equippedItemsMap;
  bool get isLoading => _isLoading;
>>>>>>> REPLACE
```
```
<<<<<<< SEARCH
  Future<void> _loadInventoryFromLocal(int userId, {bool notify = true}) async {
    final locals = await (_db.select(
      _db.userItems,
    )..where((t) => t.userId.equals(userId))).get();

    _inventory = [];
    for (var l in locals) {
      final itemDetails = await (_db.select(
        _db.items,
      )..where((t) => t.serverId.equals(l.itemId!))).getSingleOrNull();
      _inventory.add(
        ShopUserItem(
          id: l.id, // LOCAL DB ID
          serverId: l.serverId,
          itemId: l.itemId ?? 0,
          isPlaced: l.isPlaced,
          placedAtSlot: l.slot,
          name: itemDetails?.name ?? 'Unknown',
          assetPath: itemDetails?.assetPath ?? '',
          slotType: itemDetails?.slotType ?? '',
          x: l.xPos,
          y: l.yPos,
          roomId: l.roomId,
        ),
      );
    }
    if (notify) notifyListeners();
  }
=======
  Future<void> _loadInventoryFromLocal(int userId, {bool notify = true}) async {
    final locals = await (_db.select(
      _db.userItems,
    )..where((t) => t.userId.equals(userId))).get();

    _inventory = [];
    _equippedItemsMap.clear();
    for (var l in locals) {
      final itemDetails = await (_db.select(
        _db.items,
      )..where((t) => t.serverId.equals(l.itemId!))).getSingleOrNull();
      final item = ShopUserItem(
        id: l.id, // LOCAL DB ID
        serverId: l.serverId,
        itemId: l.itemId ?? 0,
        isPlaced: l.isPlaced,
        placedAtSlot: l.slot,
        name: itemDetails?.name ?? 'Unknown',
        assetPath: itemDetails?.assetPath ?? '',
        slotType: itemDetails?.slotType ?? '',
        x: l.xPos,
        y: l.yPos,
        roomId: l.roomId,
      );
      _inventory.add(item);
      if (item.isPlaced) {
        _equippedItemsMap[item.itemId] = item;
      }
    }
    if (notify) notifyListeners();
  }
>>>>>>> REPLACE
```
```
<<<<<<< SEARCH
  void resetState() {
    _catalog = [];
    _inventory = [];
    _visitedInventory = [];
=======
  void resetState() {
    _catalog = [];
    _inventory = [];
    _equippedItemsMap.clear();
    _visitedInventory = [];
>>>>>>> REPLACE
```
```
<<<<<<< SEARCH
      // 2. Local Cache Update (Insertion)
      if (userId != null) {
        await _db
            .into(_db.userItems)
            .insert(
              UserItemsCompanion.insert(
                userId: Value(userId),
                serverId: Value(newUserItemId),
                itemId: Value(itemId),
                isPlaced: const Value(false),
              ),
            );
        await _loadInventoryFromLocal(userId, notify: false);
=======
      // 2. Local Cache Update (Insertion)
      // Note: _loadInventoryFromLocal synchronously rebuilds the O(1) equipped cache
      if (userId != null) {
        await _db
            .into(_db.userItems)
            .insert(
              UserItemsCompanion.insert(
                userId: Value(userId),
                serverId: Value(newUserItemId),
                itemId: Value(itemId),
                isPlaced: const Value(false),
              ),
            );
        await _loadInventoryFromLocal(userId, notify: false);
>>>>>>> REPLACE
```
```
<<<<<<< SEARCH
        // Equip this one
        await (_db.update(
          _db.userItems,
        )..where((t) => t.id.equals(userItemId))).write(
          UserItemsCompanion(
            isPlaced: const Value(true),
            slot: Value(slot),
            xPos: Value(x ?? 0),
            yPos: Value(y ?? 0),
            roomId: Value(roomId),
          ),
        );
      });

      // Refresh memory state
      await _loadInventoryFromLocal(userId, notify: false);
=======
        // Equip this one
        await (_db.update(
          _db.userItems,
        )..where((t) => t.id.equals(userItemId))).write(
          UserItemsCompanion(
            isPlaced: const Value(true),
            slot: Value(slot),
            xPos: Value(x ?? 0),
            yPos: Value(y ?? 0),
            roomId: Value(roomId),
          ),
        );
      });

      // Refresh memory state
      // Note: _loadInventoryFromLocal synchronously rebuilds the O(1) equipped cache
      await _loadInventoryFromLocal(userId, notify: false);
>>>>>>> REPLACE
```
```
<<<<<<< SEARCH
      // 1. Local Update
      await (_db.update(
        _db.userItems,
      )..where((t) => t.id.equals(userItemId))).write(
        const UserItemsCompanion(isPlaced: Value(false), roomId: Value(null)),
      );

      // Refresh memory state
      await _loadInventoryFromLocal(userId, notify: false);
=======
      // 1. Local Update
      await (_db.update(
        _db.userItems,
      )..where((t) => t.id.equals(userItemId))).write(
        const UserItemsCompanion(isPlaced: Value(false), roomId: Value(null)),
      );

      // Refresh memory state
      // Note: _loadInventoryFromLocal synchronously rebuilds the O(1) equipped cache
      await _loadInventoryFromLocal(userId, notify: false);
>>>>>>> REPLACE
```

2. **Refactor `lib/features/shop/screens/shop_screen.dart` to use O(1) Lookups**:
   - Apply the following diff:
```
<<<<<<< SEARCH
    final provider = Provider.of<ShopProvider>(context);
    final isEquipped = item.isOwned &&
        provider.inventory.any((u) => u.itemId == item.id && u.isPlaced);

    return Container(
=======
    final provider = Provider.of<ShopProvider>(context);
    // ⚡ Bolt: Replace O(N) array scan (.any) in GridView.builder with O(1) Hash Map lookup
    // 💡 What: Use pre-computed equippedItemsMap instead of iterating through the inventory array.
    // 🎯 Why: Prevents UI stutters during scrolling by avoiding linear scans inside builder methods.
    // 📊 Impact: Changes O(N) lookup to O(1), significantly reducing build time per item.
    final isEquipped = item.isOwned &&
        provider.equippedItemsMap.containsKey(item.id);

    return Container(
>>>>>>> REPLACE
```

3. **Refactor `lib/features/shop/widgets/contextual_shop_sheet.dart` to use O(1) Lookups**:
   - Apply the following diff:
```
<<<<<<< SEARCH
    final isPlaced = provider.inventory
        .any((ui) => ui.itemId == _selectedItem?.id && ui.isPlaced);
    final placedUserItem = isPlaced
        ? provider.inventory
            .firstWhere((ui) => ui.itemId == _selectedItem?.id && ui.isPlaced)
        : null;

    return Column(
=======
    // ⚡ Bolt: Replace O(N) array scans (.any and .firstWhere) with O(1) Hash Map lookup
    // 💡 What: Fetch placed item directly from equippedItemsMap cache.
    // 🎯 Why: Removes redundant array iterations in the build method.
    // 📊 Impact: Improves rendering performance by doing a single O(1) lookup instead of two O(N) scans.
    final placedUserItem = provider.equippedItemsMap[_selectedItem?.id];
    final isPlaced = placedUserItem != null;

    return Column(
>>>>>>> REPLACE
```

4. **Add Bolt Comments**:
   - Create directory and append to `.jules/bolt.md`:
   - Run `mkdir -p apps/student_app/.jules`
   - Run `cat << 'INNER_EOF' >> apps/student_app/.jules/bolt.md
## 2024-05-18 - [O(1) Hash Map for Equipped Items]
**Learning:** The UI was previously using List.any and List.firstWhere inside GridView.builder to check for equipped items, causing O(N) scans for every visible item.
**Action:** Whenever caching derived state in a ChangeNotifier, synchronous rebuilding (like within _loadInventoryFromLocal) alongside base state modifications is crucial.
INNER_EOF`

5. **Verify file creation**:
   - Run `grep -C 5 'O(1) Hash Map' apps/student_app/.jules/bolt.md`

6. **Stage file**:
   - Run `git add apps/student_app/.jules/bolt.md`

7. **Run tests**:
   - Run `cd apps/student_app && flutter test`

8. **Complete Pre-commit Steps**:
   - Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.

9. **Submit PR**:
   - Submit the PR with branch `bolt-performance-equipped-map`, title "⚡ Bolt: [performance improvement]", and description containing What, Why, Impact, and Measurement.
