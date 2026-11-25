import 'dart:async';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/database/database.dart';
import 'package:arbor_med/features/shop/providers/shop_provider.dart';
import 'package:arbor_med/services/api_service.dart';

class ShopApi extends Fake implements ApiService {
  @override
  int? userId = 1;
  List<Map<String,dynamic>> items = [];
  Completer<dynamic>? deferred;
  final started = Completer<void>();
  final posts = <String>[];

  @override
  Future<dynamic> get(String endpoint) async {
    if (!started.isCompleted) started.complete();
    return deferred?.future ?? Future.value(items);
  }

  @override
  Future<dynamic> post(String endpoint, Map<String,dynamic> data) async {
    posts.add(endpoint);
    if (!started.isCompleted) started.complete();
    return deferred?.future ?? Future.value({});
  }
}
class TestContext extends Fake implements BuildContext {}

void main() {
  late AppDatabase db;
  late ShopApi api;
  late ShopProvider shop;
  Future<int> local(int user, int item, {bool placed=false, int? remote}) =>
      db.into(db.userItems).insert(UserItemsCompanion.insert(
        userId: Value(user), itemId: Value(item), serverId: Value(remote),
        slot: const Value('desk'), isPlaced: Value(placed), roomId: const Value(1),
      ));
  Future<UserItem> read(int id) =>
      (db.select(db.userItems)..where((t) => t.id.equals(id))).getSingle();
  Map<String,dynamic> remote(int id, int itemId) =>
      {'id':id,'item_id':itemId,'name':'Desk','slot_type':'desk'};

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    api = ShopApi();
    shop = ShopProvider.forTesting(api, db);
    shop.setAccount(1);
  });
  tearDown(() async { shop.dispose(); await db.close(); });

  test('matches an unstamped inventory item only for the active account', () async {
    final mine = await local(1,42);
    final other = await local(2,42);
    api.items = [remote(100,42)];
    await shop.fetchInventory();
    expect((await read(mine)).serverId, 100);
    expect((await read(other)).serverId, isNull);
    expect((await read(other)).userId, 2);
  });

  test('equipping only affects own slots and rejects a foreign local instance', () async {
    final target = await local(1,42,remote:100);
    final mine = await local(1,43,placed:true,remote:101);
    final other = await local(2,42,placed:true,remote:102);
    expect(await shop.equipItem(other, 'desk', 1), false);
    expect((await read(mine)).isPlaced, true);
    expect(await shop.unequipItem(other), false);
    expect(await shop.equipItem(target,'desk',1,x:0,y:0), true);
    await api.started.future;
    expect((await read(target)).isPlaced, true);
    expect((await read(mine)).isPlaced, false);
    expect((await read(other)).isPlaced, true);
    expect(api.posts, [ApiEndpoints.shopEquip]);
  });

  test('a late inventory response cannot recreate logged-out data or replace the next account', () async {
    api.deferred = Completer<dynamic>();
    final loading = shop.fetchInventory();
    await api.started.future;
    api.userId=2; shop.setAccount(2);
    api.deferred!.complete([remote(50,50)]);
    await loading;
    expect(await db.select(db.userItems).get(), isEmpty);
    expect(shop.inventory, isEmpty);
  });

  test('a late purchase does not assign an item to a subsequent account', () async {
    api.deferred=Completer<dynamic>();
    final purchasing=shop.buyItem(7, TestContext());
    await api.started.future;
    api.userId=2; shop.setAccount(2);
    api.deferred!.complete({'userItemId':10});
    expect(await purchasing, false);
    expect(await db.select(db.userItems).get(), isEmpty);
  });
  test('inventory sync preserves the global catalog price for the next account', () async {
    await db.into(db.items).insert(ItemsCompanion.insert(
      serverId: const Value(42), price: const Value(75), description: const Value('Catalog description'),
      name: const Value('Desk'), theme: const Value('clinical'),
    ));
    api.items = [remote(100,42)];
    await shop.fetchInventory();
    api.userId = 2; shop.setAccount(2);
    final entry = await (db.select(db.items)..where((row) => row.serverId.equals(42))).getSingle();
    expect(entry.price, 75);
    expect(entry.theme, 'clinical');
    expect(entry.description, 'Catalog description');
  });
}
