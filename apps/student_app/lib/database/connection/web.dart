import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web.dart';
import 'package:flutter/foundation.dart';

QueryExecutor openConnection() {
  return LazyDatabase(() async {
    try {
      final result = await WasmDatabase.open(
        databaseName: 'app_db',
        sqlite3Uri: Uri.parse('sqlite3.wasm'),
        driftWorkerUri: Uri.parse('drift_worker.js'),
      );
      return result.resolvedExecutor;
    } catch (e) {
      // Fallback: WASM failed (LinkError, MIME type, etc.)
      // Use WebDatabase (localStorage-based) so the app still works.
      debugPrint('[DB] WASM init failed ($e), using WebDatabase fallback.');
      // ignore: deprecated_member_use
      return WebDatabase('app_db');
    }
  });
}

