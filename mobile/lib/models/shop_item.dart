class ShopItem {
  final int id;
  final String name;
  final String type; // 'equipment', 'decor'
  final String slotType; // 'desk', 'wall', etc.
  final int price;
  final String assetPath;
  final String description;
  final String? theme;
  final Map<String, dynamic>? unlockReq;
  final bool isOwned;
  final int? userItemId;

  ShopItem({
    required this.id,
    required this.name,
    required this.type,
    required this.slotType,
    required this.price,
    required this.assetPath,
    required this.description,
    this.theme,
    this.unlockReq,
    this.isOwned = false,
    this.userItemId,
  });

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      name: json['name'],
      type: json['type'],
      slotType: json['slot_type'],
      price: json['price'],
      assetPath: json['asset_path'] ?? '',
      description: json['description'] ?? '',
      theme: json['theme'],
      unlockReq: json['unlock_req'] != null
          ? Map<String, dynamic>.from(json['unlock_req'])
          : null,
      isOwned: json['is_owned'] ?? false,
      userItemId: json['user_item_id'],
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
        return 15; // Behind furniture, below AC
      case 'wall_calendar':
        return 16;
      case 'window':
        return 14;
      case 'furniture':
      case 'desk':
        return 20; // Desks, shelves
      case 'exam_table':
        return 25; // Gurneys
      case 'monitor':
        return 28; // On top of stuff
      case 'tabletop':
        return 30; // Laptops, lamps
      case 'desk_decor':
        return 40; // High on wall or on desk
      case 'avatar':
        return 50;
      default:
        return 5;
    }
  }
}
