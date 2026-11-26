import 'package:arbor_med/services/duel_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/services/duel_provider.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

class _Socket extends Fake implements io.Socket {
  final handlers = <String, dynamic Function(dynamic)>{};
  final sent = <MapEntry<String, dynamic>>[];
  int connections = 0;
  @override
  bool connected = false;
  @override
  String? get id => 'fixture';
  @override
  dynamic auth;
  @override
  Function() on(String event, dynamic Function(dynamic) handler) {
    handlers[event] = handler;
    return () => handlers.remove(event);
  }

  @override
  io.Socket connect() {
    connections++;
    return this;
  }

  void ready() {
    connected = true;
    handlers['connect']!(null);
  }

  @override
  void emit(String event, [dynamic data]) => sent.add(MapEntry(event, data));
  @override
  void dispose() => handlers.clear();
}

void main() {
  late _Socket wire;
  late DuelSocketService service;
  setUp(() {
    wire = _Socket();
    service = DuelSocketService('http://localhost', 'fixture',
        openSocket: (_, options) => wire);
  });
  tearDown(() => service.dispose());
  test('out-of-match scores and clocks cannot change the current duel', () async {
    wire.ready();
    final api = ApiService()..setToken('fixture', userId: 7);
    final duel = DuelProvider(api, openSocket: (_, token) => service)..setAccount(7);
    addTearDown(duel.dispose);
    duel.joinQueue(10);
    wire.handlers['match_found']!({
      'matchId': 'new', 'role': 'p1',
      'questions': [{'id': 'q1', 'q': 'Q', 'options': ['A', 'B']}],
    });
    await Future<void>.delayed(Duration.zero);
    wire.handlers['score_update']!({'matchId': 'new', 'p1': 1, 'p2': 0});
    wire.handlers['time_sync']!({'matchId': 'new', 'time': 15});
    wire.handlers['score_update']!({'matchId': 'old', 'p1': 9, 'p2': 5});
    wire.handlers['time_sync']!({'matchId': 'old', 'time': 0});
    await Future<void>.delayed(Duration.zero);
    expect([duel.p1Score, duel.p2Score, duel.timeRemaining], [1, 0, 15]);
    wire.handlers['time_sync']!({'time': 9});
    await Future<void>.delayed(Duration.zero);
    expect(duel.timeRemaining, 9);
  });

  test('a disconnected or repeated tap cannot send or consume another answer', () async {
    wire.ready();
    final api = ApiService()..setToken('fixture', userId: 7);
    final duel = DuelProvider(api, openSocket: (_, token) => service)..setAccount(7);
    addTearDown(duel.dispose);
    duel.joinQueue(10);
    wire.handlers['match_found']!({
      'matchId': 'm', 'role': 'p1',
      'questions': [
        {'id': 'first', 'options': ['A','B']}, {'id': 'last', 'options': ['C','D']},
      ],
    });
    await Future<void>.delayed(Duration.zero);
    wire.connected = false;
    duel.submitAnswer('A');
    expect(duel.currentQuestionIndex, 0);
    wire.connected = true;
    duel.submitAnswer('A');
    duel.submitAnswer('C');
    duel.submitAnswer('D');
    expect(wire.sent.where((e) => e.key == 'submit_answer').map((e) => e.value['answer']), ['A', 'C']);
  });

  test('a handshake error omits raw transport diagnostics', () async {
    final failure = service.errorStream.first;
    wire.handlers['connect_error']!('private transport diagnostic');
    expect(await failure, isNot(contains('private transport diagnostic')));
  });

  test('a wager waits for connection, uses the current token and is sent once',
      () {
    service.joinQueue(10, 'fixture');
    expect(wire.sent, isEmpty);
    service.setToken('renewed');
    wire.ready();
    wire.ready();
    expect(wire.sent.map((e) => e.key), ['join_queue']);
    expect(wire.sent.single.value, {'wager': 10, 'token': 'renewed'});
  });
  test('leaving before a handshake prevents a later wager', () async {
    service.joinQueue(5, 'fixture');
    final left = service.queueLeftStream.first;
    service.leaveQueue();
    wire.ready();
    expect(wire.sent, isEmpty);
    expect(await left, {'refundedWager': 0});
  });
  test(
      'leaving the lobby cancels the wager on the transport before the socket connects',
      () async {
    final api = ApiService()..setToken('fixture', userId: 7);
    final provider = DuelProvider(api, openSocket: (_, token) => service)
      ..setAccount(7);
    provider.joinQueue(10);
    expect(await provider.leaveQueue(), isTrue);
    wire.ready();
    await Future<void>.delayed(Duration.zero);
    expect(wire.sent, isEmpty);
    expect(provider.state, DuelState.idle);
    provider.dispose();
  });
  test('a failed handshake drops the pending wager before a later connection',
      () async {
    service.joinQueue(5, 'fixture');
    final failure = service.errorStream.first;
    wire.handlers['connect_error']!('fixture offline');
    await failure;
    wire.ready();
    expect(wire.sent, isEmpty);
  });
  test('an unreadable socket event cannot interrupt the next valid update',
      () async {
    final time = service.timeSyncStream.first;
    final score = service.scoreUpdateStream.first;
    expect(() => wire.handlers['time_sync']!({'time': null}), returnsNormally);
    expect(() => wire.handlers['score_update']!([]), returnsNormally);
    expect(() => wire.handlers['error']!('temporary'), returnsNormally);
    wire.handlers['time_sync']!({'time': 17});
    wire.handlers['score_update']!({'p1': 2, 'p2': 1});
    expect(await time, {'time': 17});
    expect(await score, {'p1': 2, 'p2': 1});
  });
}
