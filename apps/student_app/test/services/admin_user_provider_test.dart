import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:arbor_med/services/admin_user_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/models/performance.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {
  @override
  Future<dynamic> get(String? endpoint) async {
    return super.noSuchMethod(Invocation.method(#get, [endpoint]), returnValue: Future.value(null));
  }

  @override
  Future<dynamic> put(String? endpoint, Map<String, dynamic>? data) async {
    return super.noSuchMethod(Invocation.method(#put, [endpoint, data]), returnValue: Future.value(null));
  }

  @override
  Future<dynamic> delete(String? endpoint) async {
    return super.noSuchMethod(Invocation.method(#delete, [endpoint]), returnValue: Future.value(null));
  }

  @override
  Future<dynamic> post(String? endpoint, Map<String, dynamic>? data) async {
    return super.noSuchMethod(Invocation.method(#post, [endpoint, data]), returnValue: Future.value(null));
  }
}

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  final MockApiService _apiService = MockApiService();

  @override
  ApiService get apiService => _apiService;
}

void main() {
  late MockAuthProvider mockAuth;
  late MockApiService mockApi;
  late AdminUserProvider provider;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockApi = mockAuth.apiService as MockApiService;
    provider = AdminUserProvider(mockAuth);
  });

  group('AdminUserProvider Tests', () {
    test('initial state is empty and not loading', () {
      expect(provider.isLoading, isFalse);
      expect(provider.usersPerformance, isEmpty);
      expect(provider.totalStudents, 0);
      expect(provider.adminsPerformance, isEmpty);
      expect(provider.totalAdmins, 0);
      expect(provider.userHistory, isEmpty);
      expect(provider.questionStats, isEmpty);
      expect(provider.userStats['total_users'], 0);
      expect(provider.adminSummary, isEmpty);
      expect(provider.inventorySummary, isEmpty);
    });

    test('fetchUsersPerformance parses map response correctly', () async {
      final mockResponse = {
        'users': [
          {
            'id': 1,
            'email': 'student@test.com',
            'created_at': '2023-01-01T00:00:00Z',
          }
        ],
        'total': 100
      };

      when(mockApi.get(any)).thenAnswer((_) async => mockResponse);

      await provider.fetchUsersPerformance();

      expect(provider.usersPerformance.length, 1);
      expect(provider.usersPerformance.first.id, 1);
      expect(provider.usersPerformance.first.email, 'student@test.com');
      expect(provider.totalStudents, 100);
      expect(provider.isLoading, isFalse);
    });

    test('fetchUsersPerformance parses list response correctly', () async {
      final mockResponse = [
        {
          'id': 2,
          'email': 'student2@test.com',
          'created_at': '2023-01-01T00:00:00Z',
        }
      ];

      when(mockApi.get(any)).thenAnswer((_) async => mockResponse);

      await provider.fetchUsersPerformance();

      expect(provider.usersPerformance.length, 1);
      expect(provider.usersPerformance.first.id, 2);
      expect(provider.totalStudents, 1);
    });

    test('fetchUsersPerformance handles error gracefully', () async {
      when(mockApi.get(any)).thenThrow(Exception('API Error'));
      await provider.fetchUsersPerformance();
      expect(provider.usersPerformance, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('fetchAdminsPerformance updates admin list', () async {
      final mockResponse = {
        'users': [
          {
            'id': 3,
            'email': 'admin@test.com',
            'created_at': '2023-01-01T00:00:00Z',
          }
        ],
        'total': 5
      };

      when(mockApi.get(any)).thenAnswer((_) async => mockResponse);

      await provider.fetchAdminsPerformance();

      expect(provider.adminsPerformance.length, 1);
      expect(provider.adminsPerformance.first.id, 3);
      expect(provider.totalAdmins, 5);
    });

    test('fetchAdminsPerformance parses list response correctly', () async {
      final mockResponse = [
        {
          'id': 4,
          'email': 'admin2@test.com',
          'created_at': '2023-01-01T00:00:00Z',
        }
      ];

      when(mockApi.get(any)).thenAnswer((_) async => mockResponse);

      await provider.fetchAdminsPerformance();

      expect(provider.adminsPerformance.length, 1);
      expect(provider.adminsPerformance.first.id, 4);
      expect(provider.totalAdmins, 1);
    });

    test('fetchAdminsPerformance handles error gracefully', () async {
      when(mockApi.get(any)).thenThrow(Exception('API Error'));
      await provider.fetchAdminsPerformance();
      expect(provider.adminsPerformance, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('fetchUserHistory loads correctly', () async {
      final mockResponse = [
        {
          'id': 10,
          'created_at': '2023-01-01T00:00:00Z',
          'is_correct': true,
          'response_time_ms': 1500,
          'question_text_en': 'Test Q',
          'bloom_level': 2,
          'section_name': 'Sec 1',
          'subject_name': 'Subj 1',
          'subject_slug': 'subj-1'
        }
      ];

      when(mockApi.get('${ApiEndpoints.statsAdminUserBase}/1/history?limit=100'))
          .thenAnswer((_) async => mockResponse);

      await provider.fetchUserHistory(1);

      expect(provider.userHistory.length, 1);
      expect(provider.userHistory.first.id, 10);
      expect(provider.userHistory.first.isCorrect, isTrue);
    });

    test('fetchUserHistory handles error gracefully', () async {
      when(mockApi.get(any)).thenThrow(Exception('API Error'));
      await provider.fetchUserHistory(1);
      expect(provider.userHistory, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('updateUserRole refreshes both lists on success', () async {
      when(mockApi.put(ApiEndpoints.adminUserRole, {'userId': 1, 'newRole': 'admin'}))
          .thenAnswer((_) async => {});

      // Mock empty lists for the subsequent fetches
      when(mockApi.get(argThat(contains(ApiEndpoints.statsAdminUsersPerformance))))
          .thenAnswer((_) async => {'users': [], 'total': 0});
      when(mockApi.get(argThat(contains(ApiEndpoints.adminAdmins))))
          .thenAnswer((_) async => {'users': [], 'total': 0});

      final result = await provider.updateUserRole(1, 'admin');

      expect(result, isTrue);
      verify(mockApi.put(ApiEndpoints.adminUserRole, any)).called(1);
      verify(mockApi.get(argThat(contains(ApiEndpoints.statsAdminUsersPerformance)))).called(1);
      verify(mockApi.get(argThat(contains(ApiEndpoints.adminAdmins)))).called(1);
    });

    test('updateUserRole returns false on failure', () async {
      when(mockApi.put(ApiEndpoints.adminUserRole, any))
          .thenThrow(Exception('API Error'));

      final result = await provider.updateUserRole(1, 'admin');

      expect(result, isFalse);
    });

    test('deleteUser refreshes lists on success', () async {
      when(mockApi.delete('${ApiEndpoints.adminUserBase}/1'))
          .thenAnswer((_) async => {});

      when(mockApi.get(argThat(contains(ApiEndpoints.statsAdminUsersPerformance))))
          .thenAnswer((_) async => {'users': [], 'total': 0});
      when(mockApi.get(argThat(contains(ApiEndpoints.adminAdmins))))
          .thenAnswer((_) async => {'users': [], 'total': 0});

      final result = await provider.deleteUser(1);

      expect(result, isTrue);
      verify(mockApi.delete('${ApiEndpoints.adminUserBase}/1')).called(1);
    });

    test('deleteUser returns false on failure', () async {
      when(mockApi.delete(any)).thenThrow(Exception('API Error'));
      final result = await provider.deleteUser(1);
      expect(result, isFalse);
    });

    test('fetchQuestionStats parses correctly with fallback values', () async {
      final mockResponse = {
        'questionStats': [
          {
            'question_id': 'q1',
            'question_text': 'Text',
            'topic_slug': 'topic1',
            'bloom_level': 3,
            'total_attempts': 10,
            'correct_count': 5,
            'avg_time_ms': 2000,
            'correct_percentage': 50
          }
        ],
        'userStats': {
          'total_users': 500,
          'avg_session_mins': 15,
          'avg_bloom': 2.5
        }
      };

      when(mockApi.get(ApiEndpoints.statsQuestions))
          .thenAnswer((_) async => mockResponse);

      await provider.fetchQuestionStats();

      expect(provider.questionStats.length, 1);
      expect(provider.questionStats.first.questionId, 'q1');
      expect(provider.userStats['total_users'], 500);
      expect(provider.userStats['avg_bloom'], 2.5);
    });

    test('fetchQuestionStats with topicId', () async {
      when(mockApi.get('${ApiEndpoints.statsQuestions}?topicId=123'))
          .thenAnswer((_) async => {
                'questionStats': [],
                'userStats': {'total_users': 0, 'avg_session_mins': 0}
              });

      await provider.fetchQuestionStats(topicId: 123);

      verify(mockApi.get('${ApiEndpoints.statsQuestions}?topicId=123')).called(1);
    });

    test('fetchQuestionStats handles error gracefully', () async {
      when(mockApi.get(any)).thenThrow(Exception('API Error'));
      await provider.fetchQuestionStats();
      expect(provider.questionStats, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('sendDirectMessage succeeds', () async {
      when(mockApi.post(ApiEndpoints.adminNotify, {'userId': 1, 'message': 'Hello'}))
          .thenAnswer((_) async => {});

      final result = await provider.sendDirectMessage(1, 'Hello');
      expect(result, isTrue);
    });

    test('sendDirectMessage handles error', () async {
      when(mockApi.post(any, any)).thenThrow(Exception('Error'));
      final result = await provider.sendDirectMessage(1, 'Hello');
      expect(result, isFalse);
    });

    test('fetchAdminSummary loads correctly', () async {
      final mockResponse = [
        {'stat': 'test', 'value': 1}
      ];
      when(mockApi.get(ApiEndpoints.statsAdminSummary))
          .thenAnswer((_) async => mockResponse);

      await provider.fetchAdminSummary();
      expect(provider.adminSummary.length, 1);
      expect(provider.adminSummary.first['stat'], 'test');
    });

    test('fetchAdminSummary handles error', () async {
      when(mockApi.get(ApiEndpoints.statsAdminSummary)).thenThrow(Exception('Error'));
      await provider.fetchAdminSummary();
      expect(provider.adminSummary, isEmpty);
    });

    test('fetchInventorySummary loads correctly', () async {
      final mockResponse = [
        {'item': 'test', 'count': 1}
      ];
      when(mockApi.get(ApiEndpoints.statsInventorySummary))
          .thenAnswer((_) async => mockResponse);

      await provider.fetchInventorySummary();
      expect(provider.inventorySummary.length, 1);
      expect(provider.inventorySummary.first['item'], 'test');
    });

    test('fetchInventorySummary handles error', () async {
      when(mockApi.get(ApiEndpoints.statsInventorySummary)).thenThrow(Exception('Error'));
      await provider.fetchInventorySummary();
      expect(provider.inventorySummary, isEmpty);
    });

    test('fetchAdminUserAnalytics loads correctly', () async {
      final mockResponse = {'analytics': 'data'};
      when(mockApi.get('${ApiEndpoints.statsAdminUserBase}/1/analytics'))
          .thenAnswer((_) async => mockResponse);

      final result = await provider.fetchAdminUserAnalytics(1);
      expect(result, mockResponse);
    });

    test('fetchAdminUserAnalytics handles error', () async {
      when(mockApi.get('${ApiEndpoints.statsAdminUserBase}/1/analytics'))
          .thenThrow(Exception('Error'));

      final result = await provider.fetchAdminUserAnalytics(1);
      expect(result, isNull);
    });

    test('resetState clears all data', () {
      // Setup some dirty state first
      provider.usersPerformance.add(UserPerformance(
        id: 1, email: 'a', createdAt: DateTime.now(),
        pathophysiology: SubjectPerformance(avgScore: 0, totalQuestions: 0, correctQuestions: 0, avgTimeMs: 0),
        pathology: SubjectPerformance(avgScore: 0, totalQuestions: 0, correctQuestions: 0, avgTimeMs: 0),
        microbiology: SubjectPerformance(avgScore: 0, totalQuestions: 0, correctQuestions: 0, avgTimeMs: 0),
        pharmacology: SubjectPerformance(avgScore: 0, totalQuestions: 0, correctQuestions: 0, avgTimeMs: 0),
        ecg: SubjectPerformance(avgScore: 0, totalQuestions: 0, correctQuestions: 0, avgTimeMs: 0),
        cases: SubjectPerformance(avgScore: 0, totalQuestions: 0, correctQuestions: 0, avgTimeMs: 0),
      ));

      provider.resetState();

      expect(provider.usersPerformance, isEmpty);
      expect(provider.totalStudents, 0);
      expect(provider.adminsPerformance, isEmpty);
      expect(provider.totalAdmins, 0);
      expect(provider.userHistory, isEmpty);
      expect(provider.questionStats, isEmpty);
      expect(provider.adminSummary, isEmpty);
      expect(provider.inventorySummary, isEmpty);
      expect(provider.userStats['total_users'], 0);
      expect(provider.isLoading, isFalse);
    });
  });
}
