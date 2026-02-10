import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

import 'dart:convert';
import '../services/api_service.dart';
import '../models/user.dart';
import '../database/database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../constants/api_endpoints.dart';

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

    _apiService.onTokenRefreshed = (newToken) async {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('auth_token', newToken);
      debugPrint("Auth Token refreshed and saved internally.");
    };
  }

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
        _apiService.setToken(token,
            refreshToken: refreshToken, userId: _user?.id);

        try {
          // Optionally refresh user data from server to ensure it's up-to-date
          await refreshUser();
        } catch (e) {
          debugPrint("Refresh user failed during auto-login (session likely expired): $e");
          await logout(); // Wipe invalid session
        }
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

  Future<void> _saveAuthData(
      String token, String? refreshToken, User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    if (refreshToken != null) {
      await prefs.setString('refresh_token', refreshToken);
    }
    await prefs.setString('user_data', jsonEncode(user.toJson()));
  }

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
      final data = await _apiService.post(ApiEndpoints.authLogin, {
        'username': identifier,
        'password': password,
      });

      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;

      _user = User.fromJson(data);
      _isLoading = false;

      _apiService.setToken(token,
          refreshToken: refreshToken, userId: _user?.id);

      notifyListeners();

      unawaited(_saveAuthData(token, refreshToken, _user!));
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

      await _apiService.post(ApiEndpoints.authRegister, {
        'email': email,
        'password': password,
        'username': email.split('@')[0],
        'display_name': email.split('@')[0],
      });


    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }


  Future<void> verifyRegistration(String email, String otp) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.post(ApiEndpoints.authVerifyRegistration, {
        'email': email,
        'otp': otp,
      });

      final token = data['token'] as String;
      final refreshToken = data['refreshToken'] as String?;

      _user = User.fromJson(
          data['user']); // Note: Backend returns { user: {...}, token: ... }

      _apiService.setToken(token,
          refreshToken: refreshToken, userId: _user?.id);


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
    final data = await _apiService.get(ApiEndpoints.authMe);
    if (_user != null) {
      _user = User.fromJson(data);
      notifyListeners();
    }
  }

  Future<void> updateNickname(String newName) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.put(ApiEndpoints.authProfile, {
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

  Future<void> logout() async {
    // 1. Notify backend to revoke refresh token if possible
    try {
      final prefs = await SharedPreferences.getInstance();
      final refreshToken = prefs.getString('refresh_token');
      if (refreshToken != null) {
        await _apiService.post(ApiEndpoints.authLogout, {'refreshToken': refreshToken});
      }
    } catch (e) {
      debugPrint("Logout backend notification failed: $e");
    }

    // 2. Clear local auth state
    _user = null;
    _apiService.setToken('', refreshToken: '', userId: 0);

    try {
      // 3. WIPE local user-specific data from database
      await AppDatabase().clearUserData();

      // 4. Clear saved credentials
      await _clearStorage();
    } catch (e) {
      debugPrint("Database/Storage cleanup failed during logout: $e");
    } finally {
      // Always notify listeners to update UI
      notifyListeners();
    }
  }

  /// Checks if the device is currently offline.
  Future<bool> isOffline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r == ConnectivityResult.none);
  }


  Future<void> requestOTP(String email) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post(ApiEndpoints.authRequestOtp, {'email': email});
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post(ApiEndpoints.authResetPassword, {
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
      await _apiService.post(ApiEndpoints.authVerifyEmail, {
        'email': email,
        'otp': otp,
      });
      // If we are logged in, update the user state
      if (_user != null && _user!.email == email) {
        _user = User.fromJson({
          ..._user!.toJson(),
          'is_email_verified': true,
        });
        await _saveAuthData(
            _apiService.token!, _apiService.refreshToken, _user!);
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
