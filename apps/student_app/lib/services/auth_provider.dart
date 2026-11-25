import 'package:flutter/foundation.dart';
import 'session_storage.dart';
import 'dart:async';

import '../services/api_service.dart';
import '../core/models/user.dart';
import '../database/database.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import '../core/api_exceptions.dart';

/// Manages the application's authentication state, user session, and token persistence.
/// Extends [ChangeNotifier] to update the UI globally upon login, logout, or profile updates.
/// Integrates with [ApiService] and [AppDatabase] for remote and local data storage respectively.
class AuthProvider with ChangeNotifier {
  final ApiService _apiService;
  final AppDatabase _db;
  User? _user;
  int _sessionVersion = 0;
  bool _isLoading = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider({AppDatabase? db, ApiService? apiService})
      : _db = db ?? AppDatabase(),
        _apiService = apiService ?? ApiService() {
    debugPrint("AuthProvider initializing. kIsWeb: $kIsWeb");

    _apiService.onTokenRefreshed = (newToken) async {
      final user = _user;
      if (user != null) {
        await _saveAuthData(newToken, _apiService.refreshToken, user);
      }
    };
  }

  Future<void> tryAutoLogin() async {
    final version = _sessionVersion;
    _isLoading = true;
    notifyListeners();

    try {
      final session = await SessionStorage.read();
      if (session != null && version == _sessionVersion) {
        final token = session['token'] as String;
        final refreshToken = session['refreshToken'] as String?;
        final userData = session['user'] as Map<String, dynamic>;
        _user = User.fromJson(userData);

        // Initialize ApiService with both tokens and userId
        _apiService.setToken(token,
            refreshToken: refreshToken, userId: _user?.id);

        try {
          // Optionally refresh user data from server if online
          await refreshUser();
        } on AuthException catch (e) {
          debugPrint(
              "Refresh user failed with auth error (session expired or revoked): $e");
          if (version == _sessionVersion) await logout();
        } catch (e) {
          debugPrint(
              "Server unreachable during auto-login (cold-start or offline), keeping cached session: $e");
          // Graceful degradation: keep local user logged in from cache
        }
      }
    } catch (e) {
      debugPrint('Auto-login failed: $e');
      // The platform key store can be temporarily unavailable while locked.
    } finally {
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }
  }

  Future<void> _saveAuthData(
      String token, String? refreshToken, User user) async {
    try {
      await SessionStorage.save(token, refreshToken, user.toJson());
    } catch (_) {
      // The current session remains usable when a device key store is temporarily locked.
      debugPrint('The current session could not be saved to secure storage.');
    }
  }

  Future<void> _acceptSession(Map<String, dynamic> data) {
    final token = data['token'] as String;
    final refreshToken = data['refreshToken'] as String?;
    final user = User.fromJson(
        data['user'] is Map<String, dynamic> ? data['user'] : data);
    _sessionVersion++;
    _user = user;
    _isLoading = false;
    _apiService.setToken(token, refreshToken: refreshToken, userId: user.id);
    final save = _saveAuthData(token, refreshToken, user);
    notifyListeners();
    return save;
  }

  void setAuthDataFromResponse(Map<String, dynamic> data) {
    unawaited(_acceptSession(data));
  }

  Future<void> login(String identifier, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.post(ApiEndpoints.authLogin, {
        'username': identifier,
        'password': password,
      });
      await _acceptSession(data as Map<String, dynamic>);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String> register(String email, String password,
      {String? username, String? displayName}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final data = await _apiService.post(ApiEndpoints.authRegister, {
        'email': email,
        'password': password,
        'username': username ?? email.split('@')[0],
        'display_name': displayName ?? email.split('@')[0],
      });
      return data['registrationId'] as String;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> resendRegistrationOTP(
      String email, String registrationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post(ApiEndpoints.authResendRegistrationOtp, {
        'email': email,
        'registrationId': registrationId,
      });
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> verifyRegistration(
      String email, String otp, String registrationId) async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.post(ApiEndpoints.authVerifyRegistration, {
        'email': email,
        'registrationId': registrationId,
        'otp': otp,
      });

      await _acceptSession(data as Map<String, dynamic>);
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Verifies a user's email address using an OTP (typically for existing unverified users).
  Future<void> verifyEmail(String email, String otp,
      {required String verificationId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post(ApiEndpoints.authVerifyEmail, {
        'email': email,
        'otp': otp,
        'verificationId': verificationId,
      });
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> refreshUser() async {
    final version = _sessionVersion;
    final userId = _user?.id;
    if (userId == null) return;
    try {
      final data = await _apiService.get(ApiEndpoints.authMe);
      if (_sessionVersion != version || data['id'] != userId) return;
      _user = User.fromJson(data);
      notifyListeners();
    } catch (_) {
      if (_sessionVersion == version) rethrow;
    }
  }

  Future<void> updateNickname(String newName) async {
    final userId = _user?.id;
    if (userId == null) return;
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.put(ApiEndpoints.authProfile, {
        'display_name': newName,
      });
      if (_user?.id == userId) {
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

  /// Sets the authoritative coin balance from a confirmed backend response.
  void updateCoinBalance(int newBalance) {
    if (_user != null) {
      _user = User.fromJson({
        ..._user!.toJson(),
        'coins': newBalance,
      });
      final token = _apiService.token ?? '';
      unawaited(_saveAuthData(token, _apiService.refreshToken, _user!));
      notifyListeners();
    }
  }

  /// Ends the local session immediately. Revocation uses the outgoing credentials.
  Future<void> logout() async {
    final id = _user?.id;
    final token = _apiService.token;
    final refresh = _apiService.refreshToken;
    _sessionVersion++;
    _user = null;
    _apiService.setToken('');
    final cleanup = Future.wait<void>([
      SessionStorage.clear(),
      if (id != null) _db.clearUserCacheFor(id),
    ]);
    notifyListeners();
    if (id != null && token != null && refresh != null && refresh.isNotEmpty) {
      unawaited(
          _apiService.revokeSession(token, refresh, id).catchError((Object _) {
        debugPrint('Could not revoke the outgoing session on the server.');
      }));
    }
    await cleanup;
  }

  /// Checks if the device is currently offline.
  Future<bool> isOffline() async {
    final results = await Connectivity().checkConnectivity();
    return results.any((r) => r == ConnectivityResult.none);
  }

  Future<void> requestOTP(String email,
      {String purpose = 'password-reset', String? verificationId}) async {
    _isLoading = true;
    notifyListeners();
    try {
      await _apiService.post(ApiEndpoints.authRequestOtp, {
        'email': email,
        'purpose': purpose,
        if (verificationId != null) 'verificationId': verificationId,
      });
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

  ApiService get apiService => _apiService;
  String? get token => _apiService.token;
}
