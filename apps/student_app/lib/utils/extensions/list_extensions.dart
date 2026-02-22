extension ListSafeAccess<T> on List<T> {
  /// Safely gets an element at [index].
  /// Returns null if [index] is out of bounds.
  T? safeGet(int index) {
    if (index < 0 || index >= length) return null;
    return this[index];
  }
}
