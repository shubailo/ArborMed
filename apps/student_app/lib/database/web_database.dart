import 'package:drift/drift.dart';
// ignore: deprecated_member_use
import 'package:drift/web.dart';

LazyDatabase openConnection() {
  return LazyDatabase(() async {
    // Note: package:drift/web.dart is deprecated. 
    // Migration to package:drift/wasm.dart is recommended for next-gen web support.
    // ignore: deprecated_member_use
    return WebDatabase('arbormed_v1');
  });
}
