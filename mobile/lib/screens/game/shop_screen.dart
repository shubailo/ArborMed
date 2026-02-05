import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../services/auth_provider.dart';
import '../../services/audio_provider.dart';
import '../../widgets/cozy/cozy_room_renderer.dart';
import '../../widgets/cozy/cozy_button.dart';
import '../../widgets/cozy/paper_texture.dart';

class ShopScreen extends StatefulWidget {
  const ShopScreen({super.key});

  @override
  State<ShopScreen> createState() => _ShopScreenState();
}

class _ShopScreenState extends State<ShopScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false).fetchCatalog();
      Provider.of<ShopProvider>(context, listen: false).fetchInventory();
    });
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
          // 🏡 Background: Room Renderer (The "Clinic")
          Positioned.fill(
            child: CozyRoomRenderer(
              room: provider.currentRoom,
              equippedItems: provider.equippedItemsAsShopItems,
            ),
          ),
          
          // 🌚 Soft Dimmer
          Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3))),

          // 📋 The Clipboard Shop Card
          Center(
            child: Container(
              width: 500,
              height: MediaQuery.of(context).size.height * 0.7, 
              margin: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFDF5),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(color: const Color(0xFF5D4037), width: 6),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 40, offset: const Offset(0, 20))
                ],
              ),
              child: PaperTexture(
                opacity: 0.05,
                child: Column(
                  children: [
                    // Clipboard Header Clip
                    Container(
                      width: 140,
                      height: 40,
                      margin: const EdgeInsets.only(top: -20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF5D4037),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                           BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4, offset: const Offset(0, 2))
                        ],
                      ),
                      child: Center(
                        child: Container(
                          width: 80, 
                          height: 6, 
                          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(3)),
                        ),
                      ),
                    ),

                    // Header
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "MEDICAL SUPPLY",
                                  style: GoogleFonts.figtree(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                    color: const Color(0xFF5D4037),
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                Text(
                                  "DISPATCH TERMINAL",
                                  style: GoogleFonts.figtree(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF8CAA8C),
                                    letterSpacing: 2.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF5D4037).withValues(alpha: 0.05),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              children: [
                                Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 22, height: 22),
                                const SizedBox(width: 8),
                                Text(
                                  '$coins', 
                                  style: GoogleFonts.figtree(
                                    fontSize: 18, 
                                    fontWeight: FontWeight.w900, 
                                    color: const Color(0xFF5D4037)
                                  )
                                ),
                              ],
                            ),
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
                                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.72,
                                    crossAxisSpacing: 20,
                                    mainAxisSpacing: 20,
                                  ),
                                  itemCount: catalog.length,
                                  itemBuilder: (ctx, i) {
                                    final item = catalog[i];
                                    return _buildShopItemV2(item, coins);
                                  },
                                ),
                    ),
                    
                    // Footer Close
                    Padding(
                       padding: const EdgeInsets.all(20),
                       child: CozyButton(
                         label: "EXIT STORAGE",
                         variant: CozyButtonVariant.ghost,
                         onPressed: () => Navigator.pop(context),
                       ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildShopItemV2(ShopItem item, int currentCoins) {
    final provider = Provider.of<ShopProvider>(context);
    final isEquipped = item.isOwned && provider.inventory.any((u) => u.itemId == item.id && u.isPlaced);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF5D4037).withValues(alpha: 0.08), width: 2),
        boxShadow: [
          BoxShadow(color: const Color(0xFF5D4037).withValues(alpha: 0.04), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        children: [
          // Item Image
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Hero(
                tag: 'shop_${item.id}',
                child: item.assetPath.isNotEmpty 
                  ? Image.asset(item.assetPath, fit: BoxFit.contain)
                  : Icon(Icons.medical_services_outlined, size: 40, color: Colors.brown[100]),
              ),
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Column(
              children: [
                Text(
                  item.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.figtree(fontWeight: FontWeight.w900, fontSize: 13, color: const Color(0xFF5D4037)),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 10),
                CozyButton(
                  label: item.isOwned 
                    ? (isEquipped ? 'EQUIPPED' : 'USE') 
                    : '${item.price} ⭐',
                  variant: isEquipped ? CozyButtonVariant.ghost : CozyButtonVariant.primary,
                  onPressed: () async {
                    final audio = Provider.of<AudioProvider>(context, listen: false);
                    final provider = Provider.of<ShopProvider>(context, listen: false);

                    if (item.isOwned) {
                      // EQUIP LOGIC
                      if (isEquipped) return;
                      
                      audio.playSfx('click');
                      if (item.userItemId != null) {
                        await provider.equipItem(item.userItemId!, item.slotType, 1);
                        CozyButton.heartbeat(); // Haptic polish
                      }
                      return;
                    }

                    // BUY LOGIC
                    if (currentCoins < item.price) {
                      audio.playSfx('click'); 
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: const Text('Not enough funds!'), backgroundColor: Colors.red[300]));
                      return;
                    }

                    bool success = await provider.buyItem(item.id, context);
                    if (success) {
                      audio.playSfx('success');
                      CozyButton.heartbeat(); // PREMIUM HEARTBEAT FEEL
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView(ShopProvider provider) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
            const SizedBox(height: 16),
            Text('Sync Error: ${provider.errorMessage}',
                style: GoogleFonts.figtree(color: const Color(0xFF5D4037), fontWeight: FontWeight.bold),
                textAlign: TextAlign.center),
            const SizedBox(height: 20),
            CozyButton(
              label: 'RE-FETCH STORAGE',
              onPressed: () => provider.fetchCatalog(),
            )
          ],
        ),
      ),
    );
  }
}
