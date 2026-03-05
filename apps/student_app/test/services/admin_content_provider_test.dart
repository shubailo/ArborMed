import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:image_picker/image_picker.dart';
import 'package:arbor_med/services/admin_content_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/models/quote.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {
  Future<dynamic> Function(String endpoint)? onGet;
  Future<dynamic> Function(String endpoint, Map<String, dynamic> data)? onPost;
  Future<dynamic> Function(String endpoint, Map<String, dynamic> data)? onPut;
  Future<dynamic> Function(String endpoint)? onDelete;

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
}

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  final MockApiService _apiService = MockApiService();

  @override
  ApiService get apiService => _apiService;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late AdminContentProvider provider;
  late MockAuthProvider mockAuth;
  late MockApiService mockApi;

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockAuth = MockAuthProvider();
    mockApi = mockAuth.apiService as MockApiService;
    provider = AdminContentProvider(mockAuth);
  });

  group('AdminContentProvider Initial State', () {
    test('initial values are empty or false', () {
      expect(provider.isLoading, isFalse);
      expect(provider.adminQuotes, isEmpty);
      expect(provider.currentQuote, isNull);
      expect(provider.uploadedIcons, isEmpty);
    });
  });

  group('AdminContentProvider Quote CRUD', () {
    test('fetchAdminQuotes updates adminQuotes on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizAdminQuotes) {
          return [
            {
              'id': 1,
              'text_en': 'Test En',
              'text_hu': 'Test Hu',
              'author': 'Author',
              'title_en': 'Title En',
              'title_hu': 'Title Hu',
              'icon_name': 'icon1',
              'custom_icon_url': 'url1',
            }
          ];
        }
        return null;
      };

      expect(provider.isLoading, isFalse);

      final future = provider.fetchAdminQuotes();

      // Should be loading immediately after call
      expect(provider.isLoading, isTrue);

      await future;

      expect(provider.isLoading, isFalse);
      expect(provider.adminQuotes.length, 1);
      expect(provider.adminQuotes[0].id, 1);
      expect(provider.adminQuotes[0].textEn, 'Test En');
      expect(provider.adminQuotes[0].author, 'Author');
    });

    test('fetchAdminQuotes handles errors gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchAdminQuotes();

      expect(provider.isLoading, isFalse);
      expect(provider.adminQuotes, isEmpty);
    });

    test('createQuote sends correct data and fetches quotes', () async {
      bool postCalled = false;
      bool getCalled = false;

      mockApi.onPost = (endpoint, data) async {
        if (endpoint == ApiEndpoints.quizAdminQuotes) {
          postCalled = true;
          expect(data['text_en'], 'New En');
          expect(data['text_hu'], 'New Hu');
          expect(data['author'], 'New Auth');
          return {'id': 2};
        }
        return null;
      };

      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizAdminQuotes) {
          getCalled = true;
          return [];
        }
        return null;
      };

      final result = await provider.createQuote('New En', 'New Hu', 'New Auth');

      expect(result, isTrue);
      expect(postCalled, isTrue);
      expect(getCalled, isTrue);
    });

    test('createQuote returns false on error', () async {
      mockApi.onPost = (endpoint, data) async {
        throw Exception('API Error');
      };

      final result = await provider.createQuote('New En', 'New Hu', 'New Auth');

      expect(result, isFalse);
    });

    test('updateQuote sends correct data and fetches quotes', () async {
      bool putCalled = false;
      bool getCalled = false;

      mockApi.onPut = (endpoint, data) async {
        if (endpoint == '${ApiEndpoints.quizAdminQuotes}/1') {
          putCalled = true;
          expect(data['text_en'], 'Upd En');
          return {'id': 1};
        }
        return null;
      };

      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizAdminQuotes) {
          getCalled = true;
          return [];
        }
        return null;
      };

      final result = await provider.updateQuote(1, 'Upd En', 'Upd Hu', 'Upd Auth');

      expect(result, isTrue);
      expect(putCalled, isTrue);
      expect(getCalled, isTrue);
    });

    test('updateQuote returns false on error', () async {
      mockApi.onPut = (endpoint, data) async {
        throw Exception('API Error');
      };

      final result = await provider.updateQuote(1, 'Upd En', 'Upd Hu', 'Upd Auth');

      expect(result, isFalse);
    });

    test('deleteQuote sends delete request and fetches quotes', () async {
      bool deleteCalled = false;
      bool getCalled = false;

      mockApi.onDelete = (endpoint) async {
        if (endpoint == '${ApiEndpoints.quizAdminQuotes}/1') {
          deleteCalled = true;
          return {'success': true};
        }
        return null;
      };

      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizAdminQuotes) {
          getCalled = true;
          return [];
        }
        return null;
      };

      final result = await provider.deleteQuote(1);

      expect(result, isTrue);
      expect(deleteCalled, isTrue);
      expect(getCalled, isTrue);
    });

    test('deleteQuote returns false on error', () async {
      mockApi.onDelete = (endpoint) async {
        throw Exception('API Error');
      };

      final result = await provider.deleteQuote(1);

      expect(result, isFalse);
    });

    test('fetchCurrentQuote updates currentQuote on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizSingleQuote) {
          return {
            'id': 10,
            'text_en': 'Single En',
            'text_hu': 'Single Hu',
            'author': 'Single Auth',
          };
        }
        return null;
      };

      await provider.fetchCurrentQuote();

      expect(provider.currentQuote, isNotNull);
      expect(provider.currentQuote!.id, 10);
      expect(provider.currentQuote!.textEn, 'Single En');
    });

    test('fetchCurrentQuote handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchCurrentQuote();

      expect(provider.currentQuote, isNull);
    });
  });

  group('AdminContentProvider Image & Icon Management', () {
    test('fetchUploadedIcons updates uploadedIcons on success', () async {
      mockApi.onGet = (endpoint) async {
        if (endpoint == '${ApiEndpoints.apiUpload}?folder=icons') {
          return {
            'images': ['http://example.com/icon1.png', 'http://example.com/icon2.png']
          };
        }
        return null;
      };

      await provider.fetchUploadedIcons();

      expect(provider.uploadedIcons.length, 2);
      expect(provider.uploadedIcons[0], 'http://example.com/icon1.png');
    });

    test('fetchUploadedIcons handles error gracefully', () async {
      mockApi.onGet = (endpoint) async {
        throw Exception('API Error');
      };

      await provider.fetchUploadedIcons();

      expect(provider.uploadedIcons, isEmpty);
    });

    test('deleteUploadedIcon deletes from API and removes from list', () async {
      // Setup initial state
      mockApi.onGet = (endpoint) async {
        if (endpoint == '${ApiEndpoints.apiUpload}?folder=icons') {
          return {
            'images': ['http://example.com/icon1.png', 'http://example.com/icon2.png']
          };
        }
        return null;
      };
      await provider.fetchUploadedIcons();
      expect(provider.uploadedIcons.length, 2);

      bool deleteCalled = false;
      mockApi.onDelete = (endpoint) async {
        if (endpoint == '${ApiEndpoints.apiUpload}/icon1.png') {
          deleteCalled = true;
          return {'success': true};
        }
        return null;
      };

      final result = await provider.deleteUploadedIcon('http://example.com/icon1.png');

      expect(result, isTrue);
      expect(deleteCalled, isTrue);
      expect(provider.uploadedIcons.length, 1);
      expect(provider.uploadedIcons.contains('http://example.com/icon1.png'), isFalse);
    });

    test('deleteUploadedIcon returns false on error and leaves list intact', () async {
      // Setup initial state
      mockApi.onGet = (endpoint) async {
        if (endpoint == '${ApiEndpoints.apiUpload}?folder=icons') {
          return {
            'images': ['http://example.com/icon1.png']
          };
        }
        return null;
      };
      await provider.fetchUploadedIcons();
      expect(provider.uploadedIcons.length, 1);

      mockApi.onDelete = (endpoint) async {
        throw Exception('API Error');
      };

      final result = await provider.deleteUploadedIcon('http://example.com/icon1.png');

      expect(result, isFalse);
      expect(provider.uploadedIcons.length, 1);
    });
  });

  group('AdminContentProvider Translation', () {
    test('translateText returns translated string on success', () async {
      mockApi.onPost = (endpoint, data) async {
        if (endpoint == ApiEndpoints.quizTranslate) {
          expect(data['text'], 'Hello');
          expect(data['sourceLang'], 'en');
          expect(data['targetLang'], 'hu');
          return {'translatedText': 'Szia'};
        }
        return null;
      };

      final result = await provider.translateText('Hello', 'en', 'hu');

      expect(result, 'Szia');
    });

    test('translateText returns null on error', () async {
      mockApi.onPost = (endpoint, data) async {
        throw Exception('API Error');
      };

      final result = await provider.translateText('Hello', 'en', 'hu');

      expect(result, isNull);
    });
  });

  group('AdminContentProvider resetState', () {
    test('resetState clears all lists and current quote', () async {
      // Setup some state
      mockApi.onGet = (endpoint) async {
        if (endpoint == ApiEndpoints.quizAdminQuotes) {
          return [
            {
              'id': 1,
              'text_en': 'Test',
            }
          ];
        } else if (endpoint == ApiEndpoints.quizSingleQuote) {
          return {
            'id': 10,
            'text_en': 'Single',
          };
        } else if (endpoint == '${ApiEndpoints.apiUpload}?folder=icons') {
          return {
            'images': ['url1']
          };
        }
        return null;
      };

      await provider.fetchAdminQuotes();
      await provider.fetchCurrentQuote();
      await provider.fetchUploadedIcons();

      expect(provider.adminQuotes, isNotEmpty);
      expect(provider.currentQuote, isNotNull);
      expect(provider.uploadedIcons, isNotEmpty);

      provider.resetState();

      expect(provider.isLoading, isFalse);
      expect(provider.adminQuotes, isEmpty);
      expect(provider.currentQuote, isNull);
      expect(provider.uploadedIcons, isEmpty);
    });
  });
}
