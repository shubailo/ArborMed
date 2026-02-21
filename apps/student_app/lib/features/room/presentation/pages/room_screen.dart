import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/room/presentation/providers/room_providers.dart';
import 'package:student_app/features/room/domain/entities/room_entities.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';

class RoomScreen extends ConsumerWidget {
  const RoomScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomControllerProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBFBF9),
      appBar: AppBar(
        title: const Text(
          'My Study Room',
          style: TextStyle(
            color: Color(0xFF4A443F),
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20, color: Color(0xFF4A443F)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: roomState.when(
        loading: () => const Center(child: CircularProgressIndicator(color: Color(0xFFE06C53))),
        error: (err, stack) => Center(child: Text('Error: $err')),
        data: (state) => _RoomView(roomState: state),
      ),
    );
  }
}

class _RoomView extends StatelessWidget {
  final RoomState roomState;
  const _RoomView({required this.roomState});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          flex: 3,
          child: Container(
            margin: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(32),
              border: Border.all(color: const Color(0xFFF1EFE7), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(30),
              child: Stack(
                children: [
                   // Base Background (Cozy Desk Scenery)
                  Positioned.fill(
                    child: Container(
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFF9F8F4), Color(0xFFF1EFE7)],
                        ),
                      ),
                    ),
                  ),
                  
                  // Shelf/Floor line
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(color: const Color(0xFFE2DDD1).withValues(alpha: 0.3)),
                  ),

                  // Slots
                  _RoomSlot(
                    slotKey: 'wall_left',
                    top: 40,
                    left: 40,
                    label: 'Wall Left',
                    currentItem: roomState.items.where((i) => i.slotKey == 'wall_left').firstOrNull,
                  ),
                  _RoomSlot(
                    slotKey: 'wall_right',
                    top: 40,
                    right: 40,
                    label: 'Wall Right',
                    currentItem: roomState.items.where((i) => i.slotKey == 'wall_right').firstOrNull,
                  ),
                  _RoomSlot(
                    slotKey: 'desk_main',
                    bottom: 100,
                    left: 60,
                    label: 'Desk Center',
                    currentItem: roomState.items.where((i) => i.slotKey == 'desk_main').firstOrNull,
                  ),
                  _RoomSlot(
                    slotKey: 'floor_corner',
                    bottom: 40,
                    right: 60,
                    label: 'Floor Right',
                    currentItem: roomState.items.where((i) => i.slotKey == 'floor_corner').firstOrNull,
                  ),
                ],
              ),
            ),
          ),
        ),
        
        // Instructional Footer
        Padding(
          padding: const EdgeInsets.all(24.0),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F4),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFF1EFE7)),
            ),
            child: const Row(
              children: [
                Icon(Icons.info_outline, color: Color(0xFFB5A79E), size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Tap on any empty slot or item to customize your study sanctuary.',
                    style: TextStyle(color: Color(0xFF8E847C), fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _RoomSlot extends ConsumerWidget {
  final String slotKey;
  final double? top, bottom, left, right;
  final String label;
  final RoomItem? currentItem;

  const _RoomSlot({
    required this.slotKey,
    this.top,
    this.bottom,
    this.left,
    this.right,
    required this.label,
    this.currentItem,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = currentItem;
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: GestureDetector(
        onTap: () => _showSelectionSheet(context, ref),
        child: Column(
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: item == null 
                    ? Colors.white.withValues(alpha: 0.5)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: item == null 
                      ? const Color(0xFFE2DDD1) 
                      : Colors.transparent,
                  style: BorderStyle.solid,
                ),
              ),
              child: item == null
                  ? const Center(
                      child: Icon(Icons.add, color: Color(0xFFB5A79E)),
                    )
                  : Center(child: _RoomItemSprite(itemKey: item.shopItem.key)),
            ),
            if (item != null)
              Container(
                 margin: const EdgeInsets.only(top: 4),
                 padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                 decoration: BoxDecoration(
                   color: Colors.white,
                   borderRadius: BorderRadius.circular(4),
                   boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 2)],
                 ),
                 child: Text(
                   item.shopItem.name,
                   style: const TextStyle(fontSize: 10, color: Color(0xFF4A443F)),
                 ),
              )
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context, WidgetRef ref) {
    // Determine allowed categories based on slot (V1 mapping)
    List<String> allowedCategories = [];
    if (slotKey.startsWith('wall')) allowedCategories = ['poster', 'wall_decor'];
    if (slotKey.startsWith('desk')) allowedCategories = ['tech', 'stationary', 'lamp'];
    if (slotKey.startsWith('floor')) allowedCategories = ['furniture', 'plant'];

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SelectionSheet(
        slotKey: slotKey,
        allowedCategories: allowedCategories,
        currentPlacementId: currentItem?.shopItemId,
      ),
    );
  }
}

class _SelectionSheet extends ConsumerWidget {
  final String slotKey;
  final List<String> allowedCategories;
  final String? currentPlacementId;

  const _SelectionSheet({
    required this.slotKey,
    required this.allowedCategories,
    this.currentPlacementId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inventory = ref.watch(rewardInventoryProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFF1EFE7),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Select Decor',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4A443F),
                      ),
                    ),
                    Text(
                      'Choose items for $slotKey',
                      style: const TextStyle(fontSize: 13, color: Color(0xFFB5A79E)),
                    ),
                  ],
                ),
                if (currentPlacementId != null)
                   TextButton.icon(
                     onPressed: () {
                       ref.read(roomControllerProvider.notifier).clearSlot(slotKey);
                       Navigator.pop(context);
                     },
                     icon: const Icon(Icons.delete_outline, color: Color(0xFFE06C53), size: 18),
                     label: const Text('Clear Slot', style: TextStyle(color: Color(0xFFE06C53))),
                   ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: inventory.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
              data: (items) {
                // Filter by category
                final filtered = items.where((i) {
                  final shopItem = i.shopItem;
                  return shopItem != null && allowedCategories.contains(shopItem.category);
                }).toList();
                
                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.inventory_2_outlined, size: 48, color: Color(0xFFF1EFE7)),
                        const SizedBox(height: 16),
                        const Text(
                          'No available items for this slot.',
                          style: TextStyle(color: Color(0xFFB5A79E)),
                        ),
                        TextButton(
                          onPressed: () => Navigator.pop(context), // Go buy some maybe?
                          child: const Text('Back to Room'),
                        )
                      ],
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.85,
                  ),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final invItem = filtered[index];
                    final isCurrent = invItem.shopItemId == currentPlacementId;
                    
                    return GestureDetector(
                      onTap: invItem.quantity > 0 || isCurrent
                          ? () {
                              ref.read(roomControllerProvider.notifier)
                                  .placeItem(slotKey, invItem.shopItemId);
                              Navigator.pop(context);
                            }
                          : null,
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isCurrent 
                                ? const Color(0xFFE06C53) 
                                : const Color(0xFFF1EFE7),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.02),
                              blurRadius: 8,
                            )
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.image_outlined, color: Color(0xFFB5A79E), size: 32),
                            const SizedBox(height: 12),
                            Text(
                              invItem.shopItem?.name ?? 'Item',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF4A443F),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'In Stock: ${invItem.quantity}',
                              style: TextStyle(
                                fontSize: 11,
                                color: invItem.quantity > 0 ? const Color(0xFFB5A79E) : Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomItemSprite extends StatelessWidget {
  final String itemKey;
  const _RoomItemSprite({required this.itemKey});

  @override
  Widget build(BuildContext context) {
    // Registry Map for custom assets
    final Map<String, String> registry = {
       // 'plant_fern': 'assets/room/items/plant_fern.png',
    };

    final assetPath = registry[itemKey] ?? 'assets/room/items/$itemKey.png';

    // V1: Use Icons as placeholders if asset loading is complex, 
    // but try image-based logic first as per spec
    return Image.asset(
      assetPath,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        // Fallback placeholder with generic category icons if image not found
        return const Icon(Icons.extension_outlined, color: Color(0xFFE2DDD1), size: 32);
      },
    );
  }
}
