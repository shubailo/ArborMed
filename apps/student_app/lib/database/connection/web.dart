import 'package:drift/drift.dart';
import 'package:drift/wasm.dart';
import 'package:drift/web.dart';

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
      print('[DB] WASM init failed ($e), using WebDatabase fallback.');
      return WebDatabase('app_db');
    }
  });
}

