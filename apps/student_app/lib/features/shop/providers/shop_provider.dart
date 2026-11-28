import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math' as math;
import 'package:collection/collection.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:drift/drift.dart' as drift;
import 'package:arbor_med/services/api_service.dart';
import '../../../database/database.dart';
import '../../../core/api_endpoints.dart';

// Models
import 'package:arbor_med/features/shop/models/shop_item.dart';
import 'package:arbor_med/features/shop/models/generated_shop_catalog.dart';
import 'package:arbor_med/features/shop/models/shop_user_item.dart';

// Re-export models so existing importers don't break
export 'package:arbor_med/features/shop/models/shop_item.dart';
export 'package:arbor_med/features/shop/models/generated_shop_catalog.dart';
export 'package:arbor_med/features/shop/models/shop_user_item.dart';

class ShopProvider with ChangeNotifier {
  static final ShopProvider _instance = ShopProvider._(ApiService(), AppDatabase());
  factory ShopProvider() => _instance;
  ShopProvider._(this._apiService, this._db);
  @visibleForTesting
  ShopProvider.forTesting(ApiService api, AppDatabase db) : this._(api, db);

  final ApiService _apiService;
  final AppDatabase _db;
  final Set<int> _pendingPurchases = {};
  int? _owner;
  int _generation = 0;
  int _catalogRequest = 0;
  int _inventoryRequest = 0;
  int _placementRevision = 0;
  final Set<int> _pendingPlacements = {};
  Future<void> _placementSync = Future.value();
  (int?, int) get _account => (_apiService.userId, _generation);

  void setAccount(int? userId) {
    if (_owner == userId) return;
    _owner = userId;
    resetState();
  }

  List<ShopItem> _catalog = [];
  List<ShopUserItem> _inventory = [];
  List<ShopUserItem> _visitedInventory = [];
  bool _isLoading = false;
  bool _isVisitLoading = false;
  int _visitRequest = 0;
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
  bool get isLoading => _isLoading || _isVisitLoading || _pendingPurchases.isNotEmpty;
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


  bool _isFullPreviewMode = false;
  String? _lastSlotType;
  int? _lastTargetX;
  int? _lastTargetY;

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
    final candidates = GeneratedShopCatalog.items
        .where((i) => i.slotType == slotType)
        .toList();
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
    // Disabled: Med Buddy character has been removed
  }

  void triggerBuddyHappy() {}

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
      if (_visitedInventory.isEmpty) {
        return GeneratedShopCatalog.items.firstWhere((i) => i.id == 100);
      }
      try {
        final roomItem = _visitedInventory.firstWhere(
          (i) => i.isPlaced && i.slotType == 'room',
        );
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

    // Default: My Room (Dynamic based on Rank)
    try {
      final roomItem = _inventory.firstWhere(
        (i) => i.isPlaced && i.slotType == 'room',
      );
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
      // 🧬 Rank-based automatic room upgrade fallback
      // 100: Default, 101: Resident Suite, 102: Chief Office
      int defaultId = 100;
      
      // We can't easily access AuthProvider here without context or proxy,
      // but we can assume ID 100 is the starter.
      // In a real scenario, we'd use ProxyProvider to pass rank here.
      return GeneratedShopCatalog.items.firstWhere((i) => i.id == defaultId);
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
        .map(
          (u) => ShopItem(
            id: u.itemId,
            name: u.name,
            type: 'furniture',
            slotType: u.slotType,
            price: 0,
            assetPath: u.assetPath,
            description: '',
            isOwned: true,
            userItemId: u.id,
            gridCell: u.usesGrid && u.x != null && u.y != null ? (u.x!, u.y!) : null,
            placementSlot: u.placedAtSlot,
          ),
        )
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
    final request = ++_catalogRequest;
    _isLoading = true;
    _errorMessage = null;
    final account = _account;
    _currentSlotType = slotType;
    _currentTheme = theme;
    notifyListeners();

    try {
      await _loadCatalogFromLocal(slotType: slotType, theme: theme);
      if (_account != account || request != _catalogRequest || account.$1 == null) return;

      String endpoint = '${ApiEndpoints.shopCatalog}?';
      if (slotType != null) endpoint += 'slot_type=$slotType&';
      if (theme != null) endpoint += 'theme=$theme&';

      final List<dynamic> data = await _apiService.get(endpoint);
      if (_account != account || request != _catalogRequest) return;
      final remoteItems = data.map((json) => ShopItem.fromJson(json)).toList();

      await _syncCatalogToLocal(remoteItems);
      if (_account != account || request != _catalogRequest) return;
      await _loadCatalogFromLocal(slotType: slotType, theme: theme);
    } catch (e) {
      debugPrint('Fetch remote catalog error: $e');
    } finally {
      if (_account == account && request == _catalogRequest) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> _loadCatalogFromLocal({String? slotType, String? theme}) async {
    final account = _account;
    final request = _catalogRequest;
    final query = _db.select(_db.items);

    if (slotType != null) {
      query.where((t) => t.slotType.equals(slotType));
    }
    if (theme != null) {
      query.where((t) => t.theme.equals(theme));
    }

    final locals = await query.get();

    final userId = account.$1;

    final catalog = locals
        .where((row) => row.price != null && row.description != 'Cached from inventory')
        .map(
          (l) => ShopItem(
            id: l.serverId ?? 0,
            name: l.name ?? '',
            type: l.type ?? '',
            slotType: l.slotType ?? '',
            price: l.price ?? 0,
            assetPath: l.assetPath ?? '',
            description: l.description ?? '',
            theme: l.theme,
            isOwned: false,
          ),
        )
        .toList();

    final localInventory = userId != null
        ? await (_db.select(
            _db.userItems,
          )..where((t) => t.userId.equals(userId))).get()
        : [];

    // ⚡ Bolt: Pre-compute inventory into a map instead of searching via .any and .firstWhere in O(N*M)
    final Map<int?, int> localInventoryMap = {};
    for (var inv in localInventory) {
      if (inv.itemId != null) {
        localInventoryMap[inv.itemId] = inv.id;
      }
    }

    if (_account != account || request != _catalogRequest) return;
    _catalog = catalog.map((item) {
      final int? userItemId = localInventoryMap[item.id];
      final bool owned = userItemId != null;
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
        userItemId: userItemId,
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

  Future<void> fetchInventory({bool notify = true}) => _fetchInventory(notify: notify);

  Future<void> _fetchInventory({bool notify = true, bool preservePlacement = false}) async {
    final request = ++_inventoryRequest;
    final placementRevision = _placementRevision;
    _isLoading = true;
    if (notify) notifyListeners();

    final account = _account;
    bool current() => _account == account && request == _inventoryRequest;
    bool canMerge() => current() && (preservePlacement ||
        (_pendingPlacements.isEmpty && placementRevision == _placementRevision));
    final userId = account.$1;
    if (userId == null) {
      _isLoading = false;
      if (notify) notifyListeners();
      return;
    }

    try {
      await _loadInventoryFromLocal(userId, notify: false);
      if (!canMerge()) return;
      final List<dynamic> data = await _apiService.get(
        ApiEndpoints.shopInventory,
      );
      if (!canMerge()) return;
      final remoteInventory = data
          .map((json) => ShopUserItem.fromJson(json))
          .toList();

      await _db.transaction(() async {
        if (canMerge()) {
          await _syncInventoryToLocal(userId, remoteInventory,
              preservePlacement: preservePlacement, canMerge: canMerge);
        }
      });
      if (!current()) return;
      await _loadInventoryFromLocal(userId, notify: false);
    } catch (e) {
      debugPrint('Fetch remote inventory error: $e');
    } finally {
      if (current()) {
        _isLoading = false;
        if (notify) notifyListeners();
      }
    }
  }

  Future<void> _loadInventoryFromLocal(int userId, {bool notify = true}) async {
    final account = _account;
    final request = _inventoryRequest;
    if (account.$1 != userId) return;
    final locals = await (_db.select(
      _db.userItems,
    )..where((t) => t.userId.equals(userId))).get();

    final inventory = <ShopUserItem>[];
    for (var l in locals) {
      if (l.itemId == null) continue;
      final itemDetails = await (_db.select(
        _db.items,
      )..where((t) => t.serverId.equals(l.itemId!))).getSingleOrNull();

      String name = itemDetails?.name ?? '';
      String assetPath = itemDetails?.assetPath ?? '';
      String slotType = itemDetails?.slotType ?? (l.slot ?? '');

      if (name.isEmpty || assetPath.isEmpty || slotType.isEmpty) {
        final catalogMatch =
            GeneratedShopCatalog.items.firstWhereOrNull((i) => i.id == l.itemId);
        if (catalogMatch != null) {
          if (name.isEmpty) name = catalogMatch.name;
          if (assetPath.isEmpty) assetPath = catalogMatch.assetPath;
          if (slotType.isEmpty) slotType = catalogMatch.slotType;
        }
      }

      inventory.add(
        ShopUserItem(
          id: l.id, // LOCAL DB ID
          serverId: l.serverId,
          itemId: l.itemId ?? 0,
          isPlaced: l.isPlaced,
          usesGrid: l.usesGrid,
          placedAtSlot: l.slot,
          name: name.isNotEmpty ? name : 'Item ${l.itemId}',
          assetPath: assetPath,
          slotType: slotType,
          x: l.xPos,
          y: l.yPos,
          roomId: l.roomId,
        ),
      );
    }
    if (_account != account || request != _inventoryRequest) return;
    _inventory = inventory;
    if (notify) notifyListeners();
  }

  Future<void> _syncInventoryToLocal(
    int userId,
    List<ShopUserItem> remoteInventory, {
    bool preservePlacement = false,
    required bool Function() canMerge,
  }) async {
    // 1. Fetch current locals to find serverId-less matches (local purchases)
    final account = _account;
    final existingLocals = await (_db.select(_db.userItems)..where((t) => t.userId.equals(userId))).get();
    if (_account != account || account.$1 != userId || !canMerge()) return;
    // ⚡ Bolt: Group local items by serverId and itemId into O(1) Hash Maps
    // This replaces an O(N*M) linear array scan (.where().firstOrNull inside the loop)
    final Map<int, List<UserItem>> serverIdMap = {};
    final Map<int, List<UserItem>> itemIdMap = {};
    for (var l in existingLocals) {
      if (l.serverId != null) {
        serverIdMap.putIfAbsent(l.serverId!, () => []).add(l);
      } else if (l.itemId != null) {
        itemIdMap.putIfAbsent(l.itemId!, () => []).add(l);
      }
    }

    final Set<int> processedServerIds = {};

    await _db.batch((batch) {
      for (var item in remoteInventory) {
        // De-duplicate remote items to prevent multiple inserts for same server item id
        if (processedServerIds.contains(item.id)) continue;
        processedServerIds.add(item.id);

        // Inventory responses from older servers only have partial catalog metadata.
        // Preserve an existing catalog entry when its complete description is unavailable.
        if (item.price != null && item.type != null) {
          batch.insert(
            _db.items,
            ItemsCompanion.insert(
              serverId: Value(item.itemId),
              name: Value(item.name),
              type: Value(item.type),
              slotType: Value(item.slotType),
              price: Value(item.price),
              assetPath: Value(item.assetPath),
              description: Value(item.description),
              theme: Value(item.theme),
            ),
            mode: item.description == null && item.theme == null
                ? drift.InsertMode.insertOrIgnore
                : drift.InsertMode.insertOrReplace,
          );
        }

        // Find existing local row for this instance or item
        // Priority 1: Match by serverId
        // Priority 2: Match by itemId for local "dirty" items (serverId is NULL)
        UserItem? match;
        if (serverIdMap.containsKey(item.id) && serverIdMap[item.id]!.isNotEmpty) {
          match = serverIdMap[item.id]!.removeLast();
        } else if (itemIdMap.containsKey(item.itemId) && itemIdMap[item.itemId]!.isNotEmpty) {
          match = itemIdMap[item.itemId]!.removeLast();
        }

        if (match != null) {
          // Update existing row
          batch.update(
            _db.userItems,
            UserItemsCompanion(
              serverId: Value<int?>(item.id),
              isPlaced: preservePlacement ? const Value.absent() : Value(item.isPlaced),
              usesGrid: preservePlacement ? const Value.absent() : Value(item.usesGrid),
              slot: preservePlacement ? const Value.absent() : Value(item.placedAtSlot),
              xPos: preservePlacement ? const Value.absent() : Value(item.x ?? 0),
              yPos: preservePlacement ? const Value.absent() : Value(item.y ?? 0),
              roomId: preservePlacement ? const Value.absent() : Value(item.roomId),
            ),
            where: (t) => t.id.equals(match!.id) & t.userId.equals(userId),
          );
        } else {
          // New row
          batch.insert(
            _db.userItems,
            UserItemsCompanion.insert(
              userId: Value<int?>(userId),
              serverId: Value<int?>(item.id),
              itemId: Value<int?>(item.itemId),
              isPlaced: Value(item.isPlaced),
              usesGrid: Value(item.usesGrid),
              slot: Value(item.placedAtSlot),
              xPos: Value(item.x ?? 0),
              yPos: Value(item.y ?? 0),
              roomId: Value(item.roomId),
            ),
            mode: drift.InsertMode.insertOrIgnore,
          );
        }
      }
    });
  }

  Future<void> fetchRemoteInventory(int userId) async {
    final account = _account;
    final request = ++_visitRequest;
    bool current() => _account == account && request == _visitRequest;
    _isVisitLoading = true;
    _isVisiting = true;
    _visitedInventory = [];
    notifyListeners();
    try {
      final List<dynamic> data = await _apiService.get(
        '/shop/inventory?userId=$userId',
      );
      if (!current()) return;
      _visitedInventory = data
          .map((json) => ShopUserItem.fromJson(json))
          .toList();
    } catch (e) {
      if (current()) debugPrint('Fetch remote inventory error: ${e.runtimeType}');
    } finally {
      if (current()) {
        _isVisitLoading = false;
        notifyListeners();
      }
    }
  }

  void clearVisitedInventory() {
    _visitRequest++;
    _isVisitLoading = false;
    _visitedInventory = [];
    _isVisiting = false; // ✅ STOP VISITING (Return to my room)
    notifyListeners();
  }

  /// 🧹 Resets the in-memory state of the shop.
  /// Called during logout to ensure no data leaks to the next user.
  void resetState() {
    _generation++;
    _isVisiting = false;
    _isFullPreviewMode = false;
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
    _isVisitLoading = false;
    _pendingPurchases.clear();
    _pendingPlacements.clear();
    notifyListeners();
  }

  Future<bool> buyItem(int itemId, BuildContext context, {int? expectedPrice}) async {
    final account = _account;
    final userId = account.$1;
    if (userId == null || !_pendingPurchases.add(itemId)) return false;
    try {
      notifyListeners();

      // 1. Strict API-First Buy
      final response = await _apiService.post(ApiEndpoints.shopBuy, {
        'itemId': itemId,
        if (expectedPrice != null) 'expectedPrice': expectedPrice,
      });

      if (_account != account) return false;
      if (response == null || response['userItemId'] == null) {
        _errorMessage =
            "Purchase failed: ${response?['message'] ?? 'Unknown error'}";
        return false;
      }

      final newUserItemId = response['userItemId'];
      // Cache the purchase for the account that sent the request.
      await _db
          .into(_db.userItems)
          .insert(
            UserItemsCompanion.insert(
              userId: Value(userId),
              serverId: Value(newUserItemId),
              itemId: Value(itemId),
              isPlaced: const Value(false),
            ),
            mode: drift.InsertMode.insertOrIgnore,
          );
      if (_account != account) return false;
      await _loadInventoryFromLocal(userId, notify: false);
      if (_account != account) return false;
      await _loadCatalogFromLocal(
        slotType: _currentSlotType,
        theme: _currentTheme,
      );

      if (_account != account) return false;
      _errorMessage = null;
      notifyListeners();
      return true;
    } catch (e) {
      if (_account != account) return false;
      debugPrint('Buy item error: $e');
      _errorMessage = "Purchase failed. Please check your connection.";
      return false;
    } finally {
      if (_account == account) {
        _pendingPurchases.remove(itemId);
        notifyListeners();
      }
    }
  }

  Future<UserItem?> _ownedItem(int userId, int localId) =>
      (_db.select(_db.userItems)..where((t) => t.userId.equals(userId) & t.id.equals(localId))).getSingleOrNull();

  Future<bool> equipItem(int userItemId, String slot, int roomId, {int? x, int? y}) async {
    final account = _account;
    final userId = account.$1;
    if (userId == null || (x == null) != (y == null)) return false;
    final revision = ++_placementRevision;
    _pendingPlacements.add(revision);
    var queued = false;
    try {
      final changed = await _db.transaction(() async {
        final owned = await _ownedItem(userId, userItemId);
        if (_account != account || owned == null) return false;
        final conflicts = _db.update(_db.userItems)..where((t) => t.userId.equals(userId) & t.isPlaced.equals(true));
        if (x != null && y != null) {
          conflicts.where((t) => t.roomId.equals(roomId) & t.usesGrid.equals(true) & t.xPos.equals(x) & t.yPos.equals(y));
        } else {
          conflicts.where((t) => t.roomId.equals(roomId) & t.usesGrid.equals(false) & t.slot.equals(slot));
        }
        await conflicts.write(const UserItemsCompanion(isPlaced: Value(false), roomId: Value(null), usesGrid: Value(false)));
        await (_db.update(_db.userItems)..where((t) => t.id.equals(userItemId) & t.userId.equals(userId))).write(
          UserItemsCompanion(isPlaced: const Value(true), slot: Value(slot),
            xPos: Value(x ?? 0), yPos: Value(y ?? 0), roomId: Value(roomId),
            usesGrid: Value(x != null && y != null)),
        );
        return true;
      });
      if (!changed || _account != account) return false;
      _queuePlacement(account, revision, userId, userItemId, ApiEndpoints.shopEquip,
          {'roomId': roomId, 'slot': slot, 'x': x, 'y': y});
      queued = true;
      return await _refreshPlacement(account, userId);
    } catch (error) {
      debugPrint('Equip error: $error');
      return false;
    } finally {
      if (!queued) _pendingPlacements.remove(revision);
    }
  }

  Future<bool> unequipItem(int userItemId) async {
    final account = _account;
    final userId = account.$1;
    if (userId == null) return false;
    final revision = ++_placementRevision;
    _pendingPlacements.add(revision);
    var queued = false;
    try {
      final changed = await _db.transaction(() async {
        if (_account != account) return 0;
        return (_db.update(_db.userItems)
              ..where((t) => t.id.equals(userItemId) & t.userId.equals(userId)))
            .write(const UserItemsCompanion(isPlaced: Value(false), roomId: Value(null), usesGrid: Value(false)));
      });
      if (changed == 0 || _account != account) return false;
      _queuePlacement(account, revision, userId, userItemId, ApiEndpoints.shopUnequip, {});
      queued = true;
      return await _refreshPlacement(account, userId);
    } catch (error) {
      debugPrint('Unequip error: $error');
      return false;
    } finally {
      if (!queued) _pendingPlacements.remove(revision);
    }
  }

  Future<bool> _refreshPlacement((int?, int) account, int userId) async {
    await _loadInventoryFromLocal(userId, notify: false);
    if (_account != account) return false;
    await _loadCatalogFromLocal(slotType: _currentSlotType, theme: _currentTheme);
    if (_account != account) return false;
    notifyListeners();
    return true;
  }

  void _queuePlacement((int?, int) account, int revision, int userId, int localId,
      String endpoint, Map<String, dynamic> fields) {
    _placementSync = _placementSync.then((_) async {
      var saved = false;
      try {
        if (_account != account) return;
        var item = await _ownedItem(userId, localId);
        if (_account != account || item == null) return;
        if (item.serverId == null) {
          await _fetchInventory(notify: false, preservePlacement: true);
          if (_account != account) return;
          item = await _ownedItem(userId, localId);
        }
        if (_account == account && item?.serverId != null) {
          await _apiService.post(endpoint, {...fields, 'userItemId': item!.serverId});
          saved = true;
        }
      } catch (error) {
        debugPrint('Background placement sync failed: ${error.runtimeType}');
      } finally {
        _pendingPlacements.remove(revision);
      }
      if (saved && _account == account && _pendingPlacements.isEmpty) {
        unawaited(fetchInventory());
      }
    });
  }

  @override
  void dispose() {
    _generation++;
    _pendingPlacements.clear();
    super.dispose();
  }
}
