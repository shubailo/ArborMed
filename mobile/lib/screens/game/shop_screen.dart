import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../services/auth_provider.dart';
import '../../services/audio_provider.dart';
import '../../widgets/cozy/cozy_tile.dart';
import '../../widgets/cozy/cozy_room_renderer.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    Provider.of<ShopProvider>(context, listen: false).fetchCatalog();
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ShopProvider>(context);
    final catalog = provider.catalog;
    final coins = Provider.of<AuthProvider>(context).user?.coins ?? 0;

    return Material(
      type: MaterialType.transparency,
      child: Stack(
        children: [
          // 1. Background with icons
          // 1. Background: Room Renderer (The "Clinic")
          Positioned.fill(
            child: GestureDetector(
               onTap: () {
                 // Tap outside to maybe close shop? For now just absorb tap
               },
               child: Container(
                 color: Colors.black, // Fallback
                 child: CozyRoomRenderer(
                   room: provider.currentRoom,
                   equippedItems: provider.equippedItemsAsShopItems,
                 ),
               ),
            ),
          ),
          
          // Gradient Overlay to make text pop if needed?
          // Positioned.fill(child: Container(color: Colors.black12)),

          // 2. The Clipboard Shop Card
          Center(
            child: Container(
              width: 600,
              // Make it shorter or push it down to reveal room?
              // Let's use a bottom sheet style or just a smaller centered modal
              height: MediaQuery.of(context).size.height * 0.55, 
              margin: const EdgeInsets.only(top: 200, left: 20, right: 20, bottom: 20), // Push down
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5), // paperWhite
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFF8D6E63), width: 4), // Brown clipboard border
                boxShadow: const [
                  BoxShadow(color: Colors.black26, blurRadius: 20, offset: Offset(0, 10))
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  children: [
                    // Clipboard Top Handle
                    Container(
                      width: 100,
                      height: 12,
                      margin: const EdgeInsets.only(top: 8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8D6E63),
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Opacity(
                            opacity: 0.0,
                            child: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF8D6E63)),
                          ),
                          const Text(
                            "MEDICAL SUPPLY",
                            style: TextStyle(
                              fontFamily: 'Quicksand',
                              fontSize: 24,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF5D4037),
                              letterSpacing: 1.5,
                            ),
                          ),
                          Row(
                            children: [
                              Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 22, height: 22),
                              const SizedBox(width: 4),
                              Text('$coins', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5D4037))),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Grid
                    Expanded(
                      child: provider.isLoading
                          ? const Center(child: CircularProgressIndicator(color: Color(0xFF8CAA8C)))
                          : provider.errorMessage != null
                              ? _buildErrorView(provider)
                              : GridView.builder(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.85,
                                    crossAxisSpacing: 16,
                                    mainAxisSpacing: 16,
                                  ),
                                  itemCount: catalog.length,
                                  itemBuilder: (ctx, i) {
                                    final item = catalog[i];
                                    return _buildShopItem(item, coins);
                                  },
                                ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItem(ShopItem item, int currentCoins) {
    final provider = Provider.of<ShopProvider>(context); // Listen to changes
    final isEquipped = item.isOwned && provider.inventory.any((u) => u.itemId == item.id && u.isPlaced);

    return CozyTile(
      onTap: () {}, // Handled by button below or whole tile? Let's just use tile for purchase for now or keep button
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Expanded(
              child: item.assetPath.isNotEmpty 
                ? Image.asset(item.assetPath, fit: BoxFit.contain)
                : Icon(Icons.medical_services_outlined, size: 40, color: Colors.brown[300]),
            ),
            const SizedBox(height: 8),
            Text(
              item.name.toUpperCase(),
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13, color: Color(0xFF5D4037)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.type.replaceAll('_', ' ').toUpperCase(),
              style: const TextStyle(fontSize: 10, color: Color(0xFF8CAA8C), fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: item.isOwned 
                    ? (isEquipped ? const Color(0xFF5D4037) : const Color(0xFF8CAA8C)) // Brown if equipped
                    : (currentCoins >= item.price ? const Color(0xFFE57373) : Colors.grey[300]), // Red/Pink for buy
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(
                  item.isOwned 
                    ? (isEquipped ? 'EQUIPPED' : 'USE') 
                    : '${item.price} 🩺', 
                  style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)
                ),
                onPressed: () async {
                  final audio = Provider.of<AudioProvider>(context, listen: false);
                  final provider = Provider.of<ShopProvider>(context, listen: false);

                  // A) Logic: OWNED -> EQUIP
                  if (item.isOwned) {
                    audio.playSfx('click');
                    // Find the userItemId for this item (hacky lookup for MVP)
                    final userItem = provider.inventory.firstWhere((u) => u.itemId == item.id);
                    await provider.equipItem(userItem.id, item.slotType, 1); // Room 1 hardcoded
                    return;
                  }

                  // B) Logic: NOT OWNED -> BUY
                  if (currentCoins < item.price) {
                    audio.playSfx('click'); 
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: const Text('Not enough stethoscopes!'), backgroundColor: Colors.red[300]));
                    return;
                  }

                  // Buy
                  bool success = await provider.buyItem(item.id, context);
                  if (!mounted) return;
                  if (success) {
                    audio.playSfx('success');
                    ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Purchased ${item.name}!'), backgroundColor: const Color(0xFF8CAA8C)));
                    // Auto-equip after buy?
                    // await provider.equipItem(...)
                  } else {
                     audio.playSfx('click');
                  }
                },
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildErrorView(ShopProvider provider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text('Error: ${provider.errorMessage}',
              style: const TextStyle(color: Colors.red),
              textAlign: TextAlign.center),
          const SizedBox(height: 10),
          ElevatedButton(
            child: const Text('Retry'),
            onPressed: () => provider.fetchCatalog(),
          )
        ],
      ),
    );
  }
}
