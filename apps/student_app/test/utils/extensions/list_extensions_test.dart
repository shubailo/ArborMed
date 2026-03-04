import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/utils/extensions/list_extensions.dart';

void main() {
  group('ListSafeAccess', () {
    test('safeGet returns element for valid indices', () {
      final list = ['a', 'b', 'c'];
      expect(list.safeGet(0), 'a');
      expect(list.safeGet(1), 'b');
      expect(list.safeGet(2), 'c');
    });

    test('safeGet returns null for negative index', () {
      final list = ['a', 'b', 'c'];
      expect(list.safeGet(-1), isNull);
      expect(list.safeGet(-10), isNull);
    });

    test('safeGet returns null for index equal to length or greater', () {
      final list = ['a', 'b', 'c'];
      expect(list.safeGet(3), isNull);
      expect(list.safeGet(4), isNull);
      expect(list.safeGet(100), isNull);
    });

    test('safeGet returns null for empty list', () {
      final list = <String>[];
      expect(list.safeGet(0), isNull);
      expect(list.safeGet(1), isNull);
      expect(list.safeGet(-1), isNull);
    });

    test('safeGet works with different data types', () {
      final intList = [1, 2, 3];
      expect(intList.safeGet(1), 2);
      expect(intList.safeGet(5), isNull);

      final nullableList = [1, null, 3];
      expect(nullableList.safeGet(1), isNull);
      expect(nullableList.safeGet(0), 1);
    });
  });
}
