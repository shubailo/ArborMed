import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../avatar/bean_widget.dart';
import '../../theme/cozy_theme.dart';

class WardrobeSheet extends StatefulWidget {
  final bool isEmbedded;

  const WardrobeSheet({super.key, this.isEmbedded = false});

  @override
  createState() => _WardrobeSheetState();
}

class _WardrobeSheetState extends State<WardrobeSheet>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    // Fetch specifically 'skin' items
    // In MVP API, we might need a type filter.
    // Assuming backend returns ALL items, and we filter locally OR we update API.
    // Let's use the new filter params we added: theme/slot_type.
    // Wait, we added `slot_type` and `theme` but not `type`.
    // Let's assume for MVP we fetch all and filter in UI, or just fetch via slot_type if we browse by slot.
    // Better: We add `type` support to API or just iterate known avatar slots.

    // For now, let's just fetch all (default) and filter locally to avoid API changes mid-flight.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false).fetchCatalog();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        // Filter Catalog for Skins
        final skins = provider.catalog.where((i) => i.type == 'skin').toList();

        // Group by Slot
        final Map<String, List<ShopItem>> bySlot = {
          'skin_color': skins.where((i) => i.slotType == 'skin_color').toList(),
          'body': skins.where((i) => i.slotType == 'body').toList(),
          'head': skins.where((i) => i.slotType == 'head').toList(),
          'hand': skins.where((i) => i.slotType == 'hand').toList(),
        };

        return Container(
          height: widget.isEmbedded ? 500 : 600,
          decoration: BoxDecoration(
            color: CozyTheme.of(context).background,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              if (!widget.isEmbedded)
                // Header with Preview
                Container(
                  padding: const EdgeInsets.all(16),
                  color: CozyTheme.of(context).primary.withValues(alpha: 0.05),
                  child: Row(
                    children: [
                      Expanded(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("Wardrobe",
                              style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: CozyTheme.of(context).textPrimary)),
                          Text("Customize your look!",
                              style: TextStyle(
                                  color: CozyTheme.of(context).textSecondary)),
                        ],
                      )),
                      BeanWidget(config: provider.avatarConfig, size: 80),
                    ],
                  ),
                ),

              // Tabs
              TabBar(
                controller: _tabController,
                labelColor: CozyTheme.of(context).primary,
                unselectedLabelColor: CozyTheme.of(context).textSecondary,
                tabs: const [
                  Tab(icon: Icon(Icons.face), text: "Skin"),
                  Tab(icon: Icon(Icons.accessibility_new), text: "Body"),
                  Tab(icon: Icon(Icons.face_retouching_natural), text: "Head"),
                  Tab(icon: Icon(Icons.pan_tool), text: "Hand"),
                ],
              ),

              Expanded(
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildGrid(bySlot['skin_color'] ?? [], provider),
                    _buildGrid(bySlot['body'] ?? [], provider),
                    _buildGrid(bySlot['head'] ?? [], provider),
                    _buildGrid(bySlot['hand'] ?? [], provider),
                  ],
                ),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _buildGrid(List<ShopItem> items, ShopProvider provider) {
    if (items.isEmpty) {
      return Center(
          child: Text("No items found.",
              style: TextStyle(color: CozyTheme.of(context).textSecondary)));
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          childAspectRatio: 0.7,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10),
      itemCount: items.length,
      itemBuilder: (ctx, i) {
        final item = items[i];
        // Check local inventory if owned
        // A bit inefficient to scan inventory every frame but fine for MVP
        final userItem = provider.inventory.firstWhere(
            (u) => u.itemId == item.id,
            orElse: () => ShopUserItem(
                id: -1,
                itemId: -1,
                isPlaced: false,
                name: '',
                assetPath: '',
                slotType: ''));
        final isOwned = userItem.id != -1;
        final isEquipped = isOwned && userItem.isPlaced;

        return GestureDetector(
          onTap: () async {
            if (isOwned) {
              // Equip logic
              // If already equipped, could unequip?
              // For now, Equip.
              await provider.equipItem(
                  userItem.id, item.slotType, 0); // Room 0 = Avatar?
              // Note: Backend might need to handle Room 0 or NULL for Avatar items.
              // We will pass 0 for now.
            } else {
              // Buy logic
              bool success = await provider.buyItem(item.id, context);
              if (success) {
                // Auto Equip after buy?
                // We need to fetch the new UserItem ID properly.
                // For MVP, user clicks again to Equip.
              }
            }
          },
          child: Container(
            decoration: BoxDecoration(
              color: isEquipped
                  ? CozyTheme.of(context).success.withValues(alpha: 0.08)
                  : CozyTheme.of(context).paperWhite,
              border: Border.all(
                  color: isEquipped
                      ? CozyTheme.of(context).success
                      : CozyTheme.of(context)
                          .textSecondary
                          .withValues(alpha: 0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Expanded(
                    child: Icon(Icons.checkroom,
                        size: 40,
                        color: CozyTheme.of(context).primary)), // Placeholder
                Text(item.name,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        fontSize: 12,
                        color: CozyTheme.of(context).textPrimary)),
                const SizedBox(height: 4),
                if (!isOwned)
                  Text("${item.price} 🩺",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                          color: CozyTheme.of(context).primary)),
                if (isOwned && !isEquipped)
                  Text("OWNED",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: CozyTheme.of(context).textSecondary)),
                if (isEquipped)
                  Text("EQUIPPED",
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          color: CozyTheme.of(context).success)),
              ],
            ),
          ),
        );
      },
    );
  }
}
