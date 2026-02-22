import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:drift/drift.dart' hide Column;
import 'package:drift/drift.dart' as drift;
import '../services/api_service.dart';
import '../database/database.dart';
import '../core/api_endpoints.dart';

// Models
import '../models/shop_item.dart';
import '../models/generated_shop_catalog.dart';
import '../models/shop_user_item.dart';

// Re-export models so existing importers don't break
export '../models/shop_item.dart';
export '../models/generated_shop_catalog.dart';
export '../models/shop_user_item.dart';

class ShopProvider with ChangeNotifier {
  static final ShopProvider _instance = ShopProvider._internal();
  factory ShopProvider() => _instance;
  ShopProvider._internal();

  final ApiService _apiService = ApiService();
  final AppDatabase _db = AppDatabase();

  List<ShopItem> _catalog = [];
  List<ShopUserItem> _inventory = [];
  List<ShopUserItem> _visitedInventory = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Track current catalog filters for reloads
  String? _currentSlotType;
  String? _currentTheme;

  // Smart Shop State
  bool _isDecorating = false;
  bool _isVisiting = false; // NEW: Track if we are explicitly visiting a friend
  ShopItem? _previewItem;
  int? _previewX;
  int? _previewY;

  List<ShopItem> get catalog => _catalog;
  List<ShopUserItem> get inventory => _inventory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Avatar State
  Map<String, dynamic>? _myAvatar;
  Map<String, dynamic>? _visitedAvatar;

  Map<String, dynamic>? get myAvatar => _myAvatar;
  Map<String, dynamic>? get visitedAvatar => _visitedAvatar;

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

  static final List<Map<String, dynamic>> _availableSlots = [
    {'slot': 'desk', 'x': 0, 'y': 2, 'name': 'Desk Slot'},
    {'slot': 'exam_table', 'x': 2, 'y': -1, 'name': 'Clinical Bay'},
    {'slot': 'desk_decor', 'x': 1, 'y': 2, 'name': 'Desk Decoration'},
    {'slot': 'window', 'x': 3, 'y': 2, 'name': 'Window View'},
    {'slot': 'corner_cabinet', 'x': 0, 'y': 0, 'name': 'Corner Storage'}, // New
    {'slot': 'rug', 'x': 2, 'y': 2, 'name': 'Floor Area'}, // New
  ];

  final Map<String, ShopItem> _cachedGhosts = {};

  List<ShopItem> getGhostItems() {
    if (!_isDecorating) return [];

    List<ShopItem> ghosts = [];

    for (var slotDef in _availableSlots) {
      String type = slotDef['slot'];
      bool isOccupied = _inventory.any((i) => i.isPlaced && i.slotType == type);

      if (!isOccupied) {
        if (!_cachedGhosts.containsKey(type)) {
          ShopItem? randomPick = _getRandomItemForSlot(type);
          if (randomPick != null) {
            _cachedGhosts[type] = randomPick;
          }
        }

        if (_cachedGhosts.containsKey(type)) {
          ghosts.add(_cachedGhosts[type]!);
        }
      }
    }
    return ghosts;
  }

  ShopItem? _getRandomItemForSlot(String slotType) {
    final candidates =
        GeneratedShopCatalog.items.where((i) => i.slotType == slotType).toList();
    if (candidates.isEmpty) return null;

    final r = math.Random();
    return candidates[r.nextInt(candidates.length)];
  }

  Map<String, int>? getSlotCoords(String slotType) {
    try {
      final slot = _availableSlots.firstWhere((s) => s['slot'] == slotType);
      return {'x': slot['x'], 'y': slot['y']};
    } catch (_) {
      return null;
    }
  }

  void startBuddyWander() {
    Stream.periodic(const Duration(seconds: 8)).listen((_) {
      _moveBuddyRandomly();
    });
  }

  void _moveBuddyRandomly() {
    final random = math.Random();
    _buddyX = random.nextInt(4) + 1; // 1 to 4
    _buddyY = random.nextInt(4) + 1; // 1 to 4

    _isBuddyWalking = true;
    notifyListeners();

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
  Map<String, ShopUserItem?> get avatarConfig {
    final config = <String, ShopUserItem?>{
      'skin_color': null,
      'body': null,
      'head': null,
      'hand': null,
    };

    // If visiting and empty, return empty config (default bean)
    if (_isVisiting && _visitedInventory.isEmpty) {
      return config;
    }

    final items = _isVisiting ? _visitedInventory : _inventory;

    for (var item in items) {
      if (item.isPlaced && _isAvatarSlot(item.slotType)) {
        config[item.slotType] = item;
      }
    }
    return config;
  }

  ShopItem get currentRoom {
    // If visiting, STRICTLY use visited usage. If empty, it means they have nothing equipped.
    if (_isVisiting) {
      // debugPrint("🔍 ShopProvider: currentRoom - Visiting Mode. Inventory size: ${_visitedInventory.length}");
      if (_visitedInventory.isEmpty) {
         return GeneratedShopCatalog.items.firstWhere((i) => i.id == 100);
      }
      try {
        final roomItem =
            _visitedInventory.firstWhere((i) => i.isPlaced && i.slotType == 'room');
        return ShopItem(
          id: roomItem.itemId,
          name: roomItem.name,
          type: 'room',
          slotType: 'room',
          price: 0,
          assetPath: roomItem.assetPath,
          description: '',
          isOwned: true,
          userItemId: roomItem.id,
        );
      } catch (_) {
        return GeneratedShopCatalog.items.firstWhere((i) => i.id == 100);
      }
    }

    // Default: My Room
    try {
      final roomItem =
          _inventory.firstWhere((i) => i.isPlaced && i.slotType == 'room');
      return ShopItem(
        id: roomItem.itemId,
        name: roomItem.name,
        type: 'room',
        slotType: 'room',
        price: 0,
        assetPath: roomItem.assetPath,
        description: '',
        isOwned: true,
        userItemId: roomItem.id, // Store unique instance ID
      );
    } catch (_) {
      return GeneratedShopCatalog.items.firstWhere((i) => i.id == 100);
    }
  }

  List<ShopItem> get equippedItemsAsShopItems {
    // If visiting and empty, return empty list (don't fallback to mine)
    if (_isVisiting && _visitedInventory.isEmpty) {
      return [];
    }

    final items = _isVisiting ? _visitedInventory : _inventory;
    final Map<int, ShopUserItem> uniqueItems = {};

    // De-duplicate by Local ID (PK) to prevent Stack collisions
    for (var item in items) {
      if (item.isPlaced && item.slotType != 'room') {
        uniqueItems[item.id] = item;
      }
    }

    return uniqueItems.values
        .map((u) => ShopItem(
              id: u.itemId,
              name: u.name,
              type: 'furniture',
              slotType: u.slotType,
              price: 0,
              assetPath: u.assetPath,
              description: '',
              isOwned: true,
              userItemId: u.id,
            ))
        .toList();
  }

  bool _isAvatarSlot(String slot) {
    return ['skin_color', 'body', 'head', 'hand'].contains(slot);
  }

  bool isItemTypePlaced(String slotType) {
    return _inventory.any((item) => item.isPlaced && item.slotType == slotType);
  }

  void toggleDecorateMode() {
    _isDecorating = !_isDecorating;
    _previewItem = null;
    _previewX = null;
    _previewY = null;
    notifyListeners();
  }

  void setPreviewItem(ShopItem? item, {int? x, int? y}) {
    _previewItem = item;
    _previewX = x;
    _previewY = y;
    notifyListeners();
  }

  Future<void> fetchCatalog({String? slotType, String? theme}) async {
    _isLoading = true;
    _errorMessage = null;
    _currentSlotType = slotType;
    _currentTheme = theme;
    notifyListeners();

    await _loadCatalogFromLocal(slotType: slotType, theme: theme);

    try {
      final userId = await _apiService.getCurrentUserId();
      if (userId == null) return;

      String endpoint = '${ApiEndpoints.shopCatalog}?';
      if (slotType != null) endpoint += 'slot_type=$slotType&';
      if (theme != null) endpoint += 'theme=$theme&';

      final List<dynamic> data = await _apiService.get(endpoint);
      final remoteItems = data.map((json) => ShopItem.fromJson(json)).toList();

      await _syncCatalogToLocal(remoteItems);
      await _loadCatalogFromLocal(slotType: slotType, theme: theme);
    } catch (e) {
      debugPrint('Fetch remote catalog error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCatalogFromLocal({String? slotType, String? theme}) async {
    final query = _db.select(_db.items);

    if (slotType != null) {
      query.where((t) => t.slotType.equals(slotType));
    }
    if (theme != null) {
      query.where((t) => t.theme.equals(theme));
    }

    final locals = await query.get();

    final userId = await _apiService.getCurrentUserId();

    _catalog = locals
        .map((l) => ShopItem(
              id: l.serverId ?? 0,
              name: l.name ?? '',
              type: l.type ?? '',
              slotType: l.slotType ?? '',
              price: l.price ?? 0,
              assetPath: l.assetPath ?? '',
              description: l.description ?? '',
              theme: l.theme,
              isOwned: false,
            ))
        .toList();

    final localInventory = userId != null
        ? await (_db.select(_db.userItems)
              ..where((t) => t.userId.equals(userId)))
            .get()
        : [];

    _catalog = _catalog.map((item) {
      final owned = localInventory.any((inv) => inv.itemId == item.id);
      return ShopItem(
        id: item.id,
        name: item.name,
        type: item.type,
        slotType: item.slotType,
        price: item.price,
        assetPath: item.assetPath,
        description: item.description,
        theme: item.theme,
        isOwned: owned,
        userItemId: owned
            ? localInventory.firstWhere((inv) => inv.itemId == item.id).id
            : null,
      );
    }).toList();

    _catalog.sort((a, b) {
      if (a.isOwned && !b.isOwned) return -1;
      if (!a.isOwned && b.isOwned) return 1;
      return a.price.compareTo(b.price);
    });
  }

  Future<void> _syncCatalogToLocal(List<ShopItem> remoteItems) async {
    await _db.batch((batch) {
      for (var item in remoteItems) {
        batch.insert(
          _db.items,
          ItemsCompanion.insert(
            serverId: Value(item.id),
            name: Value(item.name),
            type: Value(item.type),
            slotType: Value(item.slotType),
            price: Value(item.price),
            assetPath: Value(item.assetPath),
            description: Value(item.description),
            theme: Value(item.theme),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> fetchInventory({bool notify = true}) async {
    _isLoading = true;
    if (notify) notifyListeners();

    final userId = await _apiService.getCurrentUserId();
    if (userId == null) {
      _isLoading = false;
      if (notify) notifyListeners();
      return;
    }

    await _loadInventoryFromLocal(userId, notify: false);

    try {
      final List<dynamic> data = await _apiService.get(ApiEndpoints.shopInventory);
      final remoteInventory =
          data.map((json) => ShopUserItem.fromJson(json)).toList();

      await _syncInventoryToLocal(userId, remoteInventory);
      await _loadInventoryFromLocal(userId, notify: false);
    } catch (e) {
      debugPrint('Fetch remote inventory error: $e');
    } finally {
      _isLoading = false;
      if (notify) notifyListeners();
    }
  }

  Future<void> _loadInventoryFromLocal(int userId, {bool notify = true}) async {
    final locals = await (_db.select(_db.userItems)
          ..where((t) => t.userId.equals(userId)))
        .get();

    _inventory = [];
    for (var l in locals) {
      final itemDetails = await (_db.select(_db.items)
            ..where((t) => t.serverId.equals(l.itemId!)))
          .getSingleOrNull();
      _inventory.add(ShopUserItem(
        id: l.id, // LOCAL DB ID
        serverId: l.serverId,
        itemId: l.itemId ?? 0,
        isPlaced: l.isPlaced,
        placedAtSlot: l.slot,
        name: itemDetails?.name ?? 'Unknown',
        assetPath: itemDetails?.assetPath ?? '',
        slotType: itemDetails?.slotType ?? '',
        x: l.xPos,
        y: l.yPos,
        roomId: l.roomId,
      ));
    }
    if (notify) notifyListeners();
  }

  Future<void> _syncInventoryToLocal(
      int userId, List<ShopUserItem> remoteInventory) async {
    // 1. Fetch current locals to find serverId-less matches (local purchases)
    final existingLocals = await _db.select(_db.userItems).get();
    final List<UserItem> locallyTracked = List.from(existingLocals);
    final Set<int> processedServerIds = {};

    await _db.batch((batch) {
      for (var item in remoteInventory) {
        // De-duplicate remote items to prevent multiple inserts for same server item id
        if (processedServerIds.contains(item.id)) continue;
        processedServerIds.add(item.id);

        // 0. Sync/Cache Item Metadata (Ensures room works even if shop catalog wasn't synced)
        batch.insert(
          _db.items,
          ItemsCompanion.insert(
            serverId: Value<int?>(item.itemId),
            name: Value<String?>(item.name),
            type: const Value<String?>('furniture'),
            slotType: Value<String?>(item.slotType),
            price: const Value<int?>(0),
            assetPath: Value<String?>(item.assetPath),
            description: const Value<String?>('Cached from inventory'),
          ),
          mode: drift.InsertMode.insertOrReplace,
        );

        // Find existing local row for this instance or item
        // Priority 1: Match by serverId
        // Priority 2: Match by itemId for local "dirty" items (serverId is NULL)
        final match =
            locallyTracked.where((l) => l.serverId == item.id).firstOrNull ??
                locallyTracked
                    .where((l) => l.itemId == item.itemId && l.serverId == null)
                    .firstOrNull;

        if (match != null) {
          // Update existing row
          batch.update(
            _db.userItems,
            UserItemsCompanion(
              userId: Value<int?>(userId),
              serverId: Value<int?>(item.id),
              isPlaced: Value(item.isPlaced),
              slot: Value(item.placedAtSlot),
              xPos: Value(item.x ?? 0),
              yPos: Value(item.y ?? 0),
              roomId: Value(item.roomId),
            ),
            where: (t) => t.id.equals(match.id),
          );
          locallyTracked.remove(match);
        } else {
          // New row
          batch.insert(
            _db.userItems,
            UserItemsCompanion.insert(
              userId: Value<int?>(userId),
              serverId: Value<int?>(item.id),
              itemId: Value<int?>(item.itemId),
              isPlaced: Value(item.isPlaced),
              slot: Value(item.placedAtSlot),
              xPos: Value(item.x ?? 0),
              yPos: Value(item.y ?? 0),
              roomId: Value(item.roomId),
            ),
            mode: drift.InsertMode.insertOrReplace,
          );
        }
      }
    });
  }

  Future<void> fetchRemoteInventory(int userId) async {
    _isLoading = true;
    _isVisiting = true; // ✅ START VISITING
    notifyListeners();
    try {
      final List<dynamic> data =
          await _apiService.get('/shop/inventory?userId=$userId');
      _visitedInventory =
          data.map((json) => ShopUserItem.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Fetch remote inventory error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearVisitedInventory() {
    _visitedInventory = [];
    _isVisiting = false; // ✅ STOP VISITING (Return to my room)
    notifyListeners();
  }

  /// 🧹 Resets the in-memory state of the shop.
  /// Called during logout to ensure no data leaks to the next user.
  void resetState() {
    _catalog = [];
    _inventory = [];
    _visitedInventory = [];
    _cachedGhosts.clear();
    _previewItem = null;
    _isDecorating = false;
    _myAvatar = null;
    _visitedAvatar = null;
    _errorMessage = null;
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> buyItem(int itemId, BuildContext context) async {
    try {
      _isLoading = true;
      notifyListeners();

      // 1. Strict API-First Buy
      final response = await _apiService.post(ApiEndpoints.shopBuy, {
        'itemId': itemId,
      });

      if (response == null || response['userItemId'] == null) {
        _errorMessage =
            "Purchase failed: ${response?['message'] ?? 'Unknown error'}";
        return false;
      }

      final newUserItemId = response['userItemId'];
      final userId = await _apiService.getCurrentUserId();

      // 2. Local Cache Update (Insertion)
      if (userId != null) {
        await _db.into(_db.userItems).insert(
              UserItemsCompanion.insert(
                userId: Value(userId),
                serverId: Value(newUserItemId),
                itemId: Value(itemId),
                isPlaced: const Value(false),
              ),
            );
        await _loadInventoryFromLocal(userId, notify: false);
        await _loadCatalogFromLocal(
            slotType: _currentSlotType, theme: _currentTheme);
      }

      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Buy item error: $e');
      _errorMessage = "Purchase failed. Please check your connection.";
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> equipItem(int userItemId, String slot, int roomId,
      {int? x, int? y}) async {
    try {
      final userId = await _apiService.getCurrentUserId();
      if (userId == null) return false;

      // 1. Local Optimistic Update
      await _db.transaction(() async {
        // Unequip others in the same slot (or at same coordinates if x,y provided)
        if (x != null && y != null) {
          await (_db.update(_db.userItems)
                ..where((t) =>
                    t.roomId.equals(roomId) &
                    t.xPos.equals(x) &
                    t.yPos.equals(y)))
              .write(const UserItemsCompanion(
                  isPlaced: Value(false), roomId: Value(null)));
        } else {
          await (_db.update(_db.userItems)
                ..where((t) => t.slot.equals(slot) & t.isPlaced.equals(true)))
              .write(const UserItemsCompanion(isPlaced: Value(false)));
        }

        // Equip this one
        await (_db.update(_db.userItems)..where((t) => t.id.equals(userItemId)))
            .write(
          UserItemsCompanion(
            isPlaced: const Value(true),
            slot: Value(slot),
            xPos: Value(x ?? 0),
            yPos: Value(y ?? 0),
            roomId: Value(roomId),
          ),
        );
      });

      // Refresh memory state
      await _loadInventoryFromLocal(userId, notify: false);
      await _loadCatalogFromLocal(
          slotType: _currentSlotType, theme: _currentTheme);

      notifyListeners(); // Immediate UI update

      // 2. Background API Sync (Deep Sync)
      unawaited(() async {
        try {
          final localItem = await (_db.select(_db.userItems)
                ..where((t) => t.id.equals(userItemId)))
              .getSingleOrNull();
          if (localItem != null && localItem.serverId != null) {
            await _apiService.post(ApiEndpoints.shopEquip, {
              'userItemId': localItem.serverId,
              'roomId': roomId,
              'slot': slot,
              'x': x,
              'y': y,
            });
          }
        } catch (e) {
          debugPrint('Background equip failed: $e');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('Equip error: $e');
      return false;
    }
  }

  Future<bool> unequipItem(int userItemId) async {
    try {
      final userId = await _apiService.getCurrentUserId();
      if (userId == null) return false;

      // 1. Local Update
      await (_db.update(_db.userItems)..where((t) => t.id.equals(userItemId)))
          .write(
        const UserItemsCompanion(isPlaced: Value(false), roomId: Value(null)),
      );

      // Refresh memory state
      await _loadInventoryFromLocal(userId, notify: false);
      await _loadCatalogFromLocal(
          slotType: _currentSlotType, theme: _currentTheme);

      notifyListeners();

      // 2. Background API Sync
      unawaited(() async {
        try {
          final localItem = await (_db.select(_db.userItems)
                ..where((t) => t.id.equals(userItemId)))
              .getSingleOrNull();
          if (localItem != null && localItem.serverId != null) {
            await _apiService.post(ApiEndpoints.shopUnequip, {
              'userItemId': localItem.serverId,
            });
          }
        } catch (e) {
          debugPrint('Background unequip failed: $e');
        }
      }());

      return true;
    } catch (e) {
      debugPrint('Unequip item error: $e');
      return false;
    }
  }
}
