import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:student_app/features/room/presentation/providers/room_providers.dart';
import 'package:student_app/features/room/domain/entities/room_entities.dart';
import 'package:student_app/features/reward/presentation/providers/reward_providers.dart';

import 'package:student_app/features/room/domain/entities/room_layout.dart';
import 'package:student_app/core/theme/cozy_theme.dart';
import 'package:student_app/features/room/presentation/widgets/cozy_actions_overlay.dart';

class RoomShellScreen extends ConsumerWidget {
  const RoomShellScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final roomState = ref.watch(roomControllerProvider);

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      body: roomState.when(
        loading: () => const Center(child: CircularProgressIndicator()),
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
    final layout = RoomLayout.defaultClinical();

    return Stack(
      children: [
        // 2.5D Approximation Background
        Positioned.fill(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Theme.of(context).colorScheme.surface,
                  const Color(0xFFF1EFE7),
                ],
              ),
            ),
          ),
        ),

        // Layered Slots
        ...layout.slots.map((slot) {
          final currentItem = roomState.items
              .where((i) => i.slotKey == slot.slotId)
              .firstOrNull;
          return _RoomSlot(slot: slot, currentItem: currentItem);
        }),

        // Day/Night Tint Overlay
        const _DayNightTintOverlay(),

        // Room HUD / Navigation
        Positioned.fill(child: CozyActionsOverlay()),
      ],
    );
  }
}

class _DayNightTintOverlay extends StatelessWidget {
  const _DayNightTintOverlay();

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final hour = now.hour;
    Color tintColor = Colors.transparent;

    if (hour >= 6 && hour < 10) {
      tintColor = Colors.orange.withValues(alpha: 0.05); // Morning
    } else if (hour >= 17 && hour < 20) {
      tintColor = Colors.deepOrange.withValues(alpha: 0.1); // Sunset
    } else if (hour >= 20 || hour < 6) {
      tintColor = Colors.indigo.withValues(alpha: 0.15); // Night
    }

    return IgnorePointer(child: Container(color: tintColor));
  }
}

class _RoomSlot extends ConsumerWidget {
  final RoomSlot slot;
  final RoomItem? currentItem;

  const _RoomSlot({required this.slot, this.currentItem});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final item = currentItem;
    return Positioned(
      top: slot.top,
      bottom: slot.bottom,
      left: slot.left,
      right: slot.right,
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
                borderRadius: CozyTheme.borderMedium,
                border: Border.all(
                  color: item == null
                      ? const Color(0xFFE2DDD1)
                      : Colors.transparent,
                  style: BorderStyle.solid,
                ),
                boxShadow: item == null ? null : CozyTheme.panelShadow,
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
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 2,
                    ),
                  ],
                ),
                child: Text(
                  item.shopItem.name,
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showSelectionSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _SelectionSheet(
        slotKey: slot.slotId,
        allowedCategories: slot.allowedCategories,
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
                      style: const TextStyle(
                        fontSize: 13,
                        color: Color(0xFFB5A79E),
                      ),
                    ),
                  ],
                ),
                if (currentPlacementId != null)
                  TextButton.icon(
                    onPressed: () {
                      ref
                          .read(roomControllerProvider.notifier)
                          .clearSlot(slotKey);
                      Navigator.pop(context);
                    },
                    icon: const Icon(
                      Icons.delete_outline,
                      color: Color(0xFFE06C53),
                      size: 18,
                    ),
                    label: const Text(
                      'Clear Slot',
                      style: TextStyle(color: Color(0xFFE06C53)),
                    ),
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
                  return shopItem != null &&
                      allowedCategories.contains(shopItem.category);
                }).toList();

                if (filtered.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.inventory_2_outlined,
                          size: 48,
                          color: Color(0xFFF1EFE7),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No available items for this slot.',
                          style: TextStyle(color: Color(0xFFB5A79E)),
                        ),
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(context), // Go buy some maybe?
                          child: const Text('Back to Room'),
                        ),
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
                              ref
                                  .read(roomControllerProvider.notifier)
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
                            ),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.image_outlined,
                              color: Color(0xFFB5A79E),
                              size: 32,
                            ),
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
                                color: invItem.quantity > 0
                                    ? const Color(0xFFB5A79E)
                                    : Colors.red,
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
        return const Icon(
          Icons.extension_outlined,
          color: Color(0xFFE2DDD1),
          size: 32,
        );
      },
    );
  }
}
