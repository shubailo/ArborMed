import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'browser_storage.dart';

QueryExecutor openConnection() => BrowserStorageConnection(() async {
      const name = 'app_db';
      final probe = await WasmDatabase.probe(
        databaseName: name,
        sqlite3Uri: Uri.base.resolve('sqlite3.wasm'),
        driftWorkerUri: Uri.base.resolve('drift_worker.js'),
      );
      final existing = probe.existingDatabases
          .where((entry) => entry.$2 == name)
          .map((entry) => entry.$1)
          .toSet();
      final implementation = const [
        WasmStorageImplementation.opfsShared,
        WasmStorageImplementation.opfsLocks,
        WasmStorageImplementation.sharedIndexedDb,
      ].firstWhere(
        (candidate) => probe.availableStorages.contains(candidate) &&
            (existing.isEmpty || existing.contains(candidate.storageApi)),
        orElse: () => WasmStorageImplementation.inMemory,
      );
      // Keep an existing database intact when its storage cannot be shared safely.
      final executor = await probe.open(implementation, name);
      return (
        executor: executor,
        safety: implementation == WasmStorageImplementation.inMemory
            ? BrowserStorageSafety.transient
            : BrowserStorageSafety.sharedPersistent,
      );
    });
