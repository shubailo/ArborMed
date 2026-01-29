import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  bool _isLoading = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.post('/auth/login', {
        'email': email,
        'password': password,
      });

      _apiService.setToken(data['token']);
      _user = User.fromJson(data);
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

      _apiService.setToken(data['token']);
      _user = User.fromJson(data);
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
        // We update internal user fields. Token remains managed by ApiService.
        _user = User(
            id: data['id'],
            email: data['email'],
            role: data['role'],
            coins: data['coins'] ?? 0,
            xp: data['xp'] ?? 0,
            level: data['level'] ?? 1,
            streakCount: data['streak_count'] ?? 0
        );
        notifyListeners();
      }
    } catch (e) {
      debugPrint("Failed to refresh user: $e");
    }
  }

  void logout() {
    _user = null;
    _apiService.setToken('');
    notifyListeners();
  }
  
  ApiService get apiService => _apiService;
  String? get token => _apiService.token;
}
