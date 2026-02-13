class ShopUserItem {
  final int id;
  final int? serverId;
  final int itemId;
  final bool isPlaced;
  final String? placedAtSlot;
  final String name;
  final String assetPath;
  final String slotType;
  final int? x;
  final int? y;
  final int? roomId;

  ShopUserItem({
    required this.id,
    this.serverId,
    required this.itemId,
    required this.isPlaced,
    this.placedAtSlot,
    required this.name,
    required this.assetPath,
    required this.slotType,
    this.x,
    this.y,
    this.roomId,
  });

  factory ShopUserItem.fromJson(Map<String, dynamic> json) {
    return ShopUserItem(
      id: json['id'], // Server ID is used as primary ID when coming from remote
      serverId: json['id'],
      itemId: json['item_id'],
      isPlaced: json['is_placed'] ?? false,
      placedAtSlot: json['placed_at_slot'],
      name: json['name'],
      assetPath: json['asset_path'] ?? '',
      slotType: json['slot_type'] ?? '',
      x: json['x'],
      y: json['y'],
      roomId: json['placed_at_room_id'],
    );
  }

  // 🎨 Visual Layering Logic
  int get zIndex {
    switch (slotType) {
      case 'room':
        return 0;
      case 'floor_decor':
        return 10;
      case 'bin':
        return 11;
      case 'plant':
        return 12;
      case 'wall_decor':
        return 15;
      case 'wall_calendar':
        return 16;
      case 'window':
        return 14;
      case 'furniture':
      case 'desk':
        return 20;
      case 'exam_table':
        return 25;
      case 'monitor':
        return 28;
      case 'tabletop':
        return 30;
      case 'desk_decor':
        return 40;
      case 'avatar':
        return 50;
      default:
        return 5;
    }
  }
}
