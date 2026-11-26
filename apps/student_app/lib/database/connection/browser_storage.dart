import 'package:drift/drift.dart';

/// Browsing and queued answers share the same lazily opened web database.
class BrowserStorageConnection extends DatabaseConnection {
  final bool Function() _isPersistent;
  BrowserStorageConnection._(super.executor, this._isPersistent);

  factory BrowserStorageConnection(
      Future<({QueryExecutor executor, bool persistent})> Function() open) {
    var persistent = false;
    return BrowserStorageConnection._(LazyDatabase(() async {
      final result = await open();
      persistent = result.persistent;
      return result.executor;
    }), () => persistent);
  }

  Future<void> requirePersistentQueue(QueryExecutorUser user) async {
    await ensureOpen(user);
    if (!_isPersistent()) {
      throw StateError(
          'Persistent browser storage is required to save an answer.');
    }
  }
}
