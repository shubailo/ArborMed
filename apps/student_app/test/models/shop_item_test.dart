import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/models/shop_item.dart';

void main() {
  group('ShopItem.fromJson', () {
    test('uses provided asset_path when present', () {
      final json = {
        'id': 1,
        'name': 'Custom Poster',
        'type': 'wall_decor',
        'slot_type': 'wall',
        'price': 100,
        'asset_path': 'assets/custom/poster.webp',
        'description': 'A cool poster',
      };

      final item = ShopItem.fromJson(json);

      expect(item.assetPath, 'assets/custom/poster.webp');
      expect(item.id, 1);
      expect(item.type, 'wall_decor');
    });

    test('falls back to room path when asset_path is missing and type is room', () {
      final json = {
        'id': 2,
        'name': 'Standard Room',
        'type': 'room',
        'slot_type': 'room',
        'price': 500,
        'description': 'A nice room',
      };

      final item = ShopItem.fromJson(json);

      expect(item.assetPath, 'assets/images/room/2.webp');
    });

    test('falls back to furniture path when asset_path is missing and type is not room', () {
      final json = {
        'id': 3,
        'name': 'Standard Desk',
        'type': 'desk',
        'slot_type': 'desk',
        'price': 200,
        'description': 'A sturdy desk',
      };

      final item = ShopItem.fromJson(json);

      expect(item.assetPath, 'assets/images/furniture/3.webp');
    });

    test('falls back to room path when asset_path is empty string and type is room', () {
      final json = {
        'id': 4,
        'name': 'Empty Path Room',
        'type': 'room',
        'slot_type': 'room',
        'price': 500,
        'asset_path': '',
        'description': 'Another nice room',
      };

      final item = ShopItem.fromJson(json);

      expect(item.assetPath, 'assets/images/room/4.webp');
    });

    test('falls back to furniture path when asset_path is empty string and type is not room', () {
      final json = {
        'id': 5,
        'name': 'Empty Path Desk',
        'type': 'desk',
        'slot_type': 'desk',
        'price': 200,
        'asset_path': '',
        'description': 'Another sturdy desk',
      };

      final item = ShopItem.fromJson(json);

      expect(item.assetPath, 'assets/images/furniture/5.webp');
    });
  });
}
