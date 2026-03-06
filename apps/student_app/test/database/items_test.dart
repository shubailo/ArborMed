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

  group('Items Table Tests', () {
    test('can insert and read an item', () async {
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              serverId: const drift.Value(1),
              name: const drift.Value('Cool Desk'),
              type: const drift.Value('furniture'),
              slotType: const drift.Value('floor'),
              price: const drift.Value(100),
              assetPath: const drift.Value('assets/desk.png'),
              description: const drift.Value('A very cool desk'),
              theme: const drift.Value('modern'),
              isPremium: const drift.Value(true),
            ),
          );

      final item = await (db.select(db.items)..where((t) => t.id.equals(itemId))).getSingle();

      expect(item.id, itemId);
      expect(item.serverId, 1);
      expect(item.name, 'Cool Desk');
      expect(item.type, 'furniture');
      expect(item.slotType, 'floor');
      expect(item.price, 100);
      expect(item.assetPath, 'assets/desk.png');
      expect(item.description, 'A very cool desk');
      expect(item.theme, 'modern');
      expect(item.isPremium, true);
    });

    test('default values are applied correctly', () async {
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              serverId: const drift.Value(2),
            ),
          );

      final item = await (db.select(db.items)..where((t) => t.id.equals(itemId))).getSingle();

      expect(item.isPremium, false); // Default from boolean().withDefault(const Constant(false))()
    });

    test('unique constraint on serverId prevents duplicates', () async {
      await db.into(db.items).insert(
            ItemsCompanion.insert(
              serverId: const drift.Value(3),
            ),
          );

      expect(
        () => db.into(db.items).insert(
              ItemsCompanion.insert(
                serverId: const drift.Value(3),
              ),
            ),
        throwsA(isA<SqliteException>()),
      );
    });

    test('can update an item', () async {
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              serverId: const drift.Value(4),
              name: const drift.Value('Old Chair'),
            ),
          );

      await (db.update(db.items)..where((t) => t.id.equals(itemId))).write(
        const ItemsCompanion(
          name: drift.Value('New Chair'),
        ),
      );

      final item = await (db.select(db.items)..where((t) => t.id.equals(itemId))).getSingle();

      expect(item.name, 'New Chair');
    });

    test('can delete an item', () async {
      final itemId = await db.into(db.items).insert(
            ItemsCompanion.insert(
              serverId: const drift.Value(5),
            ),
          );

      var count = await db.select(db.items).get().then((v) => v.length);
      expect(count, 1);

      await (db.delete(db.items)..where((t) => t.id.equals(itemId))).go();

      count = await db.select(db.items).get().then((v) => v.length);
      expect(count, 0);
    });
  });
}
