import 'package:dio/dio.dart';

import 'package:flutter/foundation.dart';

class ApiClient {
  final Dio _dio;

  ApiClient({String? baseUrl})
    : _dio = Dio(
        BaseOptions(
          baseUrl:
              baseUrl ??
              (kIsWeb ? 'http://localhost:3000' : 'http://10.0.2.2:3000'),
          connectTimeout: const Duration(seconds: 10),
          receiveTimeout: const Duration(seconds: 10),
        ),
      );

  /// Set the token dynamically after login
  void setToken(String token) {
    _dio.options.headers['Authorization'] = 'Bearer $token';
  }

  Future<String> login() async {
    final response = await _dio.post('/auth/login');
    final String token = response.data['token'];
    setToken(token);
    return response.data['user']['id'];
  }

  Future<Map<String, dynamic>> fetchNextQuestion(
    String userId, {
    String? courseId,
  }) async {
    final Map<String, dynamic> query = {};
    if (courseId != null) {
      query['courseId'] = courseId;
    }

    final response = await _dio.get('/study/next', queryParameters: query);
    return response.data as Map<String, dynamic>;
  }

  Future<int> submitAnswer(
    String questionId,
    int quality, {
    String? courseId,
  }) async {
    final data = {'questionId': questionId, 'quality': quality};
    if (courseId != null) {
      data['courseId'] = courseId;
    }

    final response = await _dio.post('/study/answer', data: data);
    return response.data['rewardBalance'] as int? ?? 0;
  }

  Future<int> getRewardBalance(String userId) async {
    final response = await _dio.get('/rewards/balance/$userId');
    return response.data['balance'] as int? ?? 0;
  }

  Future<List<Map<String, dynamic>>> getShopItems() async {
    final response = await _dio.get('/rewards/shop');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> getUserInventory() async {
    final response = await _dio.get('/rewards/inventory');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> purchaseItem(String shopItemId) async {
    final response = await _dio.post('/rewards/purchase', data: {
      'shopItemId': shopItemId,
    });
    return response.data as Map<String, dynamic>;
  }

  // M4: Room Customization
  Future<List<Map<String, dynamic>>> getRoomState() async {
    final response = await _dio.get('/room');
    return (response.data as List).cast<Map<String, dynamic>>();
  }

  Future<Map<String, dynamic>> placeRoomItem(
    String slotKey,
    String shopItemId,
  ) async {
    final response = await _dio.post('/room/place', data: {
      'slotKey': slotKey,
      'shopItemId': shopItemId,
    });
    return response.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> clearRoomSlot(String slotKey) async {
    final response = await _dio.post('/room/clear', data: {'slotKey': slotKey});
    return response.data as Map<String, dynamic>;
  }

  // M7: Student Progress
  Future<Map<String, dynamic>> getUserCourseProgress(String userId, String courseId) async {
    final response = await _dio.get('/progress/user/$userId/course/$courseId');
    return response.data as Map<String, dynamic>;
  }
}
