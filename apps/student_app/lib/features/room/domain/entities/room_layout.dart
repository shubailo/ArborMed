
enum SlotLayer { background, mid, foreground }

class RoomSlot {
  final String slotId;
  final double? top;
  final double? bottom;
  final double? left;
  final double? right;
  final dynamic semanticPosition; // Flexible for future grid/zone usage
  final SlotLayer layer;
  final List<String> allowedCategories;
  final String label;

  const RoomSlot({
    required this.slotId,
    this.top,
    this.bottom,
    this.left,
    this.right,
    this.semanticPosition,
    this.layer = SlotLayer.mid,
    required this.allowedCategories,
    required this.label,
  });
}

class RoomLayout {
  final String layoutId;
  final String name;
  final List<RoomSlot> slots;
  final String? backgroundImage;

  const RoomLayout({
    required this.layoutId,
    required this.name,
    required this.slots,
    this.backgroundImage,
  });

  // Default Clinical Layout (Migration from current hardcoded slots)
  static RoomLayout defaultClinical() {
    return const RoomLayout(
      layoutId: 'clinical_v1',
      name: 'Modern Clinic',
      slots: [
        RoomSlot(
          slotId: 'wall_left',
          top: 40,
          left: 40,
          label: 'Wall Left',
          allowedCategories: ['poster', 'wall_decor'],
          layer: SlotLayer.background,
        ),
        RoomSlot(
          slotId: 'wall_right',
          top: 40,
          right: 40,
          label: 'Wall Right',
          allowedCategories: ['poster', 'wall_decor'],
          layer: SlotLayer.background,
        ),
        RoomSlot(
          slotId: 'desk_main',
          bottom: 100,
          left: 60,
          label: 'Desk Center',
          allowedCategories: ['tech', 'stationary', 'lamp'],
          layer: SlotLayer.mid,
        ),
        RoomSlot(
          slotId: 'floor_corner',
          bottom: 40,
          right: 60,
          label: 'Floor Right',
          allowedCategories: ['furniture', 'plant'],
          layer: SlotLayer.mid,
        ),
      ],
    );
  }
}
