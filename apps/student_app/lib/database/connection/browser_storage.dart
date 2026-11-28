import 'package:drift/drift.dart';

enum BrowserStorageSafety { transient, singleTab, sharedPersistent }

class SubmissionStorageUnavailable extends StateError {
  SubmissionStorageUnavailable()
      : super('Persistent browser storage with multi-tab protection is required to save an answer.');
}

/// Browsing and queued answers share the same lazily opened web database.
class BrowserStorageConnection extends DatabaseConnection {
  final BrowserStorageSafety Function() _storageSafety;
  BrowserStorageConnection._(super.executor, this._storageSafety);

  factory BrowserStorageConnection(
      Future<({QueryExecutor executor, BrowserStorageSafety safety})> Function() open) {
    var safety = BrowserStorageSafety.transient;
    return BrowserStorageConnection._(LazyDatabase(() async {
      final result = await open();
      safety = result.safety;
      return result.executor;
    }), () => safety);
  }

  Future<void> requirePersistentQueue(QueryExecutorUser user) async {
    await ensureOpen(user);
    if (_storageSafety() != BrowserStorageSafety.sharedPersistent) {
      throw SubmissionStorageUnavailable();
    }
  }
}
