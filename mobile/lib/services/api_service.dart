import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'dart:io';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  // Use localhost for Web/iOS, 10.0.2.2 for Android Emulator
  static String get baseUrl {
    // Return production URL directly for the APK release
    // if (kReleaseMode) {
    //   return 'https://med-buddy-lrri.onrender.com';
    // }
    // Android Emulator 10.0.2.2 points to host localhost
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; // Emulator Loopback
      // return 'http://10.65.175.74:3000'; // Physical Device LAN IP
    }
    return 'http://localhost:3000'; // Fallback for iOS/Physical
  } 
  
  String? _token;
  String? get token => _token;

  void setToken(String token) {
    _token = token;
  }

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
      body: jsonEncode(data),
    );

    return _handleResponse(response);
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );

    return _handleResponse(response);
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }
}
