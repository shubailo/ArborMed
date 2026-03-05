import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/models/user.dart';

@GenerateNiceMocks([MockSpec<ApiService>()])
import 'auth_provider_test.mocks.dart';

import 'package:flutter/services.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late MockApiService mockApiService;
  late AuthProvider authProvider;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('plugins.flutter.io/path_provider'), (MethodCall methodCall) async {
      return '.';
    });
    SharedPreferences.setMockInitialValues({});
    mockApiService = MockApiService();
    authProvider = AuthProvider(apiService: mockApiService);
  });

  group('AuthProvider Tests', () {
    test('Initial state is correct', () {
      expect(authProvider.user, isNull);
      expect(authProvider.isLoading, isFalse);
      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.isInitialized, isFalse);
    });

    test('tryAutoLogin with valid local data', () async {
      final userJson = {
        'id': 1,
        'email': 'test@test.com',
        'role': 'student',
        'coins': 100,
        'xp': 50,
        'level': 2,
        'streak_count': 5,
      };

      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_token',
        'refresh_token': 'fake_refresh_token',
        'user_data': jsonEncode(userJson),
      });

      // Avoid actual HTTP call in tryAutoLogin -> refreshUser
      when(mockApiService.get(any)).thenAnswer((_) async => userJson);

      await authProvider.tryAutoLogin();

      expect(authProvider.isInitialized, isTrue);
      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.id, 1);
      verify(mockApiService.setToken('fake_token',
          refreshToken: 'fake_refresh_token', userId: 1)).called(1);
    });

    test('login sets user and saves data', () async {
      final mockData = {
        'token': 'new_token',
        'refreshToken': 'new_refresh',
        'id': 2,
        'email': 'login@test.com',
        'role': 'student',
        'coins': 0,
        'xp': 0,
        'level': 1,
        'streak_count': 0,
      };

      when(mockApiService.post(any, any)).thenAnswer((_) async => mockData);

      await authProvider.login('login@test.com', 'password123');

      expect(authProvider.isAuthenticated, isTrue);
      expect(authProvider.user?.id, 2);
      expect(authProvider.user?.email, 'login@test.com');

      // Wait for SharedPreferences save to complete (since it's unawaited)
      await Future.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), 'new_token');
    });

    test('earnReward updates user coins optimistically', () async {
      // Setup initial state
      final userJson = {
        'id': 1,
        'email': 'test@test.com',
        'role': 'student',
        'coins': 100,
        'xp': 50,
        'level': 2,
        'streak_count': 5,
      };

      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_token',
        'user_data': jsonEncode(userJson),
      });
      when(mockApiService.get(any)).thenAnswer((_) async => userJson);
      when(mockApiService.token).thenReturn('fake_token');
      when(mockApiService.refreshToken).thenReturn('fake_refresh');

      await authProvider.tryAutoLogin();

      expect(authProvider.user?.coins, 100);

      authProvider.earnReward(50);

      expect(authProvider.user?.coins, 150);

      // Check saved data
      await Future.delayed(Duration.zero);
      final prefs = await SharedPreferences.getInstance();
      final savedData = jsonDecode(prefs.getString('user_data')!);
      expect(savedData['coins'], 150);
    });

    test('updateNickname updates display name and calls API', () async {
      final userJson = {
        'id': 1,
        'email': 'test@test.com',
        'display_name': 'OldName',
        'role': 'student',
        'coins': 100,
        'xp': 50,
        'level': 2,
        'streak_count': 5,
      };

      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_token',
        'user_data': jsonEncode(userJson),
      });
      when(mockApiService.get(any)).thenAnswer((_) async => userJson);

      await authProvider.tryAutoLogin();

      when(mockApiService.put(any, any)).thenAnswer((_) async => {
        'display_name': 'NewName',
      });

      await authProvider.updateNickname('NewName');

      expect(authProvider.user?.displayName, 'NewName');
      verify(mockApiService.put(any, {'display_name': 'NewName'})).called(1);
    });

    test('logout clears user state and calls API', () async {
      final userJson = {
        'id': 1,
        'email': 'test@test.com',
        'role': 'student',
        'coins': 100,
        'xp': 50,
        'level': 2,
        'streak_count': 5,
      };

      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_token',
        'refresh_token': 'fake_refresh_token',
        'user_data': jsonEncode(userJson),
      });
      when(mockApiService.get(any)).thenAnswer((_) async => userJson);
      when(mockApiService.post(any, any)).thenAnswer((_) async => {});

      await authProvider.tryAutoLogin();
      expect(authProvider.isAuthenticated, isTrue);

      await authProvider.logout();

      expect(authProvider.isAuthenticated, isFalse);
      expect(authProvider.user, isNull);

      verify(mockApiService.post(any, {'refreshToken': 'fake_refresh_token'})).called(1);
      verify(mockApiService.setToken('', refreshToken: '', userId: 0)).called(1);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('auth_token'), isNull);
    });

    test('refreshUser fetches and updates user state', () async {
      // Setup initial state
      final userJson = {
        'id': 1,
        'email': 'test@test.com',
        'role': 'student',
        'coins': 100,
        'xp': 50,
        'level': 2,
        'streak_count': 5,
      };

      SharedPreferences.setMockInitialValues({
        'auth_token': 'fake_token',
        'user_data': jsonEncode(userJson),
      });
      when(mockApiService.get(any)).thenAnswer((_) async => userJson);
      await authProvider.tryAutoLogin();

      // Setup refreshed data
      final refreshedUserJson = {
        'id': 1,
        'email': 'test@test.com',
        'role': 'student',
        'coins': 200, // Updated coins
        'xp': 100, // Updated xp
        'level': 3, // Updated level
        'streak_count': 5,
      };

      when(mockApiService.get(any)).thenAnswer((_) async => refreshedUserJson);

      await authProvider.refreshUser();

      expect(authProvider.user?.coins, 200);
      expect(authProvider.user?.xp, 100);
      expect(authProvider.user?.level, 3);
    });
  });
}
