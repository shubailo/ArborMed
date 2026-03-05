import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:arbor_med/services/topic_provider.dart';
import 'package:arbor_med/services/auth_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/core/api_endpoints.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {
  @override
  Future<dynamic> get(String? endpoint, {Map<String, String>? headers}) async {
    return super.noSuchMethod(
      Invocation.method(#get, [endpoint], {#headers: headers}),
      returnValue: Future.value([]),
    );
  }

  @override
  Future<dynamic> post(String? endpoint, Map<String, dynamic>? data, {Map<String, String>? headers}) async {
    return super.noSuchMethod(
      Invocation.method(#post, [endpoint, data], {#headers: headers}),
      returnValue: Future.value({}),
    );
  }

  @override
  Future<dynamic> put(String? endpoint, Map<String, dynamic>? data, {Map<String, String>? headers}) async {
    return super.noSuchMethod(
      Invocation.method(#put, [endpoint, data], {#headers: headers}),
      returnValue: Future.value({}),
    );
  }

  @override
  Future<dynamic> delete(String? endpoint, {Map<String, String>? headers}) async {
    return super.noSuchMethod(
      Invocation.method(#delete, [endpoint], {#headers: headers}),
      returnValue: Future.value({}),
    );
  }
}

// Mock AuthProvider
class MockAuthProvider extends Mock implements AuthProvider {
  final MockApiService _apiService = MockApiService();

  @override
  ApiService get apiService => _apiService;
}

void main() {
  late MockApiService mockApiService;
  late MockAuthProvider mockAuthProvider;
  late TopicProvider topicProvider;

  setUp(() {
    mockAuthProvider = MockAuthProvider();
    mockApiService = mockAuthProvider.apiService as MockApiService;
    topicProvider = TopicProvider(mockAuthProvider);
  });

  group('TopicProvider', () {
    test('initial state is empty', () {
      expect(topicProvider.topics, isEmpty);
    });

    test('resetState clears topics', () async {
      when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => [
        {'id': 1, 'name_en': 'Topic 1', 'name_hu': 'Téma 1', 'parent_id': null}
      ]);
      await topicProvider.fetchTopics();
      expect(topicProvider.topics, isNotEmpty);

      topicProvider.resetState();

      expect(topicProvider.topics, isEmpty);
    });

    group('fetchTopics', () {
      test('updates topics on success', () async {
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => [
          {'id': 1, 'name_en': 'Topic 1', 'name_hu': 'Téma 1', 'parent_id': null},
          {'id': 2, 'name_en': 'Topic 2', 'name_hu': 'Téma 2', 'parent_id': 1}
        ]);

        await topicProvider.fetchTopics();

        expect(topicProvider.topics.length, 2);
        expect(topicProvider.topics[0]['name_en'], 'Topic 1');
        expect(topicProvider.topics[1]['parent_id'], 1);
      });

      test('handles non-list response gracefully', () async {
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => {'error': 'not a list'});

        await topicProvider.fetchTopics();

        expect(topicProvider.topics, isEmpty);
      });

      test('handles errors gracefully', () async {
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenThrow(Exception('API Error'));

        await topicProvider.fetchTopics();

        expect(topicProvider.topics, isEmpty);
      });
    });

    group('createTopic', () {
      test('returns true and fetches topics on success', () async {
        when(mockApiService.post(ApiEndpoints.quizAdminTopics, any)).thenAnswer((_) async => {'id': 1});
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => [
          {'id': 1, 'name_en': 'New Topic', 'name_hu': 'Új Téma', 'parent_id': 2}
        ]);

        final result = await topicProvider.createTopic('New Topic', 'Új Téma', 2);

        expect(result, isTrue);
        expect(topicProvider.topics.length, 1);
        expect(topicProvider.topics[0]['name_en'], 'New Topic');

        verify(mockApiService.post(ApiEndpoints.quizAdminTopics, {
          'name_en': 'New Topic',
          'name_hu': 'Új Téma',
          'parent_id': 2,
        })).called(1);
        verify(mockApiService.get(ApiEndpoints.quizTopics)).called(1);
      });

      test('returns false on error', () async {
        when(mockApiService.post(ApiEndpoints.quizAdminTopics, any)).thenThrow(Exception('API Error'));

        final result = await topicProvider.createTopic('New Topic', 'Új Téma', 2);

        expect(result, isFalse);
        verify(mockApiService.post(ApiEndpoints.quizAdminTopics, any)).called(1);
        verifyNever(mockApiService.get(ApiEndpoints.quizTopics));
      });
    });

    group('deleteTopic', () {
      test('returns null and fetches topics on success', () async {
        when(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1')).thenAnswer((_) async => {});
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => []);

        final result = await topicProvider.deleteTopic(1);

        expect(result, isNull);
        verify(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1')).called(1);
        verify(mockApiService.get(ApiEndpoints.quizTopics)).called(1);
      });

      test('appends force=true query param when force is true', () async {
        when(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1?force=true')).thenAnswer((_) async => {});
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => []);

        final result = await topicProvider.deleteTopic(1, force: true);

        expect(result, isNull);
        verify(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1?force=true')).called(1);
        verify(mockApiService.get(ApiEndpoints.quizTopics)).called(1);
      });

      test('returns parsed error message on API Error', () async {
        when(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1')).thenThrow(Exception('API Error: Topic has children'));

        final result = await topicProvider.deleteTopic(1);

        expect(result, 'Topic has children');
        verify(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1')).called(1);
        verifyNever(mockApiService.get(ApiEndpoints.quizTopics));
      });

      test('returns "Network error" on generic error', () async {
        when(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1')).thenThrow(Exception('Connection refused'));

        final result = await topicProvider.deleteTopic(1);

        expect(result, 'Network error');
        verify(mockApiService.delete('${ApiEndpoints.quizAdminTopics}/1')).called(1);
        verifyNever(mockApiService.get(ApiEndpoints.quizTopics));
      });
    });

    group('updateTopic', () {
      setUp(() async {
        // Pre-populate topics for optimistic update test
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => [
          {'id': 1, 'name_en': 'Old Topic', 'name_hu': 'Régi Téma', 'parent_id': null}
        ]);
        await topicProvider.fetchTopics();
        clearInteractions(mockApiService);
      });

      test('optimistically updates topics, returns null, and fetches topics in background on success', () async {
        when(mockApiService.put('${ApiEndpoints.quizAdminTopics}/1', any)).thenAnswer((_) async => {});
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => [
          {'id': 1, 'name_en': 'Updated Topic', 'name_hu': 'Frissített Téma', 'parent_id': null}
        ]);

        bool listenerCalled = false;
        topicProvider.addListener(() {
          listenerCalled = true;
        });

        final result = await topicProvider.updateTopic(1, 'Updated Topic', 'Frissített Téma');

        expect(result, isNull);
        expect(listenerCalled, isTrue); // Should be called from optimistic update

        // Check optimistic update before the background fetch completes (it should be immediate)
        expect(topicProvider.topics[0]['name_en'], 'Updated Topic');
        expect(topicProvider.topics[0]['name_hu'], 'Frissített Téma');

        verify(mockApiService.put('${ApiEndpoints.quizAdminTopics}/1', {
          'name_en': 'Updated Topic',
          'name_hu': 'Frissített Téma',
        })).called(1);
        verify(mockApiService.get(ApiEndpoints.quizTopics)).called(1); // The background refresh
      });

      test('handles updating non-existent topic gracefully', () async {
        when(mockApiService.put('${ApiEndpoints.quizAdminTopics}/999', any)).thenAnswer((_) async => {});
        when(mockApiService.get(ApiEndpoints.quizTopics)).thenAnswer((_) async => [
          {'id': 1, 'name_en': 'Old Topic', 'name_hu': 'Régi Téma', 'parent_id': null} // still same data
        ]);

        final result = await topicProvider.updateTopic(999, 'Updated Topic', 'Frissített Téma');

        expect(result, isNull);
        expect(topicProvider.topics[0]['name_en'], 'Old Topic'); // no optimistic update happened

        verify(mockApiService.put('${ApiEndpoints.quizAdminTopics}/999', any)).called(1);
        verify(mockApiService.get(ApiEndpoints.quizTopics)).called(1);
      });

      test('returns parsed error message on API Error', () async {
        when(mockApiService.put('${ApiEndpoints.quizAdminTopics}/1', any)).thenThrow(Exception('API Error: Invalid data'));

        final result = await topicProvider.updateTopic(1, 'Updated Topic', 'Frissített Téma');

        expect(result, 'Invalid data');
        expect(topicProvider.topics[0]['name_en'], 'Old Topic'); // Optimistic update did NOT happen

        verify(mockApiService.put('${ApiEndpoints.quizAdminTopics}/1', any)).called(1);
        verifyNever(mockApiService.get(ApiEndpoints.quizTopics)); // No background refresh on error
      });

      test('returns "Network error" on generic error', () async {
        when(mockApiService.put('${ApiEndpoints.quizAdminTopics}/1', any)).thenThrow(Exception('Connection refused'));

        final result = await topicProvider.updateTopic(1, 'Updated Topic', 'Frissített Téma');

        expect(result, 'Network error');
        expect(topicProvider.topics[0]['name_en'], 'Old Topic'); // Optimistic update did NOT happen

        verify(mockApiService.put('${ApiEndpoints.quizAdminTopics}/1', any)).called(1);
        verifyNever(mockApiService.get(ApiEndpoints.quizTopics)); // No background refresh on error
      });
    });
  });
}
