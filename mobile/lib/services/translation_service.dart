import 'package:flutter/foundation.dart';
import 'api_service.dart';
import '../core/api_endpoints.dart';

class TranslationService {
  final ApiService _apiService = ApiService();

  /// Translate a single text string
  Future<String?> translateText(String text, String from, String to) async {
    if (text.trim().isEmpty) return null;
    if (from == to) return text;

    try {
      final response = await _apiService.post(
        ApiEndpoints.apiTranslate,
        {
          'text': text,
          'from': from,
          'to': to,
        },
      );

      return response['translated'] as String?;
    } catch (e) {
      debugPrint('Translation failed: $e');
      return null;
    }
  }

  /// Translate an entire question with all fields
  Future<Map<String, dynamic>?> translateQuestion({
    required Map<String, dynamic> questionData,
    required String from,
    required String to,
  }) async {
    try {
      final response = await _apiService.post(
        ApiEndpoints.apiTranslateQuestion,
        {
          'questionData': questionData,
          'from': from,
          'to': to,
        },
      );

      return response['translatedQuestion'] as Map<String, dynamic>?;
    } catch (e) {
      debugPrint('Question translation failed: $e');
      return null;
    }
  }
}
