
import 'package:flutter/foundation.dart';
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





  AuthProvider() {
    debugPrint("AuthProvider initializing. kIsWeb: $kIsWeb");

    // _initGoogleSignIn(); // No longer needed with new GoogleSignIn constructor
    _isInitialized = true;
    
    // 🔄 Listen for token refreshes from ApiService
    _apiService.onTokenRefreshed = (newToken) async {
       final prefs = await SharedPreferences.getInstance();
       await prefs.setString('auth_token', newToken);
       debugPrint("Auth Token refreshed and saved internally.");
    };
  }

  // _initGoogleSignIn removed as it's not standard usage for the mobile plugin

  // 🔑 Auto-login: Check for saved credentials on app start
  Future<void> tryAutoLogin() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token');
      final refreshToken = prefs.getString('refresh_token');
      final userJson = prefs.getString('user_data');

      if (token != null && userJson != null) {
        final userData = jsonDecode(userJson);
        _user = User.fromJson(userData);
        
        // Initialize ApiService with both tokens and userId
        _apiService.setToken(
          token, 
          refreshToken: refreshToken, 
          userId: _user?.id
        );
        
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
  Future<void> _saveAuthData(String token, String? refreshToken, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

  // 🗑️ Clear stored auth data
  Future<void> _clearStorage() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_data');
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();


    try {

      final data = await _apiService.post('/auth/login', {
        'username': identifier, 
        'password': password,
      });


      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;
      
      _user = User.fromJson(data);


      _apiService.setToken(
        token, 
        refreshToken: refreshToken, 
        userId: _user?.id
      );
      
      await _saveAuthData(token, refreshToken, _user!);

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
      // 1. Send Registration Request (No Token Response expected now)
      await _apiService.post('/auth/register', {
        'email': email,
        'password': password,
        'username': email.split('@')[0], 
        'display_name': email.split('@')[0], 
      });
      
      // Note: We do NOT set _user or token here anymore. 
      // The user must verify OTP first.
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // New method for the Two-Step Registration flow
  Future<void> verifyRegistration(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.post('/auth/verify-registration', {
        'email': email,
        'otp': otp,
      });

      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;
      
      _user = User.fromJson(data['user']); // Note: Backend returns { user: {...}, token: ... }
      
      _apiService.setToken(
        token, 
        refreshToken: refreshToken, 
        userId: _user?.id
      );
      
      // 💾 Save credentials for auto-login
      await _saveAuthData(token, refreshToken, _user!);
      
      notifyListeners();
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
    // ... rest of the file
    // Notify backend to revoke refresh token if possible
    try {
       final prefs = await SharedPreferences.getInstance();
       final refreshToken = prefs.getString('refresh_token');
       if (refreshToken != null) {
         await _apiService.post('/auth/logout', {'refreshToken': refreshToken});
       }
    } catch (e) {
      debugPrint("Logout backend notification failed: $e");
    }

    _user = null;
    _apiService.setToken('', refreshToken: '', userId: 0);
    
    try {
      // 🗑️ Clear saved credentials
      await _clearStorage();
    } finally {
      // Always notify listeners to update UI
      notifyListeners();
    }
  }

  Future<void> requestOTP(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/auth/request-otp', {'email': email});
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(String email, String otp, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/auth/reset-password', {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  // Legacy/Reset Verification (For existing users or password resets if needed later)
  Future<void> verifyEmail(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post('/auth/verify-email', {
        'email': email,
        'otp': otp,
      });
      // If we are logged in, update the user state
      if (_user != null && _user!.email == email) {
        _user = User.fromJson({
          ..._user!.toJson(),
          'is_email_verified': true,
        });
        await _saveAuthData(_apiService.token!, _apiService.refreshToken, _user!);
        notifyListeners();
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
  
  ApiService get apiService => _apiService;
  String? get token => _apiService.token;
}
