import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/image_meta.dart';
import '../cozy/voxel_data.dart';
import '../cozy/cozy_dialog_sheet.dart';

class SmartItemIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Widget? fallback;

  const SmartItemIcon({
    Key? key,
    required this.assetPath,
    required this.size,
    this.fallback,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // 1. Get Data
    final filename = assetPath.split('/').last;
    final voxels = VoxelData.data[filename];
    final fullSize = ImageMeta.sizes[filename];

    // 2. Fallback if no data
    if (voxels == null || fullSize == null || voxels.isEmpty) {
       return SizedBox(
         width: size, height: size,
         child: Image.asset(assetPath, fit: BoxFit.contain, errorBuilder: (_,__,___) => fallback ?? const SizedBox()),
       );
    }

    // 3. Calculate Content Bounding Box
    double minX = double.infinity;
    double minY = double.infinity;
    double maxX = double.negativeInfinity;
    double maxY = double.negativeInfinity;

    for (var v in voxels) {
      if (v[0] < minX) minX = v[0];
      if (v[1] < minY) minY = v[1];
      if (v[0] + v[2] > maxX) maxX = v[0] + v[2];
      if (v[1] + v[3] > maxY) maxY = v[1] + v[3];
    }

    final contentW = maxX - minX;
    final contentH = maxY - minY;
    
    // 4. Calculate Scale to fit Content into Viewport (size)
    // Scale = Target / Content
    // We add a tiny buffer (10%) so it doesn't touch the circle edge
    final double zoom = (size * 0.9) / (contentW > contentH ? contentW : contentH);
    
    // 5. Center the content
    // We want the CENTER of the content to match the CENTER of the box.
    // Content Center relative to image:
    final double cx = minX + contentW / 2;
    final double cy = minY + contentH / 2;
    
    // Position of Image TopLeft relative to Box Center:
    // Box Center is (size/2, size/2).
    // We want (cx * zoom) to fall on (size/2).
    // So Image Left (0) should be specific offset.
    // OffsetX = BoxCenter - (ContentCenterX * zoom)
    final double left = (size / 2) - (cx * zoom);
    final double top = (size / 2) - (cy * zoom);
    
    return ClipRect(
      child: Container(
        width: size,
        height: size,
        color: Colors.transparent,
        child: Stack(
          children: [
            Positioned(
              left: left,
              top: top,
              width: fullSize.width * zoom,
              height: fullSize.height * zoom,
              child: Image.asset(assetPath, fit: BoxFit.fill),
            ),
          ],
        ),
      ),
    );
  }
}


enum ShopViewState { list, detail }

class ContextualShopSheet extends StatefulWidget {
  final String slotType;
  final int targetX;
  final int targetY;

  const ContextualShopSheet({
    Key? key, 
    required this.slotType,
    required this.targetX,
    required this.targetY,
  }) : super(key: key);

  @override
  createState() => _ContextualShopSheetState();
}

class _ContextualShopSheetState extends State<ContextualShopSheet> {
  ShopViewState _viewState = ShopViewState.list;
  ShopItem? _selectedItem;
  int _currentPage = 0;
  static const int _itemsPerPage = 4;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false).fetchCatalog(slotType: widget.slotType);
    });
  }

  void _onItemSelect(ShopItem item) {
    setState(() {
      _selectedItem = item;
      _viewState = ShopViewState.detail;
    });
    Provider.of<ShopProvider>(context, listen: false).setPreviewItem(item, x: widget.targetX, y: widget.targetY);
  }

  void _onBackToList() {
    setState(() {
      _viewState = ShopViewState.list;
    });
    Provider.of<ShopProvider>(context, listen: false).setPreviewItem(null);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ShopProvider>(
      builder: (context, provider, child) {
        if (provider.isFullPreviewMode) return const SizedBox.shrink();

        return CozyDialogSheet(
          onTapOutside: () => Navigator.pop(context),
          child: Stack(
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10), // Reduced gap

                  // Main Content (Grid)
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0), // Reduced from 50 to maximize tile size
                      child: provider.isLoading 
                          ? const Center(child: CircularProgressIndicator())
                          : provider.catalog.isEmpty
                              ? _buildEmptyCatalogView()
                              : _viewState == ShopViewState.list 
                                  ? _buildPaginatedListView(provider) 
                                  : _buildDetailView(provider),
                    ),
                  ),

                  // Navigation Arrows (if in list)
                  if (_viewState == ShopViewState.list && !provider.isLoading)
                    _buildPageNavigation(provider),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _viewState == ShopViewState.list 
                      ? _buildListActions()
                      : _buildDetailActions(provider),
                  ),
                ],
              ),
              // Close Button (Fixed Top Right) - REMOVED per user request
              // Positioned(right: 8, top: 8, child: IconButton(...))
            ],
          ),
        );
      },
    );
  }

  Widget _buildPaginatedListView(ShopProvider provider) {
    if (provider.isLoading) return const Center(child: CircularProgressIndicator());
    
    final catalog = provider.catalog;
    final startIndex = _currentPage * _itemsPerPage;
    final pagedItems = catalog.skip(startIndex).take(_itemsPerPage).toList();

    return Column(
      children: [
        // Row 1
        Expanded(
          child: Row(
            children: [
               Expanded(child: _buildShopTile(pagedItems.isNotEmpty ? pagedItems[0] : null)),
               const SizedBox(width: 16),
               Expanded(child: _buildShopTile(pagedItems.length > 1 ? pagedItems[1] : null)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Row 2
        Expanded(
          child: Row(
            children: [
               Expanded(child: _buildShopTile(pagedItems.length > 2 ? pagedItems[2] : null)),
               const SizedBox(width: 16),
               Expanded(child: _buildShopTile(pagedItems.length > 3 ? pagedItems[3] : null)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildShopTile(ShopItem? item) {
    if (item == null) return Container(decoration: const BoxDecoration(color: Colors.transparent)); // Empty placeholder

    return GestureDetector(
      onTap: () => _onItemSelect(item),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Dynamic Sizing but capped to avoid massive icons on tablets
          final double iconSize = (constraints.maxWidth * 0.65).clamp(60.0, 140.0); 

          return Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: CozyTheme.paperWhite, width: 4), 
              boxShadow: const [BoxShadow(color: Colors.black12, offset: Offset(0, 4), blurRadius: 6)],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                 Padding(
                   padding: const EdgeInsets.symmetric(vertical: 8.0),
                   child: SmartItemIcon(
                     assetPath: item.assetPath,
                     size: iconSize, 
                     fallback: _buildFallbackIcon(item.name, iconSize * 0.7),
                   ),
                 ),
                
                if (item.isOwned)
                  const Text('OWNED', style: TextStyle(fontSize: 11, color: CozyTheme.primary, fontWeight: FontWeight.w900))
                else
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset('assets/ui/buttons/stethoscope_hud.png', width: 16, height: 16),
                      const SizedBox(width: 4),
                      Text('${item.price}', style: const TextStyle(fontSize: 14, color: CozyTheme.accent, fontWeight: FontWeight.w900)),
                    ],
                  ),
              ],
            ),
          );
        }
      ),
    );
  }

  Widget _buildPageNavigation(ShopProvider provider) {
    final totalPages = (provider.catalog.length / _itemsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40.0, vertical: 0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(Icons.arrow_back_ios_rounded, size: 24, color: _currentPage > 0 ? const Color(0xFF8CAA8C) : Colors.grey[300]),
            onPressed: _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
            icon: Icon(Icons.arrow_forward_ios_rounded, size: 24, color: _currentPage < totalPages - 1 ? const Color(0xFF8CAA8C) : Colors.grey[300]),
            onPressed: _currentPage < totalPages - 1 ? () => setState(() => _currentPage++) : null,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailView(ShopProvider provider) {
    if (_selectedItem == null) return const SizedBox.shrink();
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(
          padding: const EdgeInsets.all(25),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.black12),
          ),
          child: SmartItemIcon(
            assetPath: _selectedItem!.assetPath,
            size: 150,
            fallback: _buildFallbackIcon(_selectedItem!.name, 150),
          ),
        ),
        const SizedBox(height: 20),
        Text(_selectedItem!.name.toUpperCase(), style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Color(0xFF3E2723), letterSpacing: 1.1)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(_selectedItem!.description, 
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 15, color: Colors.brown[700], fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildListActions() {
    return Row(
      children: [
        Expanded(child: _buildButton('CONFIRM', const Color(0xFFFBE9E7), const Color(0xFF3E2723), () => Navigator.pop(context))),
        const SizedBox(width: 12),
        Expanded(child: _buildButton('CANCEL', const Color(0xFFEF9A9A), const Color(0xFF3E2723), () => Navigator.pop(context))),
      ],
    );
  }

  Widget _buildDetailActions(ShopProvider provider) {
    final isOwned = _selectedItem?.isOwned ?? false;
    final userItemId = _selectedItem?.userItemId;
    
    // Check if THIS specific item (ID) is currently placed
    final isPlaced = provider.inventory.any((ui) => ui.itemId == _selectedItem?.id && ui.isPlaced);
    final placedUserItem = isPlaced ? provider.inventory.firstWhere((ui) => ui.itemId == _selectedItem?.id && ui.isPlaced) : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: isOwned
                ? _buildButton(isPlaced ? 'UNEQUIP' : 'EQUIP', const Color(0xFFE0F7FA), const Color(0xFF006064), () async {
                  if (userItemId == null && placedUserItem == null) return;
                  final targetId = placedUserItem?.id ?? userItemId!;
                  
                  bool success;
                  if (isPlaced) {
                    success = await provider.unequipItem(targetId);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? "Removed from room" : "Failed to remove"), backgroundColor: success ? Colors.green : Colors.red)
                      );
                    }
                  } else {
                    success = await provider.equipItem(targetId, widget.slotType, 1, x: widget.targetX, y: widget.targetY);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(success ? "Item placed!" : "Failed to place item"), backgroundColor: success ? Colors.green : Colors.red)
                      );
                    }
                  }
                  
                  if (success && mounted) {
                    provider.setPreviewItem(null);
                    Navigator.pop(context);
                  }
                })
                : _buildButton('PURCHASE (🩺 ${_selectedItem?.price})', const Color(0xFFA5D6A7), const Color(0xFF1B5E20), () async {
                  if (_selectedItem == null) return;
                  bool success = await provider.buyItem(_selectedItem!.id, context);
                  
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? "Purchased!" : "Insufficient coins or server error"), backgroundColor: success ? Colors.green : Colors.red)
                    );
                  }

                  if (success) {
                    await provider.fetchInventory();
                    // Auto-equip after purchase
                    final newItem = provider.inventory.lastWhere((ui) => ui.itemId == _selectedItem!.id);
                    await provider.equipItem(newItem.id, widget.slotType, 1, x: widget.targetX, y: widget.targetY);
                    if (mounted) {
                      provider.setPreviewItem(null);
                      Navigator.pop(context);
                    }
                  }
                }),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildButton('PREVIEW', const Color(0xFFFFF9C4), const Color(0xFF3E2723), () {
                provider.toggleFullPreview(true, slotType: widget.slotType, x: widget.targetX, y: widget.targetY);
                Navigator.pop(context);
              }),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildButton('BACK TO LIST', const Color(0xFFBBDEFB), const Color(0xFF3E2723), _onBackToList),
      ],
    );
  }

  Widget _buildButton(String text, Color bgColor, Color textColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        height: 52,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.black, width: 2.5),
          boxShadow: const [BoxShadow(color: Colors.black26, offset: Offset(0, 5))],
        ),
        child: Center(
          child: Text(
            text, 
            style: TextStyle(color: textColor, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ),
    );
  }



  Widget _buildEmptyCatalogView() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.inventory_2_outlined, size: 64, color: Colors.grey),
        const SizedBox(height: 16),
        Text(
          "No items available for this slot",
          style: TextStyle(fontSize: 16, color: Colors.grey[600], fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Check back later or try another area.",
          style: TextStyle(fontSize: 14, color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildFallbackIcon(String name, double size) {
    IconData iconData = Icons.chair_outlined;
    if (name.contains('Table') || name.contains('Gurney')) {
      iconData = Icons.airline_seat_flat_angled;
    } else if (name.contains('Book')) {
      iconData = Icons.menu_book;
    } else if (name.contains('Microscope')) {
      iconData = Icons.biotech;
    } else if (name.contains('Coat')) {
      iconData = Icons.checkroom;
    } else if (name.contains('Plant')) {
      iconData = Icons.eco;
    } else if (name.contains('Espresso')) {
      iconData = Icons.coffee_maker;
    } else if (name.contains('Rug')) {
      iconData = Icons.grid_view_sharp;
    } else if (name.contains('Monitor')) {
      iconData = Icons.monitor_heart;
    }
    
    return Icon(iconData, size: size, color: const Color(0xFF5D4037));
  }


}
