import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';

import 'browser_storage.dart';

QueryExecutor openConnection() => BrowserStorageConnection(() async {
      // Drift reuses the existing OPFS or IndexedDB database when available.
      final result = await WasmDatabase.open(
        databaseName: 'app_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return (
        executor: result.resolvedExecutor,
        persistent:
            result.chosenImplementation != WasmStorageImplementation.inMemory,
      );
    });
