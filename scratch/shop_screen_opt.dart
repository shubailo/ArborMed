<<<<<<< SEARCH
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final catalog = provider.catalog;
    final coins = Provider.of<AuthProvider>(context).user?.coins ?? 0;
=======
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final catalog = provider.catalog;
    final coins = Provider.of<AuthProvider>(context).user?.coins ?? 0;

    // ⚡ Bolt: Pre-compute placed inventory items into a Set for O(1) lookups
    // This avoids O(N*M) scanning inside GridView.builder for every item
    final placedItemIds = provider.inventory
        .where((u) => u.isPlaced)
        .map((u) => u.itemId)
        .toSet();
>>>>>>> REPLACE
<<<<<<< SEARCH
                                  itemBuilder: (ctx, i) {
                                    final item = catalog[i];
                                    return _buildShopItemV2(item, coins);
                                  },
=======
                                  itemBuilder: (ctx, i) {
                                    final item = catalog[i];
                                    final isEquipped = item.isOwned && placedItemIds.contains(item.id);
                                    return _buildShopItemV2(item, coins, isEquipped);
                                  },
>>>>>>> REPLACE
<<<<<<< SEARCH
  Widget _buildShopItemV2(ShopItem item, int currentCoins) {
    final provider = Provider.of<ShopProvider>(context);
    final isEquipped = item.isOwned &&
        provider.inventory.any((u) => u.itemId == item.id && u.isPlaced);

    return Container(
=======
  Widget _buildShopItemV2(ShopItem item, int currentCoins, bool isEquipped) {
    return Container(
>>>>>>> REPLACE
