import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  // Use localhost for Web/iOS, 10.0.2.2 for Android Emulator
  static String get baseUrl {
    // 🌍 PRODUCTION (Release Mode / APK)
    if (kReleaseMode) {
      return 'https://med-buddy-lrri.onrender.com';
    }

    // 🏠 LOCAL DEBUG (Emulator / Web Debug)
    if (!kIsWeb && Platform.isAndroid) {
      return 'http://10.0.2.2:3000'; 
    }
    return 'http://localhost:3000';
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

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http.put(
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

  Future<dynamic> delete(String endpoint) async {
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: {
        'Content-Type': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
      },
    );

    return _handleResponse(response);
  }

  Future<String?> uploadImage(XFile file) async {
    try {
      var request = http.MultipartRequest('POST', Uri.parse('$baseUrl/api/upload'));
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';

      // Determine Mime Type
      final ext = file.name.split('.').last.toLowerCase();
      MediaType? mediaType;
      if (ext == 'png') {
        mediaType = MediaType('image', 'png');
      } else if (ext == 'jpg' || ext == 'jpeg') {
        mediaType = MediaType('image', 'jpeg');
      } else if (ext == 'webp') {
        mediaType = MediaType('image', 'webp');
      }
      
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        request.files.add(http.MultipartFile.fromBytes(
          'image', 
          bytes,
          filename: file.name,
          contentType: mediaType,
        ));
      } else {
        request.files.add(await http.MultipartFile.fromPath(
          'image', 
          file.path,
          contentType: mediaType,
        ));
      }
      
      var response = await request.send();
      var respStr = await response.stream.bytesToString();
      
      if (response.statusCode == 200) {
        var jsonRef = jsonDecode(respStr);
        return jsonRef['imageUrl'];
      }
      debugPrint("Upload failed: ${response.statusCode} $respStr");
      return null;
    } catch (e) {
      debugPrint("Upload exception: $e");
      return null;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return jsonDecode(response.body);
    } else {
      throw Exception('API Error: ${response.statusCode} ${response.body}');
    }
  }
}
