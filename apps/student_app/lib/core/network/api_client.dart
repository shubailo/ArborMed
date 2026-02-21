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

  Future<void> submitAnswer(
    String questionId,
    int quality, {
    String? courseId,
  }) async {
    final data = {'questionId': questionId, 'quality': quality};
    if (courseId != null) {
      data['courseId'] = courseId;
    }

    await _dio.post('/study/answer', data: data);
  }
}
