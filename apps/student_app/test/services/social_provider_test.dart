import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:provider/provider.dart';
import 'package:arbor_med/services/social_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/shop_provider.dart';
import 'package:arbor_med/models/user.dart';
import 'package:arbor_med/core/api_endpoints.dart';

// Mock ApiService
class MockApiService extends Mock implements ApiService {
  @override
  Future<dynamic> get(String? endpoint) async {
    return super.noSuchMethod(
      Invocation.method(#get, [endpoint]),
      returnValue: Future.value({}),
    );
  }

  @override
  Future<dynamic> post(String? endpoint, Map<String, dynamic>? data) async {
    return super.noSuchMethod(
      Invocation.method(#post, [endpoint, data]),
      returnValue: Future.value({}),
    );
  }

  @override
  Future<dynamic> put(String? endpoint, Map<String, dynamic>? data) async {
    return super.noSuchMethod(
      Invocation.method(#put, [endpoint, data]),
      returnValue: Future.value({}),
    );
  }

  @override
  Future<dynamic> delete(String? endpoint) async {
    return super.noSuchMethod(
      Invocation.method(#delete, [endpoint]),
      returnValue: Future.value({}),
    );
  }
}

// Mock ShopProvider
class MockShopProvider extends Mock implements ShopProvider {
  @override
  Future<void> fetchRemoteInventory(int? targetUserId) async {
    super.noSuchMethod(
      Invocation.method(#fetchRemoteInventory, [targetUserId]),
      returnValue: Future<void>.value(),
    );
  }

  @override
  void clearVisitedInventory() {
    super.noSuchMethod(
      Invocation.method(#clearVisitedInventory, []),
      returnValueForMissingStub: null,
    );
  }
}

void main() {
  late MockApiService mockApiService;
  late MockShopProvider mockShopProvider;
  late SocialProvider socialProvider;

  final Map<String, dynamic> sampleNetworkResponse = {
    'colleagues': [
      {'id': 1, 'username': 'doctor1', 'display_name': 'Dr. One', 'role': 'doctor'},
      {'id': 2, 'username': 'doctor2', 'display_name': 'Dr. Two', 'role': 'doctor'}
    ],
    'pending': [
      {'id': 3, 'username': 'student1', 'display_name': 'Student One', 'role': 'student'}
    ]
  };

  final List<dynamic> sampleSearchResponse = [
    {'id': 4, 'username': 'nurse1', 'display_name': 'Nurse One', 'role': 'nurse'}
  ];

  final User sampleUser = User(id: 5, role: 'student', username: 'visited_user', coins: 0, xp: 0, level: 1, streakCount: 0);

  setUp(() {
    mockApiService = MockApiService();
    mockShopProvider = MockShopProvider();
    socialProvider = SocialProvider(apiService: mockApiService);
  });

  group('SocialProvider - Initial State & resetState', () {
    test('Initial state is correct', () {
      expect(socialProvider.colleagues, isEmpty);
      expect(socialProvider.pendingRequests, isEmpty);
      expect(socialProvider.visitedUser, isNull);
      expect(socialProvider.isLoading, isFalse);
      expect(socialProvider.isVisiting, isFalse);
    });

    test('resetState clears all data', () async {
      when(mockApiService.get(ApiEndpoints.socialNetwork)).thenAnswer((_) async => sampleNetworkResponse);
      await socialProvider.fetchNetwork();
      expect(socialProvider.colleagues.length, 2);
      expect(socialProvider.pendingRequests.length, 1);

      socialProvider.resetState();

      expect(socialProvider.colleagues, isEmpty);
      expect(socialProvider.pendingRequests, isEmpty);
      expect(socialProvider.visitedUser, isNull);
      expect(socialProvider.isLoading, isFalse);
    });
  });

  group('SocialProvider - Network Operations', () {
    test('fetchNetwork updates colleagues and pendingRequests', () async {
      when(mockApiService.get(ApiEndpoints.socialNetwork)).thenAnswer((_) async => sampleNetworkResponse);

      final future = socialProvider.fetchNetwork();
      expect(socialProvider.isLoading, isTrue);
      await future;

      expect(socialProvider.isLoading, isFalse);
      expect(socialProvider.colleagues.length, 2);
      expect(socialProvider.colleagues.first.id, 1);
      expect(socialProvider.pendingRequests.length, 1);
      expect(socialProvider.pendingRequests.first.id, 3);
    });

    test('fetchNetwork handles API errors gracefully', () async {
      when(mockApiService.get(ApiEndpoints.socialNetwork)).thenThrow(Exception('API Error'));

      await socialProvider.fetchNetwork();

      expect(socialProvider.isLoading, isFalse);
      expect(socialProvider.colleagues, isEmpty);
    });

    test('searchUsers returns expected results', () async {
      when(mockApiService.get('${ApiEndpoints.socialSearch}?query=nurse')).thenAnswer((_) async => sampleSearchResponse);

      final results = await socialProvider.searchUsers('nurse');

      expect(results.length, 1);
      expect(results.first.id, 4);
    });

    test('searchUsers handles errors gracefully', () async {
      when(mockApiService.get('${ApiEndpoints.socialSearch}?query=nurse')).thenThrow(Exception('API Error'));

      final results = await socialProvider.searchUsers('nurse');

      expect(results, isEmpty);
    });

    test('sendRequest posts to API', () async {
      when(mockApiService.post(ApiEndpoints.socialRequest, argThat(equals({'receiverId': 2})))).thenAnswer((_) async => {});

      await socialProvider.sendRequest(2);

      verify(mockApiService.post(ApiEndpoints.socialRequest, argThat(equals({'receiverId': 2})))).called(1);
    });

    test('respondToRequest puts to API and refetches network', () async {
      when(mockApiService.put(ApiEndpoints.socialRequest, argThat(equals({'requesterId': 3, 'action': 'accept'})))).thenAnswer((_) async => {});
      when(mockApiService.get(ApiEndpoints.socialNetwork)).thenAnswer((_) async => sampleNetworkResponse);

      await socialProvider.respondToRequest(3, 'accept');

      verify(mockApiService.put(ApiEndpoints.socialRequest, argThat(equals({'requesterId': 3, 'action': 'accept'})))).called(1);
      verify(mockApiService.get(ApiEndpoints.socialNetwork)).called(1);
    });

    test('unfriend deletes from API and refetches network', () async {
      when(mockApiService.delete('${ApiEndpoints.socialColleague}/1')).thenAnswer((_) async => {});
      when(mockApiService.get(ApiEndpoints.socialNetwork)).thenAnswer((_) async => sampleNetworkResponse);

      await socialProvider.unfriend(1);

      verify(mockApiService.delete('${ApiEndpoints.socialColleague}/1')).called(1);
      verify(mockApiService.get(ApiEndpoints.socialNetwork)).called(1);
    });

    test('likeRoom posts to API', () async {
      when(mockApiService.post(ApiEndpoints.socialLike, argThat(equals({'targetUserId': 1})))).thenAnswer((_) async => {});

      await socialProvider.likeRoom(1);

      verify(mockApiService.post(ApiEndpoints.socialLike, argThat(equals({'targetUserId': 1})))).called(1);
    });

    test('leaveNote posts to API', () async {
      when(mockApiService.post(ApiEndpoints.socialNote, argThat(equals({'targetUserId': 1, 'note': 'Great room!'})))).thenAnswer((_) async => {});

      await socialProvider.leaveNote(1, 'Great room!');

      verify(mockApiService.post(ApiEndpoints.socialNote, argThat(equals({'targetUserId': 1, 'note': 'Great room!'})))).called(1);
    });

    test('getNotes fetches from API', () async {
      final sampleNotes = [{'id': 1, 'content': 'Nice'}];
      when(mockApiService.get('/social/notes/1')).thenAnswer((_) async => sampleNotes);

      final results = await socialProvider.getNotes(1);

      expect(results, sampleNotes);
    });
  });

  group('SocialProvider - Visiting Logic', () {
    testWidgets('startVisiting sets visitedUser and fetches remote inventory', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<SocialProvider>.value(value: socialProvider),
                ChangeNotifierProvider<ShopProvider>.value(value: mockShopProvider),
              ],
              child: Builder(
                builder: (BuildContext context) {
                  return ElevatedButton(
                    onPressed: () {
                      socialProvider.startVisiting(sampleUser, context);
                    },
                    child: const Text('Visit'),
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(ElevatedButton));

      expect(socialProvider.visitedUser, sampleUser);
      expect(socialProvider.isVisiting, isTrue);
      expect(socialProvider.getVisitingDoctor(), sampleUser);
      verify(mockShopProvider.fetchRemoteInventory(sampleUser.id)).called(1);
    });

    testWidgets('stopVisiting clears visitedUser and local inventory', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MultiProvider(
              providers: [
                ChangeNotifierProvider<SocialProvider>.value(value: socialProvider),
                ChangeNotifierProvider<ShopProvider>.value(value: mockShopProvider),
              ],
              child: Builder(
                builder: (BuildContext context) {
                  return Column(
                    mainAxisSize: MainAxisSize.min, // Fix RenderFlex overflow
                    children: [
                      ElevatedButton(
                        key: const Key('start'),
                        onPressed: () {
                          socialProvider.startVisiting(sampleUser, context);
                        },
                        child: const Text('Visit'),
                      ),
                      ElevatedButton(
                        key: const Key('stop'),
                        onPressed: () {
                          socialProvider.stopVisiting(context);
                        },
                        child: const Text('Stop'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const Key('start')));
      expect(socialProvider.isVisiting, isTrue);

      await tester.tap(find.byKey(const Key('stop')));

      expect(socialProvider.visitedUser, isNull);
      expect(socialProvider.isVisiting, isFalse);
      verify(mockShopProvider.clearVisitedInventory()).called(1);
    });
  });
}
