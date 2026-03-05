import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/avatar_config.dart';
import '../../models/avatar_assets.dart';
import '../../services/shop_provider.dart';
import '../../widgets/avatar/avatar_renderer.dart';

/// The Avatar Studio Screen where users customize their avatar.
/// Implements a "Clipboard" aesthetic with live preview and item selection.
class AvatarStudioScreen extends StatefulWidget {
  const AvatarStudioScreen({super.key});

  @override
  State<AvatarStudioScreen> createState() => _AvatarStudioScreenState();
}

class _AvatarStudioScreenState extends State<AvatarStudioScreen> {
  late AvatarConfig _workingConfig;
  String _activeCategoryId = AvatarAssets.categories.first.id;
  final Set<String> _unownedItemIds = {};

  @override
  void initState() {
    super.initState();
    final shop = context.read<ShopProvider>();
    _workingConfig = shop.myAvatarConfig;
    _calculateUnowned();
  }

  void _calculateUnowned() {
    final shop = context.read<ShopProvider>();
    _unownedItemIds.clear();

    // Check layer items against owned inventory
    for (var entry in _workingConfig.layers.entries) {
      if (entry.value != null && entry.value != 'default' && entry.value != 'nothing') {
        final owned = shop.ownedItems.any((oi) => oi.id.toString() == entry.value);
        if (!owned) {
          _unownedItemIds.add(entry.value!);
        }
      }
    }
  }

  void _onItemTap(String itemId, bool isColor) {
    setState(() {
      if (isColor) {
        if (_activeCategoryId == 'skin_color') {
          _workingConfig = _workingConfig.withSkinTone(itemId);
        } else if (_activeCategoryId == 'hair_color') {
          _workingConfig = _workingConfig.withHairColor(itemId);
        } else if (_activeCategoryId == 'outfit_color') {
          _workingConfig = _workingConfig.copyWith(
              palette: _workingConfig.palette.copyWith(outfit: itemId));
        }
      } else {
        _workingConfig = _workingConfig.withLayer(_activeCategoryId, itemId);
      }
      _calculateUnowned();
    });
  }

  Future<void> _handleSave() async {
    final shop = context.read<ShopProvider>();
    
    // 1. Identify unowned items to buy
    final List<ShopItem> toBuy = [];
    int totalCost = 0;
    
    for (var id in _unownedItemIds) {
      try {
        final item = shop.catalog.firstWhere((i) => i.id.toString() == id);
        toBuy.add(item);
        totalCost += item.price;
      } catch (_) {
        // Item not found in catalog, skip
      }
    }

    // 2. If unowned items exist, confirm purchase
    if (toBuy.isNotEmpty) {
      final confirmed = await _showPurchaseConfirmSimple(toBuy.length, totalCost);
      if (!confirmed) return;
      
      if (shop.coins < totalCost) {
        _showInsufficientFunds();
        return;
      }
    }

    // 3. Save
    final success = await shop.saveAvatarConfig(_workingConfig, itemsToBuy: toBuy);
    if (success && mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Avatar saved!')),
      );
    }
  }

  Future<bool> _showPurchaseConfirmSimple(int itemCount, int total) async {
    return await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Purchase'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('You are about to buy $itemCount item(s):'),
            const SizedBox(height: 12),
            const Divider(),
            ListTile(
              title: const Text('Total Cost', style: TextStyle(fontWeight: FontWeight.bold)),
              trailing: Text('🪙 $total', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.amber)),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.pop(context, true), child: const Text('Buy & Save')),
        ],
      ),
    ) ?? false;
  }

  void _showInsufficientFunds() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insufficient Coins'),
        content: const Text('You don\'t have enough coins for these items. Complete more tasks to earn coins!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK')),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Avatar Studio', style: TextStyle(fontWeight: FontWeight.bold)),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          TextButton(
            onPressed: _handleSave,
            child: const Text('Save', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Preview Area ──────────────────────────────────────────
          Expanded(
            flex: 2,
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                image: const DecorationImage(
                  image: AssetImage('assets/images/dots_pattern.png'), // Assume bg pattern exists
                  repeat: ImageRepeat.repeat,
                  opacity: 0.05,
                ),
              ),
              child: Center(
                child: AvatarRenderer(
                  config: _workingConfig,
                  size: 240,
                  showBorder: true,
                  backgroundColor: Colors.white,
                ),
              ),
            ),
          ),

          // ── Category Navigator ──────────────────────────────────────
          Container(
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              itemCount: AvatarAssets.categories.length,
              itemBuilder: (context, index) {
                final cat = AvatarAssets.categories[index];
                final isSelected = cat.id == _activeCategoryId;
                return GestureDetector(
                  onTap: () => setState(() => _activeCategoryId = cat.id),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                    child: Center(
                      child: Opacity(
                        opacity: isSelected ? 1.0 : 0.4,
                        child: Text(
                          cat.icon,
                          style: const TextStyle(
                            fontSize: 24,
                        ),
                      ),
                    ),
                  ),
                  ),
                );
              },
            ),
          ),

          // ── Item Selector ──────────────────────────────────────────
          Expanded(
            flex: 3,
            child: _buildItemGrid(),
          ),
        ],
      ),
    );
  }

  Widget _buildItemGrid() {
    final cat = AvatarAssets.categories.firstWhere((c) => c.id == _activeCategoryId);
    final items = AvatarAssets.getItemsForCategory(cat.id);
    final shop = context.watch<ShopProvider>();

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: 1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final itemId = items[index];
        bool isSelected = false;

        // Check selection state
        if (cat.isColorPicker) {
          if (cat.id == 'skin_color') isSelected = _workingConfig.palette.skin == itemId;
          if (cat.id == 'hair_color') isSelected = _workingConfig.palette.hair == itemId;
          if (cat.id == 'outfit_color') isSelected = _workingConfig.palette.outfit == itemId;
        } else {
          isSelected = _workingConfig.layers[cat.id] == itemId;
        }

        final isLocked = !cat.isColorPicker && itemId != 'nothing' && itemId != 'default' && !shop.ownedItems.any((oi) => oi.id.toString() == itemId);

        return GestureDetector(
          onTap: () => _onItemTap(itemId, cat.isColorPicker),
          child: Container(
            decoration: BoxDecoration(
              color: isSelected ? Theme.of(context).primaryColor.withValues(alpha: 0.1) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isSelected ? Theme.of(context).primaryColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Stack(
              children: [
                Center(
                  child: cat.isColorPicker
                      ? _buildColorPreview(cat.id, itemId)
                      : Text(itemId, textAlign: TextAlign.center, style: const TextStyle(fontSize: 10)),
                ),
                if (isLocked)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Icon(Icons.lock, size: 16, color: Colors.grey.shade600),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildColorPreview(String catId, String itemId) {
    String hex = '#FFFFFF';
    if (catId == 'skin_color') hex = AvatarAssets.skinColors[itemId]!;
    if (catId == 'hair_color') hex = AvatarAssets.hairColors[itemId]!;
    if (catId == 'outfit_color') hex = AvatarAssets.outfitColors[itemId]!;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
        shape: BoxShape.circle,
        border: Border.all(color: Colors.black12),
      ),
    );
  }
}
