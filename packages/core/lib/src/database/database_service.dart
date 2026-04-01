import 'package:flutter/foundation.dart';
import 'database.dart';

class DatabaseService {
  late AppDatabase _db;
  AppDatabase get db => _db;

  Future<void> init() async {
    _db = AppDatabase();
    debugPrint("✅ Drift Database Initialized");
  }

  Future<void> clearAll() async {
    await _db.clearUserData();
  }
}
