import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../database/database.dart';
import 'api_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final AppDatabase _db = AppDatabase();
  final ApiService _apiService = ApiService();
  
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  bool _isSyncing = false;

  void init() {
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint("🌐 Internet restored! Triggering sync...");
        processQueue();
      }
    });
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  Future<void> processQueue() async {
    if (_isSyncing) return;
    _isSyncing = true;

    try {
      final actions = await (_db.select(_db.syncActions)..orderBy([(t) => OrderingTerm(expression: t.createdAt)])).get();

      if (actions.isEmpty) {
        _isSyncing = false;
        return;
      }

      debugPrint("📦 Processing ${actions.length} sync actions...");

      for (var action in actions) {
        bool success = await _performAction(action);
        if (success) {
          await (_db.delete(_db.syncActions)..where((t) => t.id.equals(action.id))).go();
        } else {
          // Increment retry or handle failure
          if (action.retryCount >= 5) {
            await (_db.delete(_db.syncActions)..where((t) => t.id.equals(action.id))).go();
          } else {
            await (_db.update(_db.syncActions)..where((t) => t.id.equals(action.id))).write(
              SyncActionsCompanion(retryCount: Value(action.retryCount + 1)),
            );
          }
          break; // Stop processing for now if a middle one fails
        }
      }
    } catch (e) {
      debugPrint("❌ Sync process error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// Downloads all base questions for a topic (Batch Sync)
  Future<void> syncQuestions(String topicSlug) async {
    try {
      final List<dynamic> data = await _apiService.get('/quiz/all-questions?topic=$topicSlug');
      
      await _db.batch((batch) {
        for (var q in data) {
          batch.insert(
            _db.questions,
            QuestionsCompanion.insert(
              serverId: Value(q['id'] is String ? int.parse(q['id']) : q['id']),
              topicId: Value(q['topic_id'] is String ? int.parse(q['topic_id']) : q['topic_id']),
              questionText: Value(q['text']),
              type: Value(q['type']),
              options: Value(jsonEncode(q['options'])),
              correctAnswer: Value(q['correct_answer']),
              explanation: Value(q['explanation']),
              bloomLevel: Value(q['bloom_level']),
              difficulty: Value(q['difficulty']),
              active: Value(q['active'] ?? true),
              lastFetched: Value(DateTime.now()),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      debugPrint("✅ Synced ${data.length} questions for $topicSlug");
    } catch (e) {
      debugPrint("❌ Question sync failed: $e");
    }
  }

  /// Downloads all items for the shop
  Future<void> syncItems() async {
    try {
      final List<dynamic> data = await _apiService.get('/shop/items');
      
      await _db.batch((batch) {
        for (var i in data) {
          batch.insert(
            _db.items,
            ItemsCompanion.insert(
              serverId: Value(i['id']),
              name: Value(i['name']),
              type: Value(i['type']),
              slotType: Value(i['slot_type']),
              price: Value(i['price']),
              assetPath: Value(i['asset_path']),
              description: Value(i['description']),
              theme: Value(i['theme']),
              isPremium: Value(i['is_premium'] ?? false),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      });
      debugPrint("✅ Synced ${data.length} items to local shop");
    } catch (e) {
      debugPrint("❌ Item sync failed: $e");
    }
  }

  Future<bool> _performAction(SyncAction action) async {
    final payload = jsonDecode(action.payload ?? '{}');
    try {
      switch (action.actionType) {
        case 'BUY':
          await _apiService.post('/shop/buy', payload);
          return true;
        case 'EQUIP':
          await _apiService.post('/shop/equip', payload);
          return true;
        case 'UNEQUIP':
          await _apiService.post('/shop/unequip', payload);
          return true;
        case 'QUIZ_RESULT':
          await _apiService.post('/quiz/answer', {
            'topicSlug': payload['topicSlug'],
            'questionId': payload['questionId'],
            'userAnswer': payload['isCorrect'] ? 'correct' : 'incorrect',
            'responseTimeMs': payload['responseTimeMs'],
          });
          return true;
        default:
          return true; // Ignore unknown
      }
    } catch (e) {
      debugPrint("❌ Sync action ${action.actionType} failed: $e");
      return false;
    }
  }
}
