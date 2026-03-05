import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:arbor_med/services/admin_question_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/services/download/download_helper.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {
  Future<dynamic> Function(String endpoint)? onGet;
  Future<dynamic> Function(String endpoint, Map<String, dynamic> data)? onPost;
  Future<dynamic> Function(String endpoint, Map<String, dynamic> data)? onPut;
  Future<dynamic> Function(String endpoint)? onDelete;
  Future<dynamic> Function(String endpoint,
      {required List<int> bytes,
      required String filename,
      String fieldName})? onPostMultipart;
  Future<List<int>> Function(String endpoint)? onGetBytes;

  @override
  Future<dynamic> get(String? endpoint) async {
    if (onGet != null && endpoint != null) return onGet!(endpoint);
    return null;
  }

  @override
  Future<dynamic> post(String? endpoint, Map<String, dynamic>? data) async {
    if (onPost != null && endpoint != null && data != null) {
      return onPost!(endpoint, data);
    }
    return null;
  }

  @override
  Future<dynamic> put(String? endpoint, Map<String, dynamic>? data) async {
    if (onPut != null && endpoint != null && data != null) {
      return onPut!(endpoint, data);
    }
    return null;
  }

  @override
  Future<dynamic> delete(String? endpoint) async {
    if (onDelete != null && endpoint != null) return onDelete!(endpoint);
    return null;
  }

  @override
  Future<dynamic> postMultipart(String endpoint,
      {required List<int> bytes,
      required String filename,
      String fieldName = 'file'}) async {
    if (onPostMultipart != null) {
      return onPostMultipart!(endpoint,
          bytes: bytes, filename: filename, fieldName: fieldName);
    }
    return null;
  }

  @override
  Future<List<int>> getBytes(String? endpoint) async {
    if (onGetBytes != null && endpoint != null) {
      return onGetBytes!(endpoint);
    }
    return <int>[];
  }
}

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  final MockApiService _apiService = MockApiService();

  @override
  ApiService get apiService => _apiService;
}

// Mock DownloadHelper
class MockDownloadHelper extends Mock implements DownloadHelper {
  Future<void> Function(List<int> bytes, String filename, String mimeType)?
      onDownload;

  @override
  Future<void> download(
      List<int>? bytes, String? filename, String? mimeType) async {
    if (onDownload != null &&
        bytes != null &&
        filename != null &&
        mimeType != null) {
      await onDownload!(bytes, filename, mimeType);
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AdminQuestionProvider provider;
  late MockAuthProvider mockAuth;
  late MockApiService mockApi;
  late MockDownloadHelper mockDownloadHelper;

  setUp(() {
    mockAuth = MockAuthProvider();
    mockApi = mockAuth.apiService as MockApiService;
    provider = AdminQuestionProvider(mockAuth);

    mockDownloadHelper = MockDownloadHelper();
    downloadHelper = mockDownloadHelper; // override global
  });

  group('AdminQuestionProvider Initial State', () {
    test('initial values are empty or default', () {
      expect(provider.isLoading, isFalse);
      expect(provider.adminQuestions, isEmpty);
      expect(provider.adminTotalQuestions, 0);
      expect(provider.wallOfPain['failedQuestions'], isEmpty);
      expect(provider.wallOfPain['difficultTopics'], isEmpty);
      expect(provider.ecgCases, isEmpty);
      expect(provider.ecgDiagnoses, isEmpty);
    });
  });

  group('AdminQuestionProvider CRUD', () {
    test('fetchAdminQuestions updates state on success', () async {
      mockApi.onGet = (endpoint) async {
        return {
          'questions': [
            {
              'id': 1,
              'text': 'Q1',
              'options': [],
              'correct_answer': 'A',
              'topic_id': 1,
              'bloom_level': 1,
            }
          ],
          'total': 1,
        };
      };

      await provider.fetchAdminQuestions();

      expect(provider.adminQuestions.length, 1);
      expect(provider.adminQuestions.first.id, 1);
      expect(provider.adminTotalQuestions, 1);
      expect(provider.isLoading, isFalse);
    });

    test('fetchAdminQuestions with filters', () async {
      mockApi.onGet = (endpoint) async {
        expect(endpoint.contains('type=mcq'), isTrue);
        expect(endpoint.contains('bloom_level=2'), isTrue);
        expect(endpoint.contains('topic_id=3'), isTrue);
        return {
          'questions': [],
          'total': 0,
        };
      };

      await provider.fetchAdminQuestions(
          type: 'mcq', bloomLevel: 2, topicId: 3);
    });

    test('createQuestion returns true on success', () async {
      mockApi.onPost = (endpoint, data) async {
        return {'success': true};
      };

      final result = await provider.createQuestion({'text': 'New Q'});
      expect(result, isTrue);
    });

    test('updateQuestion returns true on success', () async {
      mockApi.onPut = (endpoint, data) async {
        return {'success': true};
      };

      final result = await provider.updateQuestion(1, {'text': 'Updated Q'});
      expect(result, isTrue);
    });

    test('deleteQuestion returns true and refreshes on success', () async {
      int getCalls = 0;
      mockApi.onDelete = (endpoint) async {
        return {'success': true};
      };
      mockApi.onGet = (endpoint) async {
        getCalls++;
        return {'questions': [], 'total': 0};
      };

      final result = await provider.deleteQuestion(1);
      expect(result, isTrue);
      await Future.delayed(Duration(milliseconds: 10));
      expect(getCalls, 1);
    });
  });

  group('AdminQuestionProvider Bulk & Batch', () {
    test('bulkActionQuestions returns true and refreshes', () async {
      int getCalls = 0;
      mockApi.onPost = (endpoint, data) async {
        expect(data['action'], 'delete');
        expect(data['ids'], [1, 2]);
        return {'success': true};
      };
      mockApi.onGet = (endpoint) async {
        getCalls++;
        return {'questions': [], 'total': 0};
      };

      final result =
          await provider.bulkActionQuestions(action: 'delete', ids: [1, 2]);
      expect(result, isTrue);
      await Future.delayed(Duration(milliseconds: 10));
      expect(getCalls, 1);
    });

    test('uploadQuestionsBatch returns result and refreshes', () async {
      int getCalls = 0;
      mockApi.onPostMultipart = (endpoint,
          {required bytes, required filename, String? fieldName}) async {
        return {'success': true, 'imported': 5};
      };
      mockApi.onGet = (endpoint) async {
        getCalls++;
        return {'questions': [], 'total': 0};
      };

      final result =
          await provider.uploadQuestionsBatch([1, 2, 3], 'test.xlsx');
      expect(result?['imported'], 5);
      await Future.delayed(Duration(milliseconds: 10));
      expect(getCalls, 1);
    });

    test('downloadQuestionsTemplate works', () async {
      mockApi.onGetBytes = (endpoint) async {
        return <int>[1, 2, 3];
      };
      bool downloaded = false;
      mockDownloadHelper.onDownload = (bytes, filename, mimeType) async {
        downloaded = true;
        expect(bytes, [1, 2, 3]);
        expect(filename, 'QUESTION_TEMPLATE.xlsx');
      };

      await provider.downloadQuestionsTemplate();
      expect(downloaded, isTrue);
    });
  });

  group('AdminQuestionProvider Wall of Pain', () {
    test('fetchWallOfPain updates state', () async {
      mockApi.onGet = (endpoint) async {
        return {
          'failedQuestions': [
            {'id': 1}
          ],
          'difficultTopics': [
            {'id': 2}
          ]
        };
      };

      await provider.fetchWallOfPain();

      expect(provider.wallOfPain['failedQuestions'].length, 1);
      expect(provider.wallOfPain['difficultTopics'].length, 1);
    });
  });

  group('AdminQuestionProvider ECG', () {
    test('fetchECGCases updates state', () async {
      mockApi.onGet = (endpoint) async {
        return <Map<String, dynamic>>[
          {
            'id': 1,
            'diagnosis_id': 1,
            'image_url': 'url',
            'difficulty': 'beginner',
            'findings_json': <String, dynamic>{}
          }
        ];
      };

      await provider.fetchECGCases();

      expect(provider.ecgCases.length, 1);
      expect(provider.ecgCases.first.id, 1);
    });

    test('fetchECGDiagnoses updates state', () async {
      mockApi.onGet = (endpoint) async {
        return <Map<String, dynamic>>[
          {
            'id': 1,
            'code': 'AF',
            'name_en': 'Atrial Fibrillation',
            'name_hu': 'PFI'
          }
        ];
      };

      await provider.fetchECGDiagnoses();

      expect(provider.ecgDiagnoses.length, 1);
      expect(provider.ecgDiagnoses.first.code, 'AF');
    });

    test('createECGCase returns true', () async {
      mockApi.onPost = (endpoint, data) async {
        return {'success': true};
      };
      final result = await provider.createECGCase({'test': 'data'});
      expect(result, isTrue);
    });

    test('updateECGCase returns true', () async {
      mockApi.onPut = (endpoint, data) async {
        return {'success': true};
      };
      final result = await provider.updateECGCase(1, {'test': 'data'});
      expect(result, isTrue);
    });

    test('deleteECGCase returns true', () async {
      mockApi.onDelete = (endpoint) async {
        return {'success': true};
      };
      final result = await provider.deleteECGCase(1);
      expect(result, isTrue);
    });
  });

  group('AdminQuestionProvider resetState', () {
    test('resetState clears data', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint.contains('wall_of_pain')) {
          return {
            'failedQuestions': [
              {'id': 1}
            ],
            'difficultTopics': [
              {'id': 2}
            ]
          };
        }
        return {
          'questions': [
            {
              'id': 1,
              'text': 'Q1',
              'options': [],
              'correct_answer': 'A',
              'topic_id': 1,
              'bloom_level': 1,
            }
          ],
          'total': 1,
        };
      };

      await provider.fetchAdminQuestions();
      await provider.fetchWallOfPain();

      expect(provider.adminQuestions.isNotEmpty, isTrue);

      provider.resetState();

      expect(provider.adminQuestions, isEmpty);
      expect(provider.adminTotalQuestions, 0);
      expect(provider.wallOfPain['failedQuestions'], isEmpty);
      expect(provider.wallOfPain['difficultTopics'], isEmpty);
      expect(provider.ecgCases, isEmpty);
      expect(provider.ecgDiagnoses, isEmpty);
      expect(provider.isLoading, isFalse);
    });
  });
}
