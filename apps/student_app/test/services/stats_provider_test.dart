import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:arbor_med/services/stats_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';

class MockApiService extends Mock implements ApiService {
  Future<dynamic> Function(String endpoint)? onGet;

  @override
  Future<dynamic> get(String? endpoint, {Map<String, String>? headers}) async {
    if (onGet != null && endpoint != null) return onGet!(endpoint);
    return null;
  }
}

class MockAuthProvider extends Mock implements AuthProvider {
  final MockApiService _apiService = MockApiService();

  @override
  ApiService get apiService => _apiService;
}

void main() {
  late StatsProvider provider;
  late MockAuthProvider mockAuth;
  late MockApiService mockApi;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockApi = mockAuth.apiService as MockApiService;
    provider = StatsProvider(mockAuth);
  });

  group('StatsProvider Initial State', () {
    test('initial values are empty or default', () {
      expect(provider.isLoading, isFalse);
      expect(provider.subjectMastery, isEmpty);
      expect(provider.activity, isEmpty);
      expect(provider.smartReview, isEmpty);
      expect(provider.readiness, isNull);
      expect(provider.currentQuote, isNull);
      expect(provider.sectionMastery, isEmpty);
      expect(provider.sectionStates, isEmpty);
    });

    test('getSectionState returns initial for unknown slug', () {
      expect(provider.getSectionState('unknown'), SubjectQuizState.initial);
    });
  });

  group('StatsProvider Student Methods', () {
    test('fetchSummary updates subjectMastery on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.statsSummary) {
          return [
            {
              'slug': 'cardiology',
              'name_en': 'Cardiology',
              'mastery_percent': 85,
              'total_answered': 100,
              'correct_answered': 85,
            }
          ];
        }
        return null;
      };

      await provider.fetchSummary();

      expect(provider.subjectMastery.length, 1);
      expect(provider.subjectMastery.first.slug, 'cardiology');
      expect(provider.isLoading, isFalse);
    });

    test('fetchSummary handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchSummary();

      expect(provider.subjectMastery, isEmpty);
      expect(provider.isLoading, isFalse);
    });

    test('fetchActivity updates activity on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint.contains(ApiEndpoints.statsActivity)) {
          return [
            {
              'date': '2023-01-01T00:00:00Z',
              'count': 50,
              'correct_count': 40,
            }
          ];
        }
        return null;
      };

      await provider.fetchActivity(timeframe: 'week');

      expect(provider.activity.length, 1);
      expect(provider.activity.first.count, 50);
    });

    test('fetchActivity handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchActivity();

      expect(provider.activity, isEmpty);
    });

    test('fetchMistakeIds returns list of ids on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint.contains(ApiEndpoints.statsMistakes)) {
          return [1, 2, '3'];
        }
        return null;
      };

      final result = await provider.fetchMistakeIds(timeframe: 'week');

      expect(result.length, 3);
      expect(result, [1, 2, 3]);
    });

    test('fetchMistakeIds returns empty list on error', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      final result = await provider.fetchMistakeIds();

      expect(result, isEmpty);
    });

    test('fetchSmartReview updates smartReview on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.statsSmartReview) {
          return {
            'recommendations': [
              {
                'topic': 'Arrhythmias',
                'slug': 'arrhythmias',
                'retention': 90.5,
                'daysSince': 5.0,
                'mastery': 80
              }
            ]
          };
        }
        return null;
      };

      await provider.fetchSmartReview();

      expect(provider.smartReview.length, 1);
      expect(provider.smartReview.first.slug, 'arrhythmias');
    });

    test('fetchSmartReview handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchSmartReview();

      expect(provider.smartReview, isEmpty);
    });

    test('fetchReadiness updates readiness on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.statsReadiness) {
          return {
            'overallReadiness': 85,
            'breakdown': []
          };
        }
        return null;
      };

      await provider.fetchReadiness();

      expect(provider.readiness, isNotNull);
      expect(provider.readiness!.overall, 85);
    });

    test('fetchReadiness handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchReadiness();

      expect(provider.readiness, isNull);
    });

    test('fetchSubjectDetail updates sectionMastery and state on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == '${ApiEndpoints.statsSubject}/cardiology') {
          return [
            {
              'section_name': 'ECG Basics',
              'mastery': 90.0,
            }
          ];
        }
        return null;
      };

      await provider.fetchSubjectDetail('cardiology');

      expect(provider.sectionMastery['cardiology']?.length, 1);
      expect(provider.sectionStates['cardiology'], SubjectQuizState.loaded);
    });

    test('fetchSubjectDetail sets empty state when data is empty', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == '${ApiEndpoints.statsSubject}/empty_subject') {
          return <Map<String, dynamic>>[];
        }
        return null;
      };

      await provider.fetchSubjectDetail('empty_subject');

      expect(provider.sectionMastery['empty_subject'], isEmpty);
      expect(provider.sectionStates['empty_subject'], SubjectQuizState.empty);
    });

    test('fetchSubjectDetail handles error gracefully and sets error state', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchSubjectDetail('cardiology');

      expect(provider.sectionStates['cardiology'], SubjectQuizState.error);
    });

    test('fetchCurrentQuote updates currentQuote on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizSingleQuote) {
          return {
            'id': 1,
            'text_en': 'Test Quote',
            'text_hu': 'Test Idezet',
            'author': 'Test Author',
          };
        }
        return null;
      };

      await provider.fetchCurrentQuote();

      expect(provider.currentQuote, isNotNull);
      expect(provider.currentQuote!.textEn, 'Test Quote');
    });

    test('fetchCurrentQuote handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchCurrentQuote();

      expect(provider.currentQuote, isNull);
    });
  });

  group('StatsProvider resetState', () {
    test('resetState clears all data', () async {
      // Setup some dirty state first
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.statsSummary) {
          return [
            {
              'subject_slug': 'cardiology',
              'subject_name': 'Cardiology',
              'mastery_percentage': 85.0,
              'total_questions': 100,
              'answered_correctly': 85,
            }
          ];
        } else if (endpoint == ApiEndpoints.quizSingleQuote) {
          return {
            'id': 1,
            'text_en': 'Test Quote',
            'text_hu': 'Test Idezet',
            'author': 'Test Author',
          };
        }
        return null;
      };

      await provider.fetchSummary();
      await provider.fetchCurrentQuote();

      expect(provider.subjectMastery, isNotEmpty);
      expect(provider.currentQuote, isNotNull);

      provider.resetState();

      expect(provider.subjectMastery, isEmpty);
      expect(provider.activity, isEmpty);
      expect(provider.isLoading, isFalse);
      expect(provider.smartReview, isEmpty);
      expect(provider.readiness, isNull);
      expect(provider.currentQuote, isNull);
      expect(provider.sectionMastery, isEmpty);
      expect(provider.sectionStates, isEmpty);
    });
  });
}
