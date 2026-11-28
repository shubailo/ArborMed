import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http_parser/http_parser.dart'; // For MediaType
import 'package:arbor_med/core/api_endpoints.dart';
import '../core/api_exceptions.dart';

/// A singleton service that handles all HTTP communications with the ArborMed backend.
/// It automatically manages authentication headers, token refreshing logic, environment-based base URLs,
/// and maps server responses to strongly-typed exceptions ([AuthException], [ServerException], etc.).
class ApiService {
  static final ApiService _instance = ApiService._internal();

  factory ApiService() => _instance;
  ApiService._internal();

  http.Client _client = http.Client();

  @visibleForTesting
  void setHttpClient(http.Client client) {
    _client = client;
  }

  // Use localhost for Web/iOS, 10.0.2.2 for Android Emulator
  // 🔧 CONFIG: Set this to true to use the Production Backend on Mobile Debug
  // Useful for physical devices where 10.0.2.2 doesn't work.
  static const bool useProdInDebug = false;

  static String get baseUrl {
    // 🌐 DYNAMIC OVERRIDE (Via --dart-define=API_URL=...)
    const envUrl = String.fromEnvironment('API_URL');
    if (envUrl.isNotEmpty) return envUrl;

    // 🏠 LOCAL WEB (When browsing from localhost or 127.0.0.1)
    if (kIsWeb) {
      final host = Uri.base.host;
      if (host == 'localhost' || host == '127.0.0.1' || host.isEmpty) {
        return 'http://localhost:3000';
      }
      return 'https://med-buddy-lrri.onrender.com';
    }

    // 🌍 PRODUCTION (Release Mode / APK / Forced)
    if (kReleaseMode || useProdInDebug) {
      return 'https://med-buddy-lrri.onrender.com';
    }

    // 🏠 LOCAL DEBUG (Emulator / Desktop)
    if (defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:3000';
    }
    return 'http://localhost:3000';
  }

  // ⏱️ TIMEOUT CONFIG
  // NOTE: Render free tier cold starts can take ~45s. Use 90s to handle this.
  static const Duration _timeout = Duration(seconds: 90);

  String? _token;
  String? _refreshToken;
  int? _userId;
  String? get token => _token;
  String? get refreshToken => _refreshToken;
  int? get userId => _userId;
  Future<bool>? _refreshInFlight;
  int _session = 0;
  String? _languageCode;

  void setLanguage(String lang) {
    _languageCode = lang;
  }

  void setToken(String token, {String? refreshToken, int? userId}) {
    _token = token;
    _refreshToken = refreshToken;
    _userId = userId;
    _refreshInFlight = null;
    _session++;
  }

  Future<int?> getCurrentUserId() async {
    return _userId;
  }

  // Callback to notify AuthProvider when a new access token is received
  Function(String token)? onTokenRefreshed;

  Future<dynamic> post(String endpoint, Map<String, dynamic> data) =>
      _request('POST', endpoint, body: data);

  Future<dynamic> postPublic(String endpoint, Map<String, dynamic> data) =>
      _request('POST', endpoint, body: data, useSessionToken: false);

  Future<dynamic> put(String endpoint, Map<String, dynamic> data) =>
      _request('PUT', endpoint, body: data);

  Future<dynamic> patch(String endpoint, Map<String, dynamic> data) =>
      _request('PATCH', endpoint, body: data);

  Future<dynamic> get(String endpoint) => _request('GET', endpoint);

  Future<dynamic> getBytes(String endpoint) async {
    final response = await _withSession((token) => _client.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: _getHeaders(token),
        ));

    if (response.statusCode >= 200 && response.statusCode < 300) {
      return response.bodyBytes;
    }
    _throwResponseError(response);
  }

  Future<void> submitReport(
      int questionId, String reason, String description) async {
    await post('/reports', {
      'questionId': questionId,
      'reasonCategory': reason,
      'description': description,
    });
  }

  Future<dynamic> delete(String endpoint) => _request('DELETE', endpoint);

  Future<dynamic> _request(String method, String endpoint,
      {Map<String, dynamic>? body, bool useSessionToken = true}) async {
    final uri = Uri.parse('$baseUrl$endpoint');
    final payload = body == null ? null : jsonEncode(body);
    final headers = _getHeaders(null);
    final response = await _withSession((token) async {
      final request = http.Request(method, uri)
        ..headers.addAll(headers);
      if ((token ?? '').isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      if (payload != null) request.body = payload;
      return http.Response.fromStream(await _client.send(request));
    }, useSessionToken: useSessionToken);
    return _handleResponse(response);
  }

  Map<String, String> _getHeaders(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      'Accept-Language': _languageCode ?? 'en',
    };
  }

  Future<http.Response> _withSession(
      Future<http.Response> Function(String? token) send,
      {bool useSessionToken = true}) async {
    final session = _session;
    final token = useSessionToken ? _token : null;
    void checkSession() {
      if (session != _session) {
        throw const ApiException(
            statusCode: 0, message: 'The active session changed.');
      }
    }

    try {
      final response = await send(token).timeout(_timeout);
      checkSession();
      if (response.statusCode != 401 ||
          token == null ||
          token.isEmpty ||
          (_refreshToken ?? '').isEmpty) {
        return response;
      }
      if (token == _token) {
        final refresh = _refreshInFlight ??= _refresh(session);
        try {
          if (!await refresh) {
            checkSession();
            return response;
          }
        } finally {
          if (identical(_refreshInFlight, refresh)) _refreshInFlight = null;
        }
      }
      checkSession();
      final retried = await send(_token).timeout(_timeout);
      checkSession();
      return retried;
    } catch (_) {
      checkSession();
      rethrow;
    }
  }

  Future<http.Response> _requestRefresh(String refreshToken, int userId) =>
      _client
          .post(
            Uri.parse(baseUrl + ApiEndpoints.authRefresh),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'refreshToken': refreshToken, 'userId': userId}),
          )
          .timeout(_timeout);

  String _readRefreshedToken(http.Response response) {
    final data = _handleResponse(response);
    if (data is! Map ||
        data['token'] is! String ||
        (data['token'] as String).isEmpty) {
      throw const FormatException('Invalid refresh response');
    }
    return data['token'] as String;
  }

  Future<bool> _refresh(int session) async {
    final id = _userId;
    if (id == null) return false;
    final response = await _requestRefresh(_refreshToken!, id);
    if (session != _session || response.statusCode == 401) return false;
    _token = _readRefreshedToken(response);
    onTokenRefreshed?.call(_token!);
    return true;
  }

  /// Revokes only the captured session. Account changes do not affect these headers.
  Future<void> revokeSession(
      String token, String refreshToken, int userId) async {
    Future<http.Response> revoke(String accessToken) => _client
        .post(
          Uri.parse(baseUrl + ApiEndpoints.authLogout),
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $accessToken'
          },
          body: jsonEncode({'refreshToken': refreshToken}),
        )
        .timeout(_timeout);
    var response = await revoke(token);
    if (response.statusCode == 401) {
      final renewal = await _requestRefresh(refreshToken, userId);
      if (renewal.statusCode == 401) return;
      response = await revoke(_readRefreshedToken(renewal));
    }
    _handleResponse(response);
  }

  Future<dynamic> postMultipart(String endpoint,
      {required List<int> bytes,
      required String filename,
      String fieldName = 'file'}) async {
    final response = await _withSession((token) async {
      final request =
          http.MultipartRequest('POST', Uri.parse('$baseUrl$endpoint'));
      if ((token ?? '').isNotEmpty) {
        request.headers['Authorization'] = 'Bearer $token';
      }
      request.files.add(http.MultipartFile.fromBytes(
        fieldName,
        bytes,
        filename: filename,
        contentType:
            filename.endsWith('.csv') ? MediaType('text', 'csv') : null,
      ));
      return http.Response.fromStream(await _client.send(request));
    });
    return _handleResponse(response);
  }

  static const maxImageBytes = 20 * 1024 * 1024;

  /// Uploads an image file to the backend via a multipart request.
  /// Automatically determines the MIME type and handles retry logic for token expiration.
  ///
  /// Returns the URL of the uploaded image if successful, or null on failure.
  Future<String?> uploadImage(XFile file, {String? folder}) async {
    final session = _session;
    try {
      final length = await file.length();
      if (_session != session) return null;
      return await _uploadImage(file.name, length, file.openRead, folder);
    } catch (e) {
      debugPrint("Could not read image: $e");
      return null;
    }
  }

  Future<String?> uploadImageBytes(Uint8List bytes, String filename) =>
      _uploadImage(filename, bytes.length, () => Stream.value(bytes), null);

  Future<String?> _uploadImage(String filename, int length,
      Stream<List<int>> Function() openRead, String? folder) async {
    try {
      final url = Uri.parse(baseUrl + ApiEndpoints.apiUpload).replace(
        queryParameters: folder == null ? null : {'folder': folder},
      );
      final types = {'png': 'png', 'jpg': 'jpeg', 'jpeg': 'jpeg', 'webp': 'webp',
        'gif': 'gif', 'bmp': 'bmp', 'tiff': 'tiff', 'svg': 'svg+xml'};
      final subtype = types[filename.split('.').last.toLowerCase()];
      if (subtype == null) return null;
      if (length == 0 || length > maxImageBytes) return null;
      final response = await _withSession((token) async {
        final request = http.MultipartRequest('POST', url);
        if ((token ?? '').isNotEmpty) request.headers['Authorization'] = 'Bearer $token';
        request.files.add(http.MultipartFile('image', openRead(), length,
          filename: filename, contentType: MediaType('image', subtype)));
        return http.Response.fromStream(await _client.send(request));
      });
      if (response.statusCode == 200) {
        return jsonDecode(response.body)['imageUrl'];
      }
      debugPrint("Upload failed: ${response.statusCode}");
      return null;
    } catch (e) {
      debugPrint("Upload exception: $e");
      return null;
    }
  }

  dynamic _handleResponse(http.Response response) {
    if (response.statusCode >= 200 && response.statusCode < 300) {
      if (response.statusCode == 204 || response.statusCode == 205) return null;
      return jsonDecode(response.body);
    }

    _throwResponseError(response);
  }

  Never _throwResponseError(http.Response response) {
    String? serverMessage;
    Map? details;
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) {
        details = decoded;
        serverMessage = decoded['message']?.toString();
      }
    } catch (_) {}

    switch (response.statusCode) {
      case 401:
        throw AuthException(
            message: serverMessage ?? 'Authentication failed',
            body: response.body);
      case 403:
        if (details?['code'] == 'email_not_verified' &&
            details?['email'] is String &&
            details?['verificationId'] is String) {
          throw EmailVerificationRequired(
            email: details!['email'] as String,
            verificationId: details['verificationId'] as String,
            message: serverMessage ?? 'Check your email to finish signing in.',
          );
        }
        throw ForbiddenException(
            message: serverMessage ?? 'Access denied', body: response.body);
      case 404:
        throw NotFoundException(
            message: serverMessage ?? 'Resource not found',
            body: response.body);
      case 409:
        throw ConflictException(
            message: serverMessage ?? 'Resource conflict', body: response.body);
      default:
        if (response.statusCode >= 500) {
          throw ServerException(
              statusCode: response.statusCode,
              message: serverMessage ?? 'Internal server error',
              body: response.body);
        }
        throw ApiException(
          statusCode: response.statusCode,
          message: serverMessage ?? 'API Error',
          body: response.body,
        );
    }
  }
}
