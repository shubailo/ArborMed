import 'package:flutter/material.dart';
import 'package:student_app/features/room/domain/entities/room_entities.dart';
import 'package:student_app/features/room/domain/entities/room_layout.dart' as entities;
import 'package:student_app/core/theme/cozy_theme.dart';

class RoomLayout extends StatelessWidget {
  final List<RoomItem> activeItems;
  final Function(String slotId)? onSlotTap;

  const RoomLayout({
    super.key,
    required this.activeItems,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final layout = entities.RoomLayout.defaultClinical();

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
          final currentItem = activeItems
              .where((i) => i.slotKey == slot.slotId)
              .firstOrNull;
          return _RoomSlot(
            slot: slot,
            currentItem: currentItem,
            onTap: onSlotTap != null ? () => onSlotTap!(slot.slotId) : null,
          );
        }),
      ],
    );
  }
}

class _RoomSlot extends StatelessWidget {
  final entities.RoomSlot slot;
  final RoomItem? currentItem;
  final VoidCallback? onTap;

  const _RoomSlot({required this.slot, this.currentItem, this.onTap});

  @override
  Widget build(BuildContext context) {
    final item = currentItem;
    return Positioned(
      top: slot.top,
      bottom: slot.bottom,
      left: slot.left,
      right: slot.right,
      child: GestureDetector(
        onTap: onTap,
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
                ),
                boxShadow: item == null ? null : CozyTheme.panelShadow,
              ),
              child: item == null
                  ? const Center(child: Icon(Icons.add, color: Color(0xFFB5A79E)))
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
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 10),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RoomItemSprite extends StatelessWidget {
  final String itemKey;
  const _RoomItemSprite({required this.itemKey});

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/room/items/$itemKey.png',
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return const Icon(
          Icons.extension_outlined,
          color: Color(0xFFE2DDD1),
          size: 32,
        );
      },
    );
  }
}
