import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  // 🔑 Auto-login: Check for saved credentials on app start
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final userJson = prefs.getString('user_data');

      if (token != null && userJson != null) {
        _apiService.setToken(token);
        _user = User.fromJson(jsonDecode(userJson));
        
        // Optionally refresh user data from server to ensure it's up-to-date
        await refreshUser();
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
      // Clear invalid data
      await _clearStorage();
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  // 💾 Save auth data to persistent storage
  Future<void> _saveAuthData(String token, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // 🗑️ Clear stored auth data
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('user_data');
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.post('/auth/login', {
        'username': identifier, // Backend accepts identifier in 'username' or 'email' field
        'password': password,
      });

      final token = data['token'];
      _apiService.setToken(token);
      _user = User.fromJson(data);
      
      // 💾 Save credentials for auto-login
      await _saveAuthData(token, _user!);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> register(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'name': email.split('@')[0], // Simple name derivation
      });

      final token = data['token'];
      _apiService.setToken(token);
      _user = User.fromJson(data);
      
      // 💾 Save credentials for auto-login
      await _saveAuthData(token, _user!);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    try {
      final data = await _apiService.get('/auth/me');
      if (_user != null) {
        _user = User.fromJson(data);
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to refresh user: $e");
    }
  }

  Future<void> updateNickname(String newName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.put('/auth/profile', {
        'display_name': newName,
      });
      if (_user != null) {
        _user = User.fromJson({
          ..._user!.toJson(),
          'display_name': data['display_name'],
        });
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void logout() async {
    _user = null;
    _apiService.setToken('');
    
    // 🗑️ Clear saved credentials
    await _clearStorage();
    
    notifyListeners();
  }
  
  ApiService get apiService => _apiService;
  String? get token => _apiService.token;
}
