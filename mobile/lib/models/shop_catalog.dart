import 'shop_item.dart';

/// 🛒 MVP Catalog: Hardcoded items matching the new 3D/Layered assets
class ShopCatalog {
  static final List<ShopItem> items = [
    // 🏠 ROOMS
    ShopItem(
      id: 100,
      name: 'Cozy Morning',
      type: 'room',
      slotType: 'room',
      price: 0,
      assetPath: 'assets/images/room/room_0.webp',
      description: 'A bright, sun-filled room perfect for early risers.',
      isOwned: false,
    ),
    ShopItem(
      id: 101,
      name: 'Midnight Study',
      type: 'room',
      slotType: 'room',
      price: 500,
      assetPath: 'assets/images/room/room_1.webp',
      description: 'Deep calm tones for focused night sessions.',
      isOwned: false,
    ),

    // 🪑 FURNITURE (Desks)
    ShopItem(
      id: 200,
      name: 'Oak Starter Desk',
      type: 'furniture',
      slotType: 'desk',
      price: 100,
      assetPath: 'assets/images/furniture/desk.webp',
      description: 'Sturdy and reliable.',
      isOwned: false,
    ),
    ShopItem(
      id: 201,
      name: 'Minimalist White',
      type: 'furniture',
      slotType: 'desk',
      price: 100,
      assetPath: 'assets/images/furniture/desk_1.webp',
      description: 'Clean lines for a clear mind.',
      isOwned: false,
    ),
    ShopItem(
      id: 202,
      name: 'Mahogany Executive',
      type: 'furniture',
      slotType: 'desk',
      price: 100,
      assetPath: 'assets/images/furniture/desk_2.webp',
      description: 'Serious business.',
      isOwned: false,
    ),
    ShopItem(
      id: 203,
      name: 'Gamer Station',
      type: 'furniture',
      slotType: 'desk',
      price: 100,
      assetPath: 'assets/images/furniture/desk_3.webp',
      description: 'RGB increases performance by 10%.',
      isOwned: false,
    ),

    // 🖥️ DESK DECOR (Computers / Printers)
    ShopItem(
      id: 300,
      name: 'Modern Workstation',
      type: 'furniture',
      slotType: 'desk_decor',
      price: 75,
      assetPath: 'assets/images/furniture/ac.webp',
      description: 'A high-performance system for medical data.',
      isOwned: false,
    ),
    ShopItem(
      id: 301,
      name: 'Advanced Terminal',
      type: 'furniture',
      slotType: 'desk_decor',
      price: 75,
      assetPath: 'assets/images/furniture/ac_1.webp',
      description: 'Professional-grade processing power.',
      isOwned: false,
    ),

    // 🏥 CLINICAL (Gurneys / Exam Tables)
    ShopItem(
      id: 400,
      name: 'Basic Exam Bed',
      type: 'furniture',
      slotType: 'exam_table',
      price: 150,
      assetPath: 'assets/images/furniture/gurey_1.webp',
      description: 'Standard issue.',
      isOwned: false,
    ),
    ShopItem(
      id: 401,
      name: 'Advanced Gurney',
      type: 'furniture',
      slotType: 'exam_table',
      price: 150,
      assetPath: 'assets/images/furniture/gurey_2.webp',
      description: 'With hydraulic lift support.',
      isOwned: false,
    ),

    // 🎨 DECOR (Wall)
    ShopItem(
      id: 500,
      name: 'Geometric Wall Art',
      type: 'furniture',
      slotType: 'wall_decor',
      price: 75,
      assetPath: 'assets/images/furniture/wall_decor.webp',
      description: 'Adds a splash of color to the clinic.',
      isOwned: false,
    ),

    // 🪟 WINDOWS
    ShopItem(
      id: 600,
      name: 'Sunny Window',
      type: 'furniture',
      slotType: 'window',
      price: 200,
      assetPath: 'assets/images/furniture/window.webp',
      description: 'Let the sunshine in.',
      isOwned: false,
    ),
  ];
}
