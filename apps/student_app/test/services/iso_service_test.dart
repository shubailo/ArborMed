import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/services/iso_service.dart';

void main() {
  group('IsoService', () {
    test('gridSize is 10', () {
      expect(IsoService.gridSize, 10);
    });

    group('getDepth', () {
      test('calculates correct depth for origin', () {
        expect(IsoService.getDepth(0, 0), 0.0);
      });

      test('calculates correct depth for positive coordinates', () {
        expect(IsoService.getDepth(5, 5), 10.0);
        expect(IsoService.getDepth(2, 8), 10.0);
      });

      test('calculates correct depth for negative coordinates', () {
        expect(IsoService.getDepth(-2, 3), 1.0);
        expect(IsoService.getDepth(-5, -5), -10.0);
      });

      test('returns higher depth for items closer to the viewer', () {
        final itemBack = IsoService.getDepth(1, 1);
        final itemFront = IsoService.getDepth(5, 5);
        expect(itemFront > itemBack, isTrue);
      });
    });

    group('gridToScreen', () {
      test('calculates correct screen offsets for origin', () {
        final screen = IsoService.gridToScreen(0, 0);
        expect(screen, [0.0, 0.0]);
      });

      test('calculates correct screen offsets with default tile sizes for positive x', () {
        final screen = IsoService.gridToScreen(1, 0);
        // default tileWidth = 60.0 -> (1 - 0) * 30.0 = 30.0
        // default tileHeight = 30.0 -> (1 + 0) * 15.0 = 15.0
        expect(screen, [30.0, 15.0]);
      });

      test('calculates correct screen offsets with default tile sizes for positive y', () {
        final screen = IsoService.gridToScreen(0, 1);
        // default tileWidth = 60.0 -> (0 - 1) * 30.0 = -30.0
        // default tileHeight = 30.0 -> (0 + 1) * 15.0 = 15.0
        expect(screen, [-30.0, 15.0]);
      });

      test('calculates correct screen offsets with custom tile sizes', () {
        final screen = IsoService.gridToScreen(1, 1, tileWidth: 100.0, tileHeight: 50.0);
        // x = (1 - 1) * 50.0 = 0.0
        // y = (1 + 1) * 25.0 = 50.0
        expect(screen, [0.0, 50.0]);
      });

      test('calculates correct screen offsets for negative coordinates', () {
        final screen = IsoService.gridToScreen(-1, -1);
        // x = (-1 - -1) * 30.0 = 0.0
        // y = (-1 + -1) * 15.0 = -30.0
        expect(screen, [0.0, -30.0]);
      });
    });
  });
}
