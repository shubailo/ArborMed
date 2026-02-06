import 'dart:async';
import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
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
    // 1. Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) {
      if (results.any((r) => r != ConnectivityResult.none)) {
        debugPrint("🌐 Internet restored! Triggering sync...");
        processQueue();
        syncSmartContent();
      }
    });

    // 2. Initial check on startup
    _checkInitialConnectivity();
  }

  Future<void> _checkInitialConnectivity() async {
    final results = await Connectivity().checkConnectivity();
    if (results.any((r) => r != ConnectivityResult.none)) {
      debugPrint("🚀 App Start: Online. Triggering sync...");
      processQueue();
      syncSmartContent();
    }
  }

  void dispose() {
    _connectivitySubscription?.cancel();
  }

  /// 🧠 Hybrid Sync: Queue Processing
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
          // Retry Logic
          if (action.retryCount >= 5) {
            debugPrint("❌ Action ${action.id} failed 5 times. Deleting.");
            await (_db.delete(_db.syncActions)..where((t) => t.id.equals(action.id))).go();
          } else {
            await (_db.update(_db.syncActions)..where((t) => t.id.equals(action.id))).write(
              SyncActionsCompanion(retryCount: Value(action.retryCount + 1)),
            );
          }
          // Stop processing if connection failed? 
          // For now, break to avoid hammering 
          break; 
        }
      }
    } catch (e) {
      debugPrint("❌ Sync process error: $e");
    } finally {
      _isSyncing = false;
    }
  }

  /// 📦 State Sync: Trigger Room Sync (Fetch state at sync time)
  Future<void> syncRoomState(int roomId) async {
    // 1. Remove ANY pending room state actions for this room
    await (_db.delete(_db.syncActions)..where((t) => t.actionType.equals('EQUIP_STATE'))).go();

    // 2. Create NEW trigger
    await _db.into(_db.syncActions).insert(
      SyncActionsCompanion.insert(
        actionType: const Value('EQUIP_STATE'),
        payload: Value(jsonEncode({'roomId': roomId})),
        createdAt: Value(DateTime.now()),
      ),
    );

    // 3. Trigger immediate sync attempt
    processQueue();
  }

  /// 📚 Quiz: Download Topic for Offline
  /// 🔄 Smart Sync: Prioritize Active Topics
  Future<void> syncSmartContent() async {
    // 1. Fetch priority list (e.g. recently accessed topics)
    // For now, we'll just prioritize known slugs if we had them. 
    // Since we don't have a reliable 'Recent Topics' provider here without circular deps,
    // we will rely on `syncAllContent` but prioritize lightweight metadata first?
    // Actually, let's just trigger `syncAllContent` which iterates all topics.
    await syncAllContent();
  }

  /// 🔄 Seamless Background Sync
  Future<void> syncAllContent() async {
    if (_isSyncing) return;
    _isSyncing = true;
    
    try {
      debugPrint("🔄 Starting Seamless Background Sync...");
      
      // 1. Fetch All Topics available
      final List<dynamic> topics = await _apiService.get('/quiz/topics');
      
      // 2. Iterate and Sync Questions
      // We do this serially to avoid flooding the network
      for (var topic in topics) {
        await _syncQuestionsForTopic(topic['slug']);
      }
      
      debugPrint("✅ Background Sync Complete");
    } catch (e) {
      debugPrint("⚠️ Background Sync Interrupted: $e");
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncQuestionsForTopic(String slug) async {
      try {
        final List<dynamic> questions = await _apiService.get('/quiz/all-questions?topic=$slug');
        if (questions.isEmpty) return;

        await _db.batch((batch) {
          for (var q in questions) {
            batch.insert(
              _db.questions,
              QuestionsCompanion.insert(
                serverId: Value(q['id'] is String ? int.parse(q['id']) : q['id']),
                topicId: Value(q['topic_id'] is String ? int.parse(q['topic_id']) : q['topic_id']),
                questionText: Value(q['text'] ?? q['question_text_en']),
                type: Value(q['type'] ?? 'single_choice'),
                options: Value(jsonEncode(q['options'])),
                correctAnswer: Value(q['correct_answer']),
                explanation: Value(q['explanation'] ?? ''),
                bloomLevel: Value(q['bloom_level'] ?? 1),
                difficulty: Value(q['difficulty'] ?? 1),
                active: Value(true),
                lastFetched: Value(DateTime.now()),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
        
        await _markTopicAsOfflineReady(slug);
      } catch (e) {
        debugPrint("   -> Failed to sync topic $slug: $e");
      }
  }

  /// 🔍 Check if topic is offline ready (Sync Status for UI)
  Future<bool> isTopicOfflineReady(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList('offline_topics') ?? [];
    return downloaded.contains(slug);
  }

  Future<void> _markTopicAsOfflineReady(String slug) async {
    final prefs = await SharedPreferences.getInstance();
    final downloaded = prefs.getStringList('offline_topics') ?? [];
    if (!downloaded.contains(slug)) {
      downloaded.add(slug);
      await prefs.setStringList('offline_topics', downloaded);
    }
  }

  Future<bool> _performAction(SyncAction action) async {
    final payload = jsonDecode(action.payload ?? '{}');
    try {
      switch (action.actionType) {
        case 'BUY':
          await _apiService.post('/shop/buy', payload);
          // Sync inventory to capture new serverId
          final invData = await _apiService.get('/shop/inventory?userId=${payload['userId'] ?? ''}'); 
          await _syncInventoryToLocal(invData);
          return true;
        
        case 'EQUIP_STATE':
          final roomId = payload['roomId'];
          final placedItems = await (_db.select(_db.userItems)
            ..where((t) => t.roomId.equals(roomId) & t.isPlaced.equals(true)))
            .get();

          final itemsPayload = placedItems.map((i) => {
            'userItemId': i.serverId, 
            'itemId': i.itemId, 
            'x': i.xPos,
            'y': i.yPos,
            'slot': i.slot,
          }).where((data) => data['userItemId'] != null).toList();

          await _apiService.post('/shop/sync-room', {'roomId': roomId, 'items': itemsPayload});
          return true;

        case 'QUIZ_RESULT':
          await _apiService.post('/quiz/answer', {
            'topicSlug': payload['topicSlug'],
            'questionId': payload['questionId'],
            'userAnswer': payload['isCorrect'] ? 'correct' : 'incorrect',
            'responseTimeMs': payload['responseTimeMs'],
          });
          return true;
          
        case 'EQUIP': // Legacy support (drain queue)
        case 'UNEQUIP':
           // We might want to ignore these if we are moving to state sync, 
           // BUT if user has old actions, we should try to clear them.
           // Or just return true to skip them since STATE_LATEST will overwrite.
           return true; 

        default:
          return true; // Ignore unknown
      }
    } catch (e) {
      debugPrint("❌ Sync action ${action.actionType} failed: $e");
      return false;
    }
  }

  // Helper to sync inventory results back to DB (invoked after BUY)
  Future<void> _syncInventoryToLocal(List<dynamic> remoteData) async {
    final existingLocals = await _db.select(_db.userItems).get();
    final List<UserItem> locallyTracked = List.from(existingLocals);
    final Set<int> processedServerIds = {};

    await _db.batch((batch) {
      for (var json in remoteData) {
        final serverId = json['id'];
        final itemId = json['item_id'];
        
        if (processedServerIds.contains(serverId)) continue;
        processedServerIds.add(serverId);

        // Match local item by serverId OR by itemId (if dirty/local-only)
        final match = locallyTracked.where((l) => l.serverId == serverId).firstOrNull ??
                      locallyTracked.where((l) => l.itemId == itemId && l.serverId == null).firstOrNull;

        if (match != null) {
          batch.update(
            _db.userItems,
            UserItemsCompanion(
              serverId: Value(serverId),
              isPlaced: Value(json['is_placed'] ?? false),
              slot: Value(json['placed_at_slot']),
              xPos: Value(json['x']),
              yPos: Value(json['y']),
              roomId: Value(json['placed_at_room_id']),
              isDirty: const Value(false),
            ),
            where: (t) => t.id.equals(match.id),
          );
          locallyTracked.remove(match);
        } else {
          batch.insert(
            _db.userItems, 
            UserItemsCompanion.insert(
              serverId: Value(serverId),
              itemId: Value(itemId),
              isPlaced: Value(json['is_placed'] ?? false),
              slot: Value(json['placed_at_slot']),
              xPos: Value(json['x']),
              yPos: Value(json['y']),
              roomId: Value(json['placed_at_room_id']),
              isDirty: const Value(false),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }
    });
  }
}
