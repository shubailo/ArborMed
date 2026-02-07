import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../services/shop_provider.dart';
import '../../theme/cozy_theme.dart';
import '../cozy/cozy_toast.dart';
import '../cozy/image_meta.dart';
import '../cozy/voxel_data.dart';
import '../cozy/cozy_dialog_sheet.dart';
import '../cozy/cozy_button.dart';

class SmartItemIcon extends StatelessWidget {
  final String assetPath;
  final double size;
  final Widget? fallback;

  const SmartItemIcon({
    super.key,
    required this.assetPath,
    required this.size,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Get Data
    final filename = assetPath.split('/').last;
    final voxels = VoxelData.data[filename];
    final fullSize = ImageMeta.sizes[filename];

    // 2. Fallback if no data
    if (voxels == null || fullSize == null || voxels.isEmpty) {
      return SizedBox(
        width: size,
        height: size,
        child: Image.asset(assetPath,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => fallback ?? const SizedBox()),
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
    final double zoom =
        (size * 0.9) / (contentW > contentH ? contentW : contentH);

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
              child: Image.asset(assetPath,
                  fit: BoxFit.fill,
                  errorBuilder: (_, __, ___) => fallback ?? const SizedBox()),
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
    super.key,
    required this.slotType,
    required this.targetX,
    required this.targetY,
  });

  @override
  createState() => _ContextualShopSheetState();
}

class _ContextualShopSheetState extends State<ContextualShopSheet> {
  ShopViewState _viewState = ShopViewState.list;
  ShopItem? _selectedItem;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ShopProvider>(context, listen: false)
          .fetchCatalog(slotType: widget.slotType);
    });
  }

  void _onItemSelect(ShopItem item) {
    setState(() {
      _selectedItem = item;
      _viewState = ShopViewState.detail;
    });
    Provider.of<ShopProvider>(context, listen: false)
        .setPreviewItem(item, x: widget.targetX, y: widget.targetY);
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
                    child: provider.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : provider.catalog.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 24.0),
                                child: _buildEmptyCatalogView(),
                              )
                            : _viewState == ShopViewState.list
                                ? _buildShopListView(provider)
                                : Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 24.0),
                                    child: _buildDetailView(provider),
                                  ),
                  ),

                  // Actions
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: _viewState == ShopViewState.list
                        ? const SizedBox
                            .shrink() // No actions in list view as per user request (Close/Guide removed)
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

  Widget _buildShopListView(ShopProvider provider) {
    if (provider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final catalog = provider.catalog;
    final categoryName = provider.catalog.isNotEmpty
        ? widget.slotType.replaceAll('_', ' ').toUpperCase()
        : "";

    return Column(
      children: [
        // Category Header
        if (categoryName.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: Text(
              categoryName,
              style: GoogleFonts.figtree(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: CozyTheme.of(context).textPrimary,
                letterSpacing: 2.0,
              ),
            ),
          ),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.9,
            ),
            itemCount: catalog.length,
            itemBuilder: (context, index) => _buildShopTile(catalog[index]),
          ),
        ),
      ],
    );
  }

  Widget _buildShopTile(ShopItem? item) {
    if (item == null) return const SizedBox.shrink(); // Empty placeholder

    return GestureDetector(
      onTap: () => _onItemSelect(item),
      child: Builder(
        builder: (context) {
          final palette = CozyTheme.of(context);

          return LayoutBuilder(builder: (context, constraints) {
            // Dynamic Sizing but capped to avoid massive icons on tablets
            final double iconSize =
                (constraints.maxWidth * 0.65).clamp(60.0, 140.0);

            return Container(
              decoration: BoxDecoration(
                color: palette.paperWhite,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: palette.textSecondary.withValues(alpha: 0.1),
                    width: 4),
                boxShadow: const [], // Removed shadows
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
                    Text('OWNED',
                        style: TextStyle(
                            fontSize: 11,
                            color: palette.primary,
                            fontWeight: FontWeight.w900))
                  else
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Image.asset('assets/ui/buttons/stethoscope_hud.png',
                            width: 16, height: 16),
                        const SizedBox(width: 4),
                        Text('${item.price}',
                            style: TextStyle(
                                fontSize: 14,
                                color: palette.secondary,
                                fontWeight: FontWeight.w900)),
                      ],
                    ),
                ],
              ),
            );
          });
        },
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
            color: CozyTheme.of(context).surface.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color:
                    CozyTheme.of(context).textSecondary.withValues(alpha: 0.1)),
          ),
          child: SmartItemIcon(
            assetPath: _selectedItem!.assetPath,
            size: 150,
            fallback: _buildFallbackIcon(_selectedItem!.name, 150),
          ),
        ),
        const SizedBox(height: 20),
        Text(_selectedItem!.name.toUpperCase(),
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: CozyTheme.of(context).textPrimary,
                letterSpacing: 1.1)),
        const SizedBox(height: 10),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20.0),
          child: Text(
            _selectedItem!.description,
            textAlign: TextAlign.center,
            style: TextStyle(
                fontSize: 15,
                color: CozyTheme.of(context).textSecondary,
                fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailActions(ShopProvider provider) {
    final isOwned = _selectedItem?.isOwned ?? false;
    final userItemId = _selectedItem?.userItemId;

    final isPlaced = provider.inventory
        .any((ui) => ui.itemId == _selectedItem?.id && ui.isPlaced);
    final placedUserItem = isPlaced
        ? provider.inventory
            .firstWhere((ui) => ui.itemId == _selectedItem?.id && ui.isPlaced)
        : null;

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: isOwned
                  ? CozyButton(
                      label: isPlaced ? 'Unequip' : 'Equip',
                      variant: isPlaced
                          ? CozyButtonVariant.secondary
                          : CozyButtonVariant.primary,
                      onPressed: () async {
                        if (userItemId == null && placedUserItem == null) {
                          return;
                        }
                        final targetId = placedUserItem?.id ?? userItemId!;

                        bool success;
                        if (isPlaced) {
                          success = await provider.unequipItem(targetId);
                          if (mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            CozyToast.show(context,
                                message:
                                    success ? "Removed from room" : "Failed",
                                type: success
                                    ? ToastType.success
                                    : ToastType.error);
                          }
                        } else {
                          success = await provider.equipItem(
                              targetId, widget.slotType, 1,
                              x: widget.targetX, y: widget.targetY);
                          if (mounted) {
                            ScaffoldMessenger.of(context).clearSnackBars();
                            CozyToast.show(context,
                                message: success ? "Item placed!" : "Failed",
                                type: success
                                    ? ToastType.success
                                    : ToastType.error);
                          }
                        }

                        if (success && mounted) {
                          provider.setPreviewItem(null);
                          Navigator.pop(context);
                        }
                      },
                    )
                  : CozyButton(
                      label: 'Buy 🩺 ${_selectedItem?.price}',
                      variant: CozyButtonVariant.primary,
                      onPressed: () async {
                        if (_selectedItem == null) return;
                        bool success =
                            await provider.buyItem(_selectedItem!.id, context);

                        if (success) {
                          await provider.fetchInventory();
                          final newItem = provider.inventory.lastWhere(
                              (ui) => ui.itemId == _selectedItem!.id);
                          await provider.equipItem(
                              newItem.id, widget.slotType, 1,
                              x: widget.targetX, y: widget.targetY);
                          if (mounted) {
                            provider.setPreviewItem(null);
                            Navigator.pop(context);
                          }
                        }
                      },
                    ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: CozyButton(
                label: 'Preview',
                variant: CozyButtonVariant.outline,
                onPressed: () {
                  provider.toggleFullPreview(true,
                      slotType: widget.slotType,
                      x: widget.targetX,
                      y: widget.targetY);
                  Navigator.pop(context);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CozyButton(
          label: 'Back to List',
          variant: CozyButtonVariant.ghost,
          fullWidth: true,
          onPressed: _onBackToList,
        ),
      ],
    );
  }

  Widget _buildEmptyCatalogView() {
    final palette = CozyTheme.of(context);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.inventory_2_outlined,
            size: 64, color: palette.textSecondary.withValues(alpha: 0.3)),
        const SizedBox(height: 16),
        Text(
          "No items available for this slot",
          style: TextStyle(
              fontSize: 16,
              color: palette.textSecondary,
              fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text(
          "Check back later or try another area.",
          style: TextStyle(
              fontSize: 14,
              color: palette.textSecondary.withValues(alpha: 0.6)),
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

    final palette = CozyTheme.of(context);
    return Icon(iconData, size: size, color: palette.textPrimary);
  }
}
