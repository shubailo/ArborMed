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
  int _nicknameRevision = 0;
  int get sessionRevision => _sessionVersion;
  int _pendingOperations = 0;
  int _signInAttempt = 0;
  Future<void>? _sessionWrite;
  bool _disposed = false;
  bool _isInitialized = false;

  User? get user => _user;
  bool get isLoading => _pendingOperations > 0;
  bool get isAuthenticated => _user != null;
  bool get isInitialized => _isInitialized;

  AuthProvider({AppDatabase? db, ApiService? apiService})
      : _db = db ?? AppDatabase(),
        _apiService = apiService ?? ApiService() {
    debugPrint("AuthProvider initializing. kIsWeb: $kIsWeb");

    _apiService.onTokenRefreshed = _persistRefreshedToken;
  }

  Future<void> _persistRefreshedToken(String token) async {
    final user = _user;
    if (user == null || _disposed) return;
    final saved = _saveAuthData(token, _apiService.refreshToken, user);
    notifyListeners(); // Also refresh the duel socket's next handshake credentials.
    await saved;
  }

  void _beginOperation() {
    _pendingOperations++;
    if (_pendingOperations == 1) notifyListeners();
  }

  void _endOperation({bool initialized = false}) {
    _pendingOperations--;
    if (!_disposed && (_pendingOperations == 0 || initialized)) notifyListeners();
  }

  Future<void> tryAutoLogin() async {
    final version = _sessionVersion;
    final attempt = _signInAttempt;
    _beginOperation();

    try {
      final session = await SessionStorage.read();
      if (session != null && version == _sessionVersion && attempt == _signInAttempt) {
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
      _isInitialized = true;
      _endOperation(initialized: true);
    }
  }

  Future<void> _saveAuthData(String token, String? refreshToken, User user,
      {bool replaceSession = false}) async {
    try {
      await SessionStorage.save(token, refreshToken, user.toJson(),
          replaceSession: replaceSession);
    } catch (_) {
      // The current session remains usable when a device key store is temporarily locked.
      debugPrint('The current session could not be saved to secure storage.');
    }
  }

  Future<void> _acceptSession(Map<String, dynamic> data) async {
    final token = data['token'] as String;
    final refreshToken = data['refreshToken'] as String?;
    final user = User.fromJson(
        data['user'] is Map<String, dynamic> ? data['user'] : data);
    final outgoing = _user;
    final outgoingToken = _apiService.token;
    final outgoingRefresh = _apiService.refreshToken;
    final version = ++_sessionVersion;
    _user = null;
    _apiService.setToken('');
    try {
      await SessionStorage.save(token, refreshToken, user.toJson(),
          replaceSession: true);
    } catch (_) {
      // Neither store recorded the transition. Keep the original account.
      if (version == _sessionVersion &&
          outgoing != null &&
          outgoingToken != null) {
        _user = outgoing;
        _apiService.setToken(outgoingToken,
            refreshToken: outgoingRefresh, userId: outgoing.id);
        notifyListeners();
      }
      rethrow;
    }
    if (version != _sessionVersion) return;
    _user = user;
    _apiService.setToken(token, refreshToken: refreshToken, userId: user.id);
    notifyListeners();
  }

  Future<void> _installSession(Map<String, dynamic> data) async {
    final write = _sessionWrite = _acceptSession(data);
    try {
      await write;
    } finally {
      if (identical(_sessionWrite, write)) _sessionWrite = null;
    }
  }

  Future<void> setAuthDataFromResponse(Map<String, dynamic> data) {
    _signInAttempt++;
    return _installSession(data);
  }

  Future<void> _signIn(String endpoint, Map<String, dynamic> body) async {
    final attempt = ++_signInAttempt;
    void checkAttempt() {
      if (attempt != _signInAttempt || _disposed) {
        throw const ApiException(statusCode: 0, message: 'Sign-in was superseded.');
      }
    }

    _beginOperation();
    try {
      // A previous accepted session may still be committing to device storage.
      final write = _sessionWrite;
      if (write != null) {
        try {
          await write;
        } catch (_) {
          // The prior caller receives its own storage failure.
        }
        checkAttempt();
      }
      final data = await _apiService.postPublic(endpoint, body);
      checkAttempt();
      await _installSession(data as Map<String, dynamic>);
    } finally {
      _endOperation();
    }
  }

  Future<void> login(String identifier, String password) =>
      _signIn(ApiEndpoints.authLogin, {'username': identifier, 'password': password});

  Future<String> register(String email, String password,
      {String? username, String? displayName}) async {
    _beginOperation();

    try {
      final data = await _apiService.postPublic(ApiEndpoints.authRegister, {
        'email': email,
        'password': password,
        'username': username ?? email.split('@')[0],
        'display_name': displayName ?? email.split('@')[0],
      });
      return data['registrationId'] as String;
    } finally {
      _endOperation();
    }
  }

  Future<void> resendRegistrationOTP(
      String email, String registrationId) async {
    _beginOperation();
    try {
      await _apiService.postPublic(ApiEndpoints.authResendRegistrationOtp, {
        'email': email,
        'registrationId': registrationId,
      });
    } finally {
      _endOperation();
    }
  }

  Future<void> verifyRegistration(String email, String otp, String registrationId) =>
      _signIn(ApiEndpoints.authVerifyRegistration, {
        'email': email,
        'registrationId': registrationId,
        'otp': otp,
      });

  /// Verifies a user's email address using an OTP (typically for existing unverified users).
  Future<void> verifyEmail(String email, String otp,
      {required String verificationId}) async {
    _beginOperation();
    try {
      await _apiService.postPublic(ApiEndpoints.authVerifyEmail, {
        'email': email,
        'otp': otp,
        'verificationId': verificationId,
      });
    } finally {
      _endOperation();
    }
  }

  Future<void> refreshUser() async {
    final version = _sessionVersion;
    final nicknameRevision = _nicknameRevision;
    final userId = _user?.id;
    if (userId == null) return;
    try {
      final data = await _apiService.get(ApiEndpoints.authMe);
      if (_sessionVersion != version || data['id'] != userId) return;
      await _updateCachedUser(User.fromJson({
          ...Map<String, dynamic>.from(data),
          if (nicknameRevision != _nicknameRevision) 'display_name': _user?.displayName,
        }));
    } catch (_) {
      if (_sessionVersion == version) rethrow;
    }
  }

  Future<void> updateNickname(String newName) async {
    final version = _sessionVersion;
    final userId = _user?.id;
    if (userId == null) return;
    _beginOperation();
    try {
      final data = await _apiService.put(ApiEndpoints.authProfile, {
        'display_name': newName,
      });
      if (version == _sessionVersion && _user?.id == userId) {
        _nicknameRevision++;
        await _updateCachedUser(User.fromJson({
          ..._user!.toJson(),
          'display_name': data['display_name'],
        }));
      }
    } finally {
      _endOperation();
    }
  }

  /// Sets the authoritative coin balance from a confirmed backend response.
  void updateCoinBalance(int newBalance) {
    if (_user != null) {
      unawaited(_updateCachedUser(User.fromJson({
        ..._user!.toJson(),
        'coins': newBalance,
      })));
    }
  }

  Future<void> _updateCachedUser(User user) {
    final permissionsChanged =
        _user?.role != user.role || _user?.isSuperAdmin != user.isSuperAdmin;
    _user = user;
    final token = _apiService.token;
    // Queue this snapshot before notifying listeners, which may switch accounts.
    final save = token != null && token.isNotEmpty
        ? _saveAuthData(token, _apiService.refreshToken, user,
            replaceSession: permissionsChanged)
        : Future<void>.value();
    notifyListeners();
    return save;
  }

  /// Ends the local session immediately. Revocation uses the outgoing credentials.
  Future<void> logout() => _endSession(revoke: true);

  Future<void> changePassword(
      String currentPassword, String newPassword) async {
    if (_user == null) throw const AuthException();
    final version = _sessionVersion;
    await _apiService.post(ApiEndpoints.authChangePassword, {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
    // The server already revoked this account's sessions.
    if (_sessionVersion == version) await _endSession(revoke: false);
  }

  Future<void> _endSession({required bool revoke}) async {
    final id = _user?.id;
    final token = _apiService.token;
    final refresh = _apiService.refreshToken;
    _sessionVersion++;
    _signInAttempt++;
    _user = null;
    _apiService.setToken('');
    final cleanup = Future.wait<void>([
      SessionStorage.clear(),
      if (id != null) _db.clearUserCacheFor(id),
    ]);
    notifyListeners();
    if (revoke &&
        id != null &&
        token != null &&
        refresh != null &&
        refresh.isNotEmpty) {
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
    _beginOperation();
    try {
      await _apiService.postPublic(ApiEndpoints.authRequestOtp, {
        'email': email,
        'purpose': purpose,
        if (verificationId != null) 'verificationId': verificationId,
      });
    } finally {
      _endOperation();
    }
  }

  Future<void> resetPassword(
      String email, String otp, String newPassword) async {
    _beginOperation();
    try {
      await _apiService.postPublic(ApiEndpoints.authResetPassword, {
        'email': email,
        'otp': otp,
        'newPassword': newPassword,
      });
    } finally {
      _endOperation();
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _signInAttempt++;
    _sessionVersion++;
    if (_apiService.onTokenRefreshed == _persistRefreshedToken) {
      _apiService.onTokenRefreshed = null;
    }
    super.dispose();
  }

  ApiService get apiService => _apiService;
  String? get token => _apiService.token;
}
