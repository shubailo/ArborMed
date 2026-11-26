import 'dart:async';
import 'package:arbor_med/core/api_endpoints.dart';
import 'package:arbor_med/core/api_exceptions.dart';
import 'package:arbor_med/core/models/topic.dart';
import 'package:arbor_med/features/quiz/providers/topic_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'admin_question_provider_test.dart'
    show MockApiService, MockAuthProvider;

void main() {
  late MockAuthProvider auth;
  late MockApiService api;
  late TopicProvider provider;
  const root = {'id': 1, 'name_en': 'Root', 'parent_id': null, 'slug': 'root'};
  const leaf = {
    'id': '2',
    'parent_id': '1',
    'name': 'Legacy',
    'slug': 'leaf',
    'question_count': '12',
    'description': 'preserved'
  };
  setUp(() {
    auth = MockAuthProvider();
    api = auth.apiService as MockApiService;
    provider = TopicProvider(auth);
  });
  tearDown(() => provider.dispose());

  test('an empty catalog is distinguishable from a pending request', () async {
    final result = Completer<dynamic>();
    api.onGet = (_) => result.future;
    final read = provider.fetchTopics();
    expect(provider.loading, isTrue);
    result.complete([]);
    await read;
    expect(provider.topics, isEmpty);
    expect(provider.loading, isFalse);
    expect(provider.loadFailed, isFalse);
  });

  test(
      'a committed legacy acknowledgement still reloads and never repeats the POST',
      () async {
    var posts = 0;
    api.onPost = (_, __) async {
      posts++;
      return {'success': true};
    };
    api.onGet = (_) async => [root, leaf];
    await provider.createTopic('Legacy', '', 1);
    expect(posts, 1);
    expect(provider.topics.last['id'], 2);
  });

  test(
      'an inconsistent update receipt is replaced by the authoritative catalog',
      () async {
    api.onGet = (_) async => [root, leaf];
    await provider.fetchTopics();
    api.onPut = (_, __) async => {...root, 'name_en': 'Wrong receipt'};
    api.onGet = (_) async => throw const NetworkException();
    await provider.updateTopic(2, 'new', '');
    expect(provider.topics.first['name_en'], 'Root');
    expect(provider.topics.last['name_en'], 'Legacy');
    expect(provider.loadFailed, isTrue);
  });

  test(
      'catalog normalizes PostgreSQL integers and legacy names and preserves extra fields',
      () async {
    expect(provider.topics, isEmpty);
    api.onGet = (_) async => [root, leaf];
    await provider.fetchTopics();
    expect(provider.topics.last, containsPair('parent_id', 1));
    expect(provider.topics.last, containsPair('question_count', 12));
    expect(provider.topics.last, containsPair('name_en', 'Legacy'));
    expect(provider.topics.last, containsPair('description', 'preserved'));
    expect(() => provider.topics.last['id'] = 4, throwsUnsupportedError);
    for (final bad in [0, -1, '1.5', 'no', true, 2147483648]) {
      expect(() => Topic.fromJson({...root, 'id': bad}), throwsFormatException);
    }
    expect(() => Topic.fromJson({...leaf, 'question_count': '-1'}),
        throwsFormatException);
    expect(Topic.fromJson(root).questionCount, isNull);
  });

  test('a failed catalog keeps the last complete snapshot and retry recovers',
      () async {
    api.onGet = (_) async => [root];
    await provider.fetchTopics();
    for (final payload in [
      null,
      {'bad': true},
      [
        root,
        {'id': 'bad'}
      ]
    ]) {
      api.onGet = (_) async => payload;
      await provider.fetchTopics();
      expect(provider.loadFailed, isTrue);
      expect(provider.topics.single['id'], 1);
    }
    api.onGet = (_) async => [];
    await provider.fetchTopics();
    expect(provider.loadFailed, isFalse);
    expect(provider.topics, isEmpty);
  });

  test('a late GET cannot undo a committed rename even when its refresh fails',
      () async {
    api.onGet = (_) async => [leaf];
    await provider.fetchTopics();
    final old = Completer<dynamic>();
    api.onGet = (_) => old.future;
    final request = provider.fetchTopics();
    api.onPut = (path, fields) async {
      expect(path, '${ApiEndpoints.quizAdminTopics}/2');
      expect(fields, {'name_en': 'New', 'name_hu': 'Új'});
      return {...leaf, ...fields}..remove('question_count');
    };
    api.onGet = (_) async => throw const NetworkException();
    await provider.updateTopic(2, ' New ', 'Új');
    old.complete([leaf]);
    await request;
    expect(provider.topics.single['name_en'], 'New');
    expect(provider.topics.single['question_count'], 12);
    expect(provider.loadFailed, isTrue);
  });

  test(
      'create and delete reconcile committed rows when the subsequent GET fails',
      () async {
    api.onPost = (path, body) async {
      expect(path, ApiEndpoints.quizAdminTopics);
      expect(body, {'name_en': 'New', 'name_hu': 'Új', 'parent_id': 1});
      return {...leaf, 'name_en': 'New'};
    };
    api.onGet = (_) async => throw const NetworkException();
    await provider.createTopic('New', 'Új', 1);
    expect(provider.topics.single['id'], 2);
    api.onDelete = (path) async {
      expect(path, '${ApiEndpoints.quizAdminTopics}/2');
      return {};
    };
    expect(await provider.deleteTopic(2), isNull);
    expect(provider.topics, isEmpty);
  });

  test('write errors retain their HTTP meaning and do not refresh the catalog',
      () async {
    var reads = 0;
    api.onGet = (_) async {
      reads++;
      return [];
    };
    api.onPut = (_, __) async => throw const ForbiddenException();
    api.onPost =
        (_, __) async => throw const ConflictException(message: 'Duplicate');
    api.onDelete = (_) async => throw const ConflictException(
        message: 'Has children', body: 'ordinary conflict');
    await expectLater(
        provider.updateTopic(1, 'New', ''), throwsA(isA<ForbiddenException>()));
    await expectLater(
        provider.createTopic('New', '', 1), throwsA(isA<ConflictException>()));
    await expectLater(
        provider.deleteTopic(1), throwsA(isA<ConflictException>()));
    expect(reads, 0);
  });

  test('only a structured confirmation is eligible for a destructive follow-up',
      () async {
    api.onDelete = (_) async => throw const ConflictException(
        body:
            '{"code":"topic_questions_confirmation","count":2,"confirmation":"v1"}');
    final ask = await provider.deleteTopic(2);
    expect(ask!.count, 2);
    api.onGet = (_) async => [];
    api.onDelete = (path) async {
      expect(Uri.parse(path).queryParameters,
          {'force': 'true', 'confirmation': 'v1'});
      return {};
    };
    expect(await provider.deleteTopic(2, confirmation: ask.version), isNull);
  });

  test(
      'reset invalidates both pending reads and pending committed mutation callbacks',
      () async {
    final waiting = Completer<dynamic>(), write = Completer<dynamic>();
    var reads = 0;
    api.onGet = (_) {
      reads++;
      return waiting.future;
    };
    api.onPost = (_, __) => write.future;
    final read = provider.fetchTopics(),
        create = provider.createTopic('New', '', 1);
    provider.resetState();
    waiting.complete([root]);
    write.complete(leaf);
    await Future.wait([read, create]);
    expect(provider.topics, isEmpty);
    expect(provider.loading, isFalse);
    expect(reads, 1);
  });
}
