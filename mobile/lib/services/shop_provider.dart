import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../services/auth_provider.dart';

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
      unlockReq: json['unlock_req'] != null ? Map<String, dynamic>.from(json['unlock_req']) : null,
      isOwned: json['is_owned'] ?? false,
      userItemId: json['user_item_id'],
    );
  }

  // 🎨 Visual Layering Logic
  int get zIndex {
    switch (slotType) {
      case 'room': return 0;
      case 'floor_decor': return 10;
      case 'wall_decor': return 15; // Behind furniture, below AC
      case 'window': return 14; 
      case 'furniture': return 20; // Desks, shelves
      case 'exam_table': return 25; // Gurneys
      case 'tabletop': return 30; // Laptops, lamps
      case 'wall_ac': return 40; // High on wall
      case 'avatar': return 50;
      default: return 5;
    }
  }
}

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
      slotType: 'furniture', // or 'desk'
      price: 100,
      assetPath: 'assets/images/furniture/desk.webp',
      description: 'Sturdy and reliable.',
      isOwned: false,
    ),
     ShopItem(
      id: 201,
      name: 'Minimalist White',
      type: 'furniture',
      slotType: 'furniture',
      price: 100,
      assetPath: 'assets/images/furniture/desk_1.webp',
      description: 'Clean lines for a clear mind.',
      isOwned: false,
    ),
     ShopItem(
      id: 202,
      name: 'Mahogany Executive',
      type: 'furniture',
      slotType: 'furniture',
      price: 100,
      assetPath: 'assets/images/furniture/desk_2.webp',
      description: 'Serious business.',
      isOwned: false,
    ),
     ShopItem(
      id: 203,
      name: 'Gamer Station',
      type: 'furniture',
      slotType: 'furniture',
      price: 100,
      assetPath: 'assets/images/furniture/desk_3.webp',
      description: 'RGB increases performance by 10%.',
      isOwned: false,
    ),

    // ❄️ WALL (AC / Climate)
    ShopItem(
      id: 300,
      name: 'Standard AC',
      type: 'furniture',
      slotType: 'wall_ac',
      price: 75,
      assetPath: 'assets/images/furniture/ac.webp',
      description: 'Keeps the room cool.',
      isOwned: false,
    ),
    ShopItem(
      id: 301,
      name: 'Industrial Climate Control',
      type: 'furniture',
      slotType: 'wall_ac',
      price: 75,
      assetPath: 'assets/images/furniture/ac_1.webp',
      description: 'Hospital-grade air filtration.',
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

class UserItem {
  final int id;
  final int itemId;
  final bool isPlaced;
  final String? placedAtSlot;
  // We can join with Item details in UI or Backend. 
  // For MVP, lets assume backend sends item details merged or we handle it.
  // The Backend inventory endpoint sends merged data (name, asset_path).
  final String name;
  final String assetPath;
  final String slotType;
  final int? x;
  final int? y;

  UserItem({
    required this.id, 
    required this.itemId, 
    required this.isPlaced, 
    this.placedAtSlot, 
    required this.name, 
    required this.assetPath, 
    required this.slotType,
    this.x,
    this.y,
  });

  factory UserItem.fromJson(Map<String, dynamic> json) {
    return UserItem(
      id: json['id'],
      itemId: json['item_id'],
      isPlaced: json['is_placed'] ?? false,
      placedAtSlot: json['placed_at_slot'],
      name: json['name'],
      assetPath: json['asset_path'] ?? '',
      slotType: json['slot_type'] ?? '',
      x: json['x'],
      y: json['y'],
    );
  }

  // 🎨 Visual Layering Logic (Duplicated from ShopItem for now for MVP)
  int get zIndex {
    switch (slotType) {
      case 'room': return 0;
      case 'floor_decor': return 10;
      case 'wall_decor': return 15; // Behind furniture, below AC
      case 'furniture': return 20; 
      case 'exam_table': return 25; 
      case 'tabletop': return 30;
      case 'wall_ac': return 40;
      case 'avatar': return 50;
      default: return 5;
    }
  }
}

class ShopProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  List<ShopItem> _catalog = [];
  List<UserItem> _inventory = [];
  List<UserItem> _visitedInventory = [];
  bool _isLoading = false;
  String? _errorMessage;
  
  // Smart Shop State
  bool _isDecorating = false;
  ShopItem? _previewItem;
  int? _previewX;
  int? _previewY;

  List<ShopItem> get catalog => _catalog;
  List<UserItem> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  
  bool get isDecorating => _isDecorating;
  ShopItem? get previewItem => _previewItem;
  int? get previewX => _previewX;
  int? get previewY => _previewY;

  // Buddy State
  int _buddyX = 0;
  int _buddyY = 0;
  bool _isBuddyWalking = false;
  bool _isBuddyHappy = false;

  bool _isFullPreviewMode = false;
  String? _lastSlotType;
  int? _lastTargetX;
  int? _lastTargetY;

  int get buddyX => _buddyX;
  int get buddyY => _buddyY;
  bool get isBuddyWalking => _isBuddyWalking;
  bool get isBuddyHappy => _isBuddyHappy;
  bool get isFullPreviewMode => _isFullPreviewMode;
  String? get lastSlotType => _lastSlotType;
  int? get lastTargetX => _lastTargetX;
  int? get lastTargetY => _lastTargetY;

  void toggleFullPreview(bool active, {String? slotType, int? x, int? y}) {
    _isFullPreviewMode = active;
    if (slotType != null) _lastSlotType = slotType;
    if (x != null) _lastTargetX = x;
    if (y != null) _lastTargetY = y;
    notifyListeners();
  }

  // 👻 GHOST / DECORATE LOGIC
  
  // Define the fixed "Perfect" slots for the room (Grid Coords)
  // We use these to generate ghosts for empty spots.
  static final List<Map<String, dynamic>> _availableSlots = [
    {'slot': 'furniture', 'x': 0, 'y': 2, 'name': 'Desk Slot'},
    {'slot': 'exam_table', 'x': 2, 'y': -1, 'name': 'Clinical Bay'},
    {'slot': 'wall_ac', 'x': 1, 'y': 2, 'name': 'Ventilation'},
    {'slot': 'wall_decor', 'x': 0, 'y': 2, 'name': 'Wall Decoration'},
    {'slot': 'window', 'x': 3, 'y': 2, 'name': 'Window View'},
  ];

  final Map<String, ShopItem> _cachedGhosts = {};

  /// Returns a list of "Ghost" items for empty slots.
  /// If a slot is empty, we pick a random item from the catalog to show as a preview.
  List<ShopItem> getGhostItems() {
    if (!_isDecorating) return [];

    List<ShopItem> ghosts = [];

    for (var slotDef in _availableSlots) {
      String type = slotDef['slot'];

      // 1. Check if ANY item is placed at this slot type (or exact coord?)
      // For MVP, we limit by 'slotType' uniqueness (1 desktop, 1 AC, etc.)
      bool isOccupied = _inventory.any((i) => i.isPlaced && i.slotType == type);
      
      // If user has placed something, we don't show a ghost (the placed item is there)
      if (!isOccupied) {
        // 2. Get a random ghost for this slot
        // Check cache first to prevent flickering
        if (!_cachedGhosts.containsKey(type)) {
           ShopItem? randomPick = _getRandomItemForSlot(type);
           if (randomPick != null) {
             _cachedGhosts[type] = randomPick;
           }
        }
        
        if (_cachedGhosts.containsKey(type)) {
          // Return the cached ghost item, but ensure we patch its X/Y for rendering
          // We can't mutate ShopItem (final), so we wrap or use it as is?
          // ShopItem doesn't hold X/Y usually, UserItem does.
          // But ShopLayout/Renderer might need to know WHERE to put it.
          // The Renderer usually stacks full-screen images.
          // If the asset is pre-rendered full screen, X/Y doesn't matter for rendering!
          // BUT for the "Interactive Overlay" (click target), we need X/Y.
          // We'll attach the X/Y metadata via a map or wrapper in the UI.
          ghosts.add(_cachedGhosts[type]!);
        }
      }
    }
    return ghosts;
  }
  
  ShopItem? _getRandomItemForSlot(String slotType) {
    // Filter catalog for this slot
    // We can use the hardcoded static one or the fetched one
    final candidates = ShopCatalog.items.where((i) => i.slotType == slotType).toList();
    if (candidates.isEmpty) return null;
    
    final r = math.Random();
    return candidates[r.nextInt(candidates.length)];
  }

  /// Helper to get the X/Y for a specific slot type (for the Overlay)
  Map<String, int>? getSlotCoords(String slotType) {
    try {
      final slot = _availableSlots.firstWhere((s) => s['slot'] == slotType);
      return {'x': slot['x'], 'y': slot['y']};
    } catch (_) {
      return null;
    }
  }

  void startBuddyWander() {
    // Basic Wander Logic (Random movement every 10s)
    // To avoid multiple timers, we can check if one exists or just let it run.
    // For MVP, we'll call this once when RoomWidget builds.
    Stream.periodic(const Duration(seconds: 8)).listen((_) {
      _moveBuddyRandomly();
    });
  }

  void _moveBuddyRandomly() {
    // Standard isometric hexagon floor is roughly -4 to 4 in both directions.
    // We pick a spot that is "on the floor".
    final random = math.Random();
    
    // For the hexagonal floor, positive X and Y keep Hemmy on the brown section.
    // Range 1-4 keeps him inside the red floor rectangle, avoiding the walls (0) and edges (5+).
    _buddyX = random.nextInt(4) + 1; // 1 to 4
    _buddyY = random.nextInt(4) + 1; // 1 to 4
    
    _isBuddyWalking = true;
    notifyListeners();
    
    // Reset walking state after transit (matches RoomWidget AnimatedPositioned duration)
    Timer(const Duration(seconds: 2), () {
      _isBuddyWalking = false;
      notifyListeners();
    });
  }

  void triggerBuddyHappy() {
    _isBuddyHappy = true;
    notifyListeners();
    Future.delayed(const Duration(seconds: 2), () {
      _isBuddyHappy = false;
      notifyListeners();
    });
  }

  // Avatar State: Derived from Inventory
  Map<String, UserItem?> get avatarConfig {
    final config = <String, UserItem?>{
      'skin_color': null,
      'body': null,
      'head': null,
      'hand': null,
    };
    
    // Find equipped skins
    // Currently `placedAtSlot` holds 'head', 'body' etc if it is an avatar item
    // And `placedAtRoomId` might be special or just check `slotType` if we map it correctly.
    // Let's assume for MVP: if `isPlaced` and `slotType` matches avatar slots, it's equipped.
    // NOTE: BE sets `placed_at_slot` to the slot name.
    
    final items = _visitedInventory.isNotEmpty ? _visitedInventory : _inventory;
    
    for (var item in items) {
      if (item.isPlaced && _isAvatarSlot(item.slotType)) {
        config[item.slotType] = item;
      }
    }
    return config;
  }

  // 🏠 Room Rendering Helpers
  
  /// Get the currently equipped Room background item
  ShopItem get currentRoom {
    final items = _visitedInventory.isNotEmpty ? _visitedInventory : _inventory;
    try {
      final roomItem = items.firstWhere((i) => i.isPlaced && i.slotType == 'room');
      // Convert UserItem to ShopItem for renderer
      return ShopItem(
        id: roomItem.itemId,
        name: roomItem.name,
        type: 'room',
        slotType: 'room',
        price: 0,
        assetPath: roomItem.assetPath,
        description: '',
        isOwned: true,
      );
    } catch (_) {
      // Default Room if none equipped
      return ShopCatalog.items.firstWhere((i) => i.id == 100);
    }
  }

  /// Get all placed furniture/decor as ShopItems (for the Renderer)
  List<ShopItem> get equippedItemsAsShopItems {
    final items = _visitedInventory.isNotEmpty ? _visitedInventory : _inventory;
    return items
        .where((i) => i.isPlaced && i.slotType != 'room')
        .map((u) => ShopItem(
              id: u.itemId,
              name: u.name,
              type: 'furniture', // Simplified
              slotType: u.slotType,
              price: 0,
              assetPath: u.assetPath,
              description: '',
              isOwned: true,
            ))
        .toList();
  }

  bool _isAvatarSlot(String slot) {
    return ['skin_color', 'body', 'head', 'hand'].contains(slot);
  }

  /// Checks if a medical item of the specified slotType is already placed.
  /// Used for auto-hiding Ghost Blueprints.
  bool isItemTypePlaced(String slotType) {
    return _inventory.any((item) => item.isPlaced && item.slotType == slotType);
  }

  void toggleDecorateMode() {
    _isDecorating = !_isDecorating;
    
    // Clean start: No auto-previews to avoid duplicate/floating assets
    _previewItem = null;
    _previewX = null;
    _previewY = null;
    
    notifyListeners();
  }

  void setPreviewItem(ShopItem? item, {int? x, int? y}) {
    _previewItem = item;
    _previewX = x;
    _previewY = y;
    debugPrint("👀 PREVIEW SET: ${item?.name} at ($x, $y)");
    notifyListeners();
  }

  Future<void> fetchCatalog({String? slotType, String? theme}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      String endpoint = '/shop/items?';
      if (slotType != null) endpoint += 'slot_type=$slotType&';
      if (theme != null) endpoint += 'theme=$theme&';
      
      final List<dynamic> data = await _apiService.get(endpoint);
      _catalog = data.map((json) => ShopItem.fromJson(json)).toList();
      
      // Smart Sort: Owned items first, then by price
      _catalog.sort((a, b) {
        if (a.isOwned && !b.isOwned) return -1;
        if (!a.isOwned && b.isOwned) return 1;
        return a.price.compareTo(b.price);
      });
      
    } catch (e) {
      debugPrint('Fetch catalog error: $e');
      _errorMessage = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchInventory() async {
    try {
      final List<dynamic> data = await _apiService.get('/shop/inventory');
      _inventory = data.map((json) => UserItem.fromJson(json)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Fetch inventory error: $e');
    }
  }

  Future<void> fetchRemoteInventory(int userId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final List<dynamic> data = await _apiService.get('/shop/inventory?userId=$userId');
      _visitedInventory = data.map((json) => UserItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Fetch remote inventory error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearVisitedInventory() {
    _visitedInventory = [];
    notifyListeners();
  }

  Future<bool> buyItem(int itemId, BuildContext context) async {
    try {
      await _apiService.post('/shop/buy', {'itemId': itemId});
      
      // Refresh user balance
      if (context.mounted) {
        await Provider.of<AuthProvider>(context, listen: false).refreshUser();
      }
      
      await fetchInventory(); // Refresh owned items
      return true;
    } catch (e) {
      debugPrint('Buy item error: $e');
      return false;
    }
  }

  Future<bool> equipItem(int userItemId, String slot, int roomId, {int? x, int? y}) async {
    try {
      debugPrint('🔍 Equipping item: userItemId=$userItemId, slot=$slot, roomId=$roomId, x=$x, y=$y');
      await _apiService.post('/shop/equip', {
        'userItemId': userItemId, 
        'slot': slot,
        'roomId': roomId,
        'x': x,
        'y': y
      });
      debugPrint('✅ Equip API call successful, fetching inventory...');
      await fetchInventory(); // Refresh state
      debugPrint('✅ Inventory refreshed. Total items: ${_inventory.length}');
      for (var item in _inventory.where((i) => i.isPlaced)) {
        debugPrint('  Placed: ${item.name}, Slot: ${item.slotType}, Pos: (${item.x}, ${item.y})');
      }
      return true;
    } catch (e) {
      debugPrint('❌ Equip error: $e');
      return false;
    }
  }

  Future<bool> unequipItem(int userItemId) async {
    try {
      await _apiService.post('/shop/unequip', {'userItemId': userItemId});
      await fetchInventory(); // Refresh owned items
      return true;
    } catch (e) {
      debugPrint('Unequip item error: $e');
      return false;
    }
  }
}
