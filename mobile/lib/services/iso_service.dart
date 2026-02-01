class IsoService {
  static const int gridSize = 10;
  
  /// In Isometric projection, depth is usually calculated as x + y.
  /// Items with higher x + y are "closer" to the viewer and should be rendered last.
  static double getDepth(int x, int y) {
    return (x + y).toDouble();
  }

  /// Converts grid coordinates (x, y) to screen offsets relative to a center point.
  /// This matches a standard isometric projection where:
  /// x-axis goes down-right
  /// y-axis goes down-left
  static List<double> gridToScreen(int x, int y, {double tileWidth = 60.0, double tileHeight = 30.0}) {
    double screenX = (x - y) * (tileWidth / 2);
    double screenY = (x + y) * (tileHeight / 2);
    return [screenX, screenY];
  }
}
