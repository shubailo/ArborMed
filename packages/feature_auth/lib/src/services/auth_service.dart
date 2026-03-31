import 'dart:async';
import 'package:core_interop/core_interop.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthService implements AuthContract {
  static const String _tokenKey = 'auth_token';
  static const String _roleKey = 'user_role';
  static const String _userIdKey = 'user_id';

  final _authStateController = StreamController<AuthState>.broadcast();
  AuthState _authState = AuthState.unauthenticated;
  String? _authToken;
  String? _userRole;
  String? _currentUserId;

  @override
  AuthState get authState => _authState;

  @override
  Stream<AuthState> get authStateStream => _authStateController.stream;

  @override
  String? get authToken => _authToken;

  @override
  String? get userRole => _userRole;

  @override
  String? get currentUserId => _currentUserId;

  AuthService() {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString(_tokenKey);
    _userRole = prefs.getString(_roleKey);
    _currentUserId = prefs.getString(_userIdKey);

    if (_authToken != null) {
      _authState = AuthState.authenticated;
    } else {
      _authState = AuthState.unauthenticated;
    }
    _authStateController.add(_authState);
  }

  Future<void> login(String email, String password,
      {required String role}) async {
    _authState = AuthState.loading;
    _authStateController.add(_authState);

    try {
      // TODO: Implement real API call here
      // For Phase 3 initial build, we simulate a successful login
      await Future.delayed(const Duration(seconds: 1));

      final mockToken = 'mock_token_${DateTime.now().millisecondsSinceEpoch}';
      final mockUserId = 'user_123';

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, mockToken);
      await prefs.setString(_roleKey, role);
      await prefs.setString(_userIdKey, mockUserId);

      _authToken = mockToken;
      _userRole = role;
      _currentUserId = mockUserId;
      _authState = AuthState.authenticated;

      _authStateController.add(_authState);
    } catch (e) {
      _authState = AuthState.unauthenticated;
      _authStateController.add(_authState);
      rethrow;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_roleKey);
    await prefs.remove(_userIdKey);

    _authToken = null;
    _userRole = null;
    _currentUserId = null;
    _authState = AuthState.unauthenticated;
    _authStateController.add(_authState);
  }

  void dispose() {
    _authStateController.close();
  }
}
