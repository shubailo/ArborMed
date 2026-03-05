import 'package:drift/native.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/database/database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await db.close();
  });

  group('UserItems Table Tests', () {
    test('can insert and read a user item', () async {
      // 1. Insert a mock item into Items table first, since UserItem references it logically
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              serverId: const drift.Value(1),
              name: const drift.Value('Cool Desk'),
              type: const drift.Value('furniture'),
            ),
          );

      // 2. Insert a UserItem
      final userItemId = await db.into(db.userItems).insert(
            UserItemsCompanion.insert(
              userId: const drift.Value(42),
              itemId: drift.Value(itemId),
              isPlaced: const drift.Value(true),
              roomId: const drift.Value(1),
              slot: const drift.Value('floor'),
              xPos: const drift.Value(10),
              yPos: const drift.Value(20),
            ),
          );

      // 3. Read it back
      final item = await (db.select(db.userItems)..where((t) => t.id.equals(userItemId))).getSingle();

      expect(item.userId, 42);
      expect(item.itemId, itemId);
      expect(item.isPlaced, true);
      expect(item.roomId, 1);
      expect(item.slot, 'floor');
      expect(item.xPos, 10);
      expect(item.yPos, 20);
    });

    test('default values are applied correctly', () async {
      final userItemId = await db.into(db.userItems).insert(
            UserItemsCompanion.insert(),
          );

      final item = await (db.select(db.userItems)..where((t) => t.id.equals(userItemId))).getSingle();

      expect(item.isPlaced, false); // Default from boolean().withDefault(const Constant(false))()
      expect(item.xPos, 0); // Default from integer().withDefault(const Constant(0))()
      expect(item.yPos, 0); // Default from integer().withDefault(const Constant(0))()
    });

    test('clearUserData removes user items but keeps items', () async {
      // Insert item
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              name: const drift.Value('Item to keep'),
            ),
          );

      // Insert UserItem
      await db.into(db.userItems).insert(
            UserItemsCompanion.insert(
              userId: const drift.Value(1),
              itemId: drift.Value(itemId),
            ),
          );

      // Ensure they exist
      var userItemsCount = await db.select(db.userItems).get().then((v) => v.length);
      var itemsCount = await db.select(db.items).get().then((v) => v.length);

      expect(userItemsCount, 1);
      expect(itemsCount, 1);

      // Clear user data
      await db.clearUserData();

      // Verify user items are gone, items remain
      userItemsCount = await db.select(db.userItems).get().then((v) => v.length);
      itemsCount = await db.select(db.items).get().then((v) => v.length);

      expect(userItemsCount, 0);
      expect(itemsCount, 1);
    });
  });
}
