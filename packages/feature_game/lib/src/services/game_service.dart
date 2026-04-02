import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:core_interop/core_interop.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:drift/drift.dart';

class GameService extends ChangeNotifier implements GameContract {
  final AppDatabase _db;
  final StudentContract _student = GetIt.I<StudentContract>();
  
  List<FurnitureItem> _catalog = [];
  List<FurnitureItem> _ownedItems = [];
  Map<String, String> _currentLayout = {};
  bool _isLoading = false;

  GameService(this._db) {
    _init();
  }

  Future<void> _init() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      await _loadCatalog();
      await _refreshState();
    } catch (e) {
      debugPrint("GameService init error: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadCatalog() async {
    try {
      final String response = await rootBundle.loadString('packages/arbormed_core/assets/data/shop_manifest.json');
      final data = json.decode(response);
      final list = data['items'] as List;
      final defaults = data['defaults'] as Map<String, dynamic>;
      
      _catalog = list.map((e) => FurnitureItem.fromJson(e, defaults)).toList();
    } catch (e) {
      debugPrint('Error loading shop manifest: $e');
    }
  }

  Future<void> _refreshState() async {
    final list = await _db.select(_db.furniture).get();
    
    // ⚡ Bolt: Replace O(N*M) linear scan with O(1) Map lookup
    // What: Build a map of the catalog by ID to avoid scanning it repeatedly
    // Why: `firstWhere` inside a `.map` over the owned items causes an O(N*M) performance penalty.
    // Impact: Reduces complexity from O(N*M) to O(N+M), significantly improving refresh time.
    // Measurement: Compare execution time of _refreshState before and after optimization.
    final catalogMap = { for (var item in _catalog) item.id: item };

    // Map list back to domain items
    _ownedItems = list.where((c) => !c.isLocked).map((c) {
      final catalogItem = catalogMap[c.slug] ?? FurnitureItem(
        id: c.slug,
        numericId: 0,
        name: c.nameEn ?? '',
        price: c.price,
        type: c.type ?? '',
        slotType: 'unknown',
        assetPath: c.assetPath ?? ''
      );
      return catalogItem;
    }).toList();

    // Map placed items to layout
    _currentLayout = {
      for (var c in list.where((c) => c.isPlaced))
        c.type ?? '': c.slug
    };
    
    notifyListeners();
  }

  @override
  List<FurnitureItem> get catalog => _catalog;

  @override
  List<FurnitureItem> get ownedItems => _ownedItems;

  @override
  Map<String, String> get currentLayout => _currentLayout;

  @override
  bool get isLoading => _isLoading;

  @override
  Future<List<FurnitureItem>> fetchCatalog() async {
    if (_catalog.isEmpty) await _loadCatalog();
    return _catalog;
  }

  @override
  Future<List<FurnitureItem>> fetchInventory() async {
    await _refreshState();
    return _ownedItems;
  }

  @override
  Future<Map<String, String>> fetchRoomLayout() async {
    await _refreshState();
    return _currentLayout;
  }

  @override
  Future<bool> purchaseItem(String id) async {
    final item = _catalog.firstWhere((i) => i.id == id);
    final wallet = await _student.getCoins();
    
    if (wallet < item.price) return false;

    // Persist ownership in Drift
    var entry = await (_db.select(_db.furniture)..where((t) => t.slug.equals(id))).getSingleOrNull();
    
    if (entry == null) {
      await _db.into(_db.furniture).insert(FurnitureCompanion.insert(
        slug: id,
        nameEn: Value(item.name),
        assetPath: Value(item.assetPath),
        type: Value(item.slotType),
        price: Value(item.price),
        isLocked: const Value(false),
        unlockedAt: Value(DateTime.now()),
      ));
    } else {
      await (_db.update(_db.furniture)..where((t) => t.slug.equals(id))).write(
        FurnitureCompanion(
          isLocked: const Value(false),
          unlockedAt: Value(DateTime.now()),
        )
      );
    }
    
    await _student.addCoins(-item.price);
    await _refreshState();
    return true;
  }

  @override
  Future<void> saveRoomLayout(Map<String, String> layout) async {
    // 1. Clear old placement for these slots (types)
    final types = layout.keys.toList();
    
    await (_db.update(_db.furniture)..where((t) => t.isPlaced.equals(true) & t.type.isIn(types)))
      .write(const FurnitureCompanion(isPlaced: Value(false)));

    // 2. Place new items
    for (var entry in layout.entries) {
      await (_db.update(_db.furniture)..where((t) => t.slug.equals(entry.value)))
        .write(FurnitureCompanion(
          isPlaced: const Value(true),
          type: Value(entry.key),
        ));
    }

    await _refreshState();
  }
}
