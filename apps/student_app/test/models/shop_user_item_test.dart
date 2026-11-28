import 'package:arbor_med/features/shop/models/shop_user_item.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('an explicit grid origin differs from a fixed slot at zero', () {
    final base = {
      'id': 7, 'item_id': 9, 'is_placed': true, 'name': 'Desk',
      'placed_at_slot': 'desk', 'x_pos': 0, 'y_pos': 0,
    };
    final grid = ShopUserItem.fromJson({...base, 'uses_grid': true});
    final fixed = ShopUserItem.fromJson({...base, 'uses_grid': false});
    expect(grid.usesGrid, isTrue);
    expect((grid.x, grid.y), (0, 0));
    expect(fixed.usesGrid, isFalse);
    expect(ShopUserItem.fromJson({...base, 'x_pos': 4}).usesGrid, isTrue);
  });
}
