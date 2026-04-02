import 'dart:async';
import 'dart:convert';
import 'package:core_interop/core_interop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import 'package:arbormed_core/arbormed_core.dart';

class AuthService implements AuthContract {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _userDataKey = 'user_data';

  final ApiService _api = ApiService();
  final _authStateController = StreamController<AuthState>.broadcast();

  AuthState _authState = AuthState.unauthenticated;
  String? _authToken;
  String? _userRole;
  String? _currentUserId;
  User? _user;

  @override
  AuthState get authState => _authState;

  @override
  Stream<AuthState> get authStateStream async* {
    yield _authState;
    yield* _authStateController.stream;
  }

  @override
  String? get authToken => _authToken;

  @override
  String? get userRole => _userRole;

  @override
  String? get currentUserId => _currentUserId;

  User? get user => _user;

  AuthService() {
    _init();
    _api.onTokenRefreshed = (newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, newToken);
      _authToken = newToken;
    };
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _userRole = prefs.getString(_roleKey);
    _currentUserId = prefs.getString(_userIdKey);
    final userJson = prefs.getString(_userDataKey);

    if (_authToken != null && userJson != null) {
      try {
        _user = User.fromJson(jsonDecode(userJson));
        _api.setToken(_authToken!,
            refreshToken: prefs.getString(_refreshTokenKey),
            userId: int.tryParse(_currentUserId ?? '0'));
        _authState = AuthState.authenticated;
      } catch (e) {
        debugPrint("Failed to restore user session: $e");
        await logout();
      }
    } else {
      _authState = AuthState.unauthenticated;
    }
    _authStateController.add(_authState);
  }

  @override
  Future<void> login(String identifier, String password) async {
    _authState = AuthState.loading;
    _authStateController.add(_authState);

    try {
      final data = await _api.post(ApiEndpoints.authLogin, {
        'username': identifier,
        'password': password,
      });

      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;
      _user = User.fromJson(data);

      _api.setToken(token, refreshToken: refreshToken, userId: _user?.id);

      _authToken = token;
      _userRole = _user?.role;
      _currentUserId = _user?.id.toString();
      _authState = AuthState.authenticated;

      await _saveAuthData(token, refreshToken, _user!);

      debugPrint("[AuthService] Login successful. Role: ${_user?.role}");
      _authStateController.add(_authState);
    } catch (e) {
      debugPrint("[AuthService] Login failed: $e");
      _authState = AuthState.unauthenticated;
      _authStateController.add(_authState);
      rethrow;
    }
  }

  @override
  Future<void> register(
    String email,
    String password, {
    String? username,
    String? displayName,
  }) async {
    _authState = AuthState.loading;
    _authStateController.add(_authState);
    try {
      final fallback = email.split('@')[0];
      await _api.post(ApiEndpoints.authRegister, {
        'email': email,
        'password': password,
        'username': username ?? fallback,
        'display_name': displayName ?? fallback,
      });
    } finally {
      _authState = AuthState.unauthenticated;
      _authStateController.add(_authState);
    }
  }

  @override
  Future<void> verifyEmail(String email, String otp) async {
    try {
      final data = await _api.post(ApiEndpoints.authVerifyRegistration, {
        'email': email,
        'otp': otp,
      });

      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;
      _user = User.fromJson(data['user']);

      _api.setToken(token, refreshToken: refreshToken, userId: _user?.id);
      _authToken = token;
      _userRole = _user?.role;
      _currentUserId = _user?.id.toString();
      _authState = AuthState.authenticated;

      await _saveAuthData(token, refreshToken, _user!);
      _authStateController.add(_authState);
    } catch (e) {
      rethrow;
    }
  }

  @override
  Future<void> requestOTP(String email) async {
    await _api.post(ApiEndpoints.authRequestOtp, {'email': email});
  }

  @override
  Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    await _api.post(ApiEndpoints.authResetPassword, {
      'email': email,
      'otp': otp,
      'newPassword': newPassword,
    });
  }

  @override
  Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString(_refreshTokenKey);
      if (refreshToken != null) {
        await _api.post(ApiEndpoints.authLogout,
            {'refreshToken': refreshToken}).timeout(const Duration(seconds: 5));
      }
    } catch (e) {
      debugPrint("Logout backend notification failed: $e");
    }

    _authToken = null;
    _userRole = null;
    _currentUserId = null;
    _user = null;
    _authState = AuthState.unauthenticated;

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Clear all auth data

    _api.setToken('', refreshToken: '', userId: 0);
    _authStateController.add(_authState);
  }

  Future<void> _saveAuthData(
      String token, String? refreshToken, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    if (refreshToken != null) {
      await prefs.setString(_refreshTokenKey, refreshToken);
    }
    await prefs.setString(_roleKey, user.role);
    await prefs.setString(_userIdKey, user.id.toString());
    await prefs.setString(_userDataKey, jsonEncode(user.toJson()));
  }

  void dispose() {
    _authStateController.close();
  }
}
