import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType
import '../core/api_endpoints.dart';
import '../core/api_exceptions.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();
  // Use localhost for Web/iOS, 10.0.2.2 for Android Emulator
  // 🔧 CONFIG: Set this to true to use the Production Backend on Mobile Debug
  // Useful for physical devices where 10.0.2.2 doesn't work.
  static const bool useProdInDebug = true;

  static String get baseUrl {
    // 🌐 DYNAMIC OVERRIDE (Via --dart-define=API_URL=...)
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // 🌍 PRODUCTION (Release Mode / APK / Forced)
    if (kReleaseMode || (useProdInDebug && !kIsWeb)) {
      return 'https://med-buddy-lrri.onrender.com';
    }

    // 🏠 LOCAL DEBUG (Emulator / Web Debug)
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // ⏱️ TIMEOUT CONFIG
  static const Duration _timeout = Duration(seconds: 30);

  String? _token;
  String? _refreshToken;
  int? _userId;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  int? get userId => _userId;
  bool _isRefreshing = false;
  String? _languageCode;

  void setLanguage(String lang) {
    _languageCode = lang;
  }

  void setToken(String token, {String? refreshToken, int? userId}) {
    _token = token;
    if (refreshToken != null) _refreshToken = refreshToken;
    if (userId != null) _userId = userId;
  }

  Future<int?> getCurrentUserId() async {
    return _userId;
  }

  // Callback to notify AuthProvider when a new access token is received
  Function(String token)? onTokenRefreshed;

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) async {
    final response = await http
        .post(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    return _wrappedHandleResponse(response, () => post(endpoint, data));
  }

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) async {
    final response = await http
        .put(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
          body: jsonEncode(data),
        )
        .timeout(_timeout);

    return _wrappedHandleResponse(response, () => put(endpoint, data));
  }

  Future<dynamic> get(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    return _wrappedHandleResponse(response, () => get(endpoint));
  }

  Future<dynamic> getBytes(String endpoint) async {
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: _getHeaders(),
    );

    if (response.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
      final success = await _tryRefreshToken();
      if (success) return getBytes(endpoint);
    }

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    } else {
      throw ApiException(statusCode: response.statusCode, message: 'API Error', body: response.body);
    }
  }

  Future<void> submitReport(int questionId, String reason, String description) async {
    await post('/reports', {
      'questionId': questionId,
      'reasonCategory': reason,
      'description': description,
    });
  }

  Future<dynamic> delete(String endpoint) async {
    final response = await http
        .delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(),
        )
        .timeout(_timeout);

    return _wrappedHandleResponse(response, () => delete(endpoint));
  }

  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      if (_token != null && _token!.isNotEmpty)
        'Authorization': 'Bearer $_token',
      'Accept-Language': _languageCode ?? 'en',
    };
  }

  Future<dynamic> _wrappedHandleResponse(
      http.Response response, Future<dynamic> Function() retry) async {
    if (response.statusCode == 401 && _refreshToken != null && !_isRefreshing) {
      final success = await _tryRefreshToken();
      if (success) {
        return retry();
      }
    }
    return _handleResponse(response);
  }

  Future<bool> _tryRefreshToken() async {
    if (_isRefreshing) return false;
    _isRefreshing = true;

    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl${ApiEndpoints.authRefresh}'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'refreshToken': _refreshToken,
              'userId': _userId,
            }),
          )
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        _token = data['token'];
        if (onTokenRefreshed != null) {
          onTokenRefreshed!(_token!);
        }
        return true;
      } else {
        debugPrint("Refresh token failed: ${response.statusCode}");
        return false;
      }
    } catch (e) {
      debugPrint("Refresh token error: $e");
      return false;
    } finally {
      _isRefreshing = false;
    }
  }

  Future<dynamic> postMultipart(String endpoint,
      {required List<int> bytes,
      required String filename,
      String fieldName = 'file'}) async {
    try {
      var request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      if (_token != null) request.headers['Authorization'] = 'Bearer $_token';

      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType:
            filename.endsWith('.csv') ? MediaType('text', 'csv') : null,
      ));

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 401 &&
          _refreshToken != null &&
          !_isRefreshing) {
        final success = await _tryRefreshToken();
        if (success) {
          return postMultipart(endpoint,
              bytes: bytes, filename: filename, fieldName: fieldName);
        }
      }

      return _handleResponse(response);
    } catch (e) {
      debugPrint("Multipart post error: $e");
      rethrow;
    }
  }

  Future<String?> uploadImage(XFile file, {String? folder}) async {
    try {
      String url = '$baseUrl${ApiEndpoints.apiUpload}';
      if (folder != null) url += '?folder=$folder';

      var request = http.MultipartRequest('POST', Uri.parse(url));
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

      // Handle 401 for upload too
      if (response.statusCode == 401 &&
          _refreshToken != null &&
          !_isRefreshing) {
        final success = await _tryRefreshToken();
        if (success) {
          return uploadImage(file, folder: folder);
        }
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
    }
    switch (response.statusCode) {
      case 401:
        throw AuthException(body: response.body);
      case 403:
        throw ForbiddenException(body: response.body);
      case 404:
        throw NotFoundException(body: response.body);
      case 409:
        throw ConflictException(body: response.body);
      default:
        if (response.statusCode >= 500) {
          throw ServerException(statusCode: response.statusCode, body: response.body);
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: 'API Error',
          body: response.body,
        );
    }
  }
}
