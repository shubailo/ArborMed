import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class TranslationService {
  final String baseUrl;
  
  TranslationService({required this.baseUrl});
  
  /// Translate a single text string
  Future<String?> translateText(String text, String from, String to) async {
    if (text.trim().isEmpty) return null;
    if (from == to) return text;
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/translate'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'text': text,
          'from': from,
          'to': to,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translated'] as String?;
      } else {
        debugPrint('Translation API error: ${response.statusCode}');
        return null;
      }
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
      final response = await http.post(
        Uri.parse('$baseUrl/api/translate/question'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'questionData': questionData,
          'from': from,
          'to': to,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['translatedQuestion'] as Map<String, dynamic>?;
      } else {
        debugPrint('Question translation API error: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Question translation failed: $e');
      return null;
    }
  }
}
