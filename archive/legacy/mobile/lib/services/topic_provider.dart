import 'package:flutter/foundation.dart';
import 'auth_provider.dart';
import '../core/api_endpoints.dart';

/// Manages topic CRUD operations: fetch, create, update, delete topics.
class TopicProvider with ChangeNotifier {
  final AuthProvider authProvider;

  TopicProvider(this.authProvider);

  // --- State ---
  List<Map<String, dynamic>> _topics = [];
  List<Map<String, dynamic>> get topics => _topics;

  Future<void> fetchTopics() async {
    try {
      final data = await authProvider.apiService.get(ApiEndpoints.quizTopics);
      if (data is List) {
        _topics = data.cast<Map<String, dynamic>>();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error fetching topics: $e');
    }
  }

  Future<bool> createTopic(String nameEn, String nameHu, int? parentId) async {
    try {
      await authProvider.apiService.post(ApiEndpoints.quizAdminTopics, {
        'name_en': nameEn,
        'name_hu': nameHu,
        'parent_id': parentId,
      });
      await fetchTopics();
      return true;
    } catch (e) {
      debugPrint('Error creating topic: $e');
      return false;
    }
  }

  Future<String?> deleteTopic(int topicId, {bool force = false}) async {
    try {
      await authProvider.apiService
          .delete('${ApiEndpoints.quizAdminTopics}/$topicId${force ? '?force=true' : ''}');
      await fetchTopics();
      return null;
    } catch (e) {
      debugPrint('Error deleting topic: $e');
      return e.toString().contains('API Error')
          ? e.toString().split('API Error: ')[1]
          : 'Network error';
    }
  }

  Future<String?> updateTopic(int id, String nameEn, String nameHu) async {
    try {
      await authProvider.apiService.put('${ApiEndpoints.quizAdminTopics}/$id', {
        'name_en': nameEn,
        'name_hu': nameHu,
      });

      // Optimistic update
      final index = _topics.indexWhere((t) => t['id'] == id);
      if (index != -1) {
        _topics[index]['name_en'] = nameEn;
        _topics[index]['name_hu'] = nameHu;
        notifyListeners();
      }

      fetchTopics(); // Background refresh
      return null;
    } catch (e) {
      debugPrint('Error updating topic: $e');
      return e.toString().contains('API Error')
          ? e.toString().split('API Error: ')[1]
          : 'Network error';
    }
  }

  void resetState() {
    _topics = [];
    notifyListeners();
  }
}
