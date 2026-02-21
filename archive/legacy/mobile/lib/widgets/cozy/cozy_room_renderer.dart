import 'package:flutter/material.dart';
import '../../services/shop_provider.dart';
import 'voxel_data.dart';

class CozyRoomRenderer extends StatelessWidget {
  final ShopItem room;
  final List<ShopItem> equippedItems;
  final List<ShopItem> ghostItems;
  final ShopItem? previewItem;
  final double scale;
  final Function(ShopItem)? onItemTap;
  final BorderRadius? borderRadius;

  const CozyRoomRenderer({
    super.key,
    required this.room,
    required this.equippedItems,
    this.ghostItems = const [],
    this.previewItem,
    this.scale = 1.0,
    this.onItemTap,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    // 1. Merge Room + Items + Ghosts + Preview
    final equippedSlots = equippedItems.map((e) => e.slotType).toSet();
    final visibleGhosts =
        ghostItems.where((g) => !equippedSlots.contains(g.slotType)).toList();

    final allAssets = [room, ...equippedItems, ...visibleGhosts];
    if (previewItem != null) {
      allAssets.add(previewItem!);
    }

    // 2. Sort by Z-Index (Painter's Algorithm)
    allAssets.sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // 3. De-duplicate Assets by Slot Type to prevent visual stacking
    final Map<String, ShopItem> uniqueAssets = {};
    for (var item in allAssets) {
      if (item.assetPath.isEmpty) continue;

      // Use slotType as the key to ensure only one item per slot is rendered.
      // Since allAssets is constructed as [equippedItems, ghosts, previewItem],
      // the later items (ghosts/previews) will naturally overwrite earlier ones.
      uniqueAssets[item.slotType] = item;
    }

    final validAssets = uniqueAssets.values.toList();

    return Container(
      alignment: Alignment.center,
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.zero,
        child: Stack(
          alignment: Alignment.center,
          children: validAssets.map((item) {
            final isGhost = ghostItems.contains(item);
            final itemKey =
                "${isGhost ? 'G' : 'E'}_${item.slotType}_${item.id}_${item.userItemId ?? ''}";

            // Voxel Hitbox Logic (Pixel-Perfect)
            final filename = item.assetPath.split('/').last;
            final voxels = VoxelData.data[filename] ?? [];

            return SyncedScaleWrapper(
              key: ValueKey(itemKey),
              onTap: onItemTap != null ? () => onItemTap!(item) : null,
              isGhost: isGhost,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // A. VISUAL
                  IgnorePointer(
                    child: Opacity(
                      opacity: isGhost ? 0.6 : 1.0,
                      child: Image.asset(
                        item.assetPath,
                        gaplessPlayback: true,
                        errorBuilder: (context, error, stackTrace) {
                          // 📦 Fallback for missing assets
                          return Container(
                            width: 300,
                            height: 300,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.inventory_2_outlined,
                                    color: Colors.white.withValues(alpha: 0.5),
                                    size: 48,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    "Unpacking...",
                                    style: TextStyle(
                                      color:
                                          Colors.white.withValues(alpha: 0.5),
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // B. VOXEL HITBOXES
                  if (onItemTap != null)
                    ...voxels.map((rect) {
                      return Positioned(
                        left: rect[0],
                        top: rect[1],
                        width: rect[2],
                        height: rect[3],
                        child: Builder(builder: (context) {
                          return Listener(
                            onPointerDown: (_) {
                              debugPrint("👇 POINTER DOWN: $filename");
                              SyncedScaleWrapper._of(context)?.animateTap(true);
                            },
                            onPointerUp: (_) {
                              SyncedScaleWrapper._of(context)
                                  ?.animateTap(false);
                            },
                            onPointerCancel: (_) {
                              SyncedScaleWrapper._of(context)
                                  ?.animateTap(false);
                            },
                            child: GestureDetector(
                              behavior: HitTestBehavior.translucent,
                              onTap: () async {
                                // Wait for bounce-back to be visible
                                await Future.delayed(
                                    const Duration(milliseconds: 200));
                                onItemTap!(item);
                              },
                              child: Container(
                                color: Colors.transparent, // HIDDEN
                              ),
                            ),
                          );
                        }),
                      );
                    }),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

/// Helper: Separation of Taps vs Visuals
class SyncedScaleWrapper extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final bool isGhost;

  const SyncedScaleWrapper({
    super.key,
    required this.child,
    this.onTap,
    this.isGhost = false,
  });

  @override
  createState() => _SyncedScaleWrapperState();

  static _SyncedScaleWrapperState? _of(BuildContext context) {
    return context.findAncestorStateOfType<_SyncedScaleWrapperState>();
  }
}

class _SyncedScaleWrapperState extends State<SyncedScaleWrapper>
    with TickerProviderStateMixin {
  late AnimationController _tapController;
  late Animation<double> _tapScaleAnim;

  late AnimationController _entryController;
  late Animation<double> _entryScaleAnim;

  @override
  void initState() {
    super.initState();
    // 1. Tap Animation
    _tapController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 70),
        reverseDuration: const Duration(milliseconds: 300));
    _tapScaleAnim = Tween<double>(begin: 1.0, end: 0.98).animate(
        // Slightly less scale down
        CurvedAnimation(
            parent: _tapController,
            curve: Curves.easeOutCubic,
            reverseCurve:
                Curves.easeOutCubic // Removed elasticOut for subtler feel
            ));

    // 2. Entry Animation (The "Pop" - now more of a "Gentle Nudge")
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // Slightly faster
    );

    _entryScaleAnim = TweenSequence<double>([
      TweenSequenceItem(
          tween: Tween(begin: 0.0, end: 1.05)
              .chain(CurveTween(curve: Curves.easeOutQuart)),
          weight: 70), // Reduced overshoot from 1.15 to 1.05
      TweenSequenceItem(
          tween: Tween(begin: 1.05, end: 1.0)
              .chain(CurveTween(curve: Curves.easeInOut)),
          weight: 30),
    ]).animate(_entryController);

    _entryController.forward();
  }

  @override
  void dispose() {
    _tapController.dispose();
    _entryController.dispose();
    super.dispose();
  }

  Future<void> animateTap(bool down) async {
    if (!mounted) return;
    if (down) {
      _tapController.forward();
    } else {
      await _tapController.forward();
      if (mounted) await _tapController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 📦 The Asset
          ScaleTransition(
            scale: _entryScaleAnim,
            child: ScaleTransition(
              scale: _tapScaleAnim,
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
