## 2024-05-18 - [O(1) Hash Map for Equipped Items]
**Learning:** The UI was previously using List.any and List.firstWhere inside GridView.builder to check for equipped items, causing O(N) scans for every visible item.
**Action:** Whenever caching derived state in a ChangeNotifier, synchronous rebuilding (like within _loadInventoryFromLocal) alongside base state modifications is crucial.
