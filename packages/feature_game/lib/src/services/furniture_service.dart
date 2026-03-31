import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:get_it/get_it.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class FurnitureService extends ChangeNotifier {
  final Isar _isar;
  final StudentContract _studentContract = GetIt.I<StudentContract>();

  List<FurnitureCollection> _items = [];
  
  FurnitureService(this._isar);

  List<FurnitureCollection> get items => _items;

  Future<void> loadItems() async {
    _items = await _isar.furnitureCollections.where().findAll();
    notifyListeners();
  }

  Future<void> updatePosition(String slug, double x, double y) async {
    final item = await _isar.furnitureCollections.filter().slugEqualTo(slug).findFirst();
    if (item == null) return;

    item.x = x;
    item.y = y;
    item.isPlaced = true;

    await _isar.writeTxn(() async {
      await _isar.furnitureCollections.put(item);
    });
    
    await loadItems();
  }

  Future<bool> buyItem(String slug) async {
    final item = await _isar.furnitureCollections.filter().slugEqualTo(slug).findFirst();
    if (item == null || !item.isLocked) return false;

    final currentCoins = await _studentContract.getCoins();
    if (currentCoins < item.price) return false;

    await _studentContract.addCoins(-item.price);
    
    item.isLocked = false;
    await _isar.writeTxn(() async {
      await _isar.furnitureCollections.put(item);
    });

    await loadItems();
    return true;
  }
}
