import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/duel_provider.dart';
import 'package:arbor_med/services/duel_socket_service.dart';

class _Socket extends Fake implements DuelSocketService {
  final connections = StreamController<bool>.broadcast();
  final matches = StreamController<Map<String, dynamic>>.broadcast();
  final receipts = StreamController<Map<String, dynamic>>.broadcast();
  final results = StreamController<Map<String, dynamic>>.broadcast();
  final departures = StreamController<Map<String, dynamic>>.broadcast();
  final opponent = StreamController<Map<String, dynamic>>.broadcast();
  final errors = StreamController<String>.broadcast();
  final queries = <String>[];
  int leaves = 0;
  @override
  bool get isConnected => true;
  @override
  Stream<bool> get connectionStream => connections.stream;
  @override
  Stream<Map<String, dynamic>> get matchFoundStream => matches.stream;
  @override
  Stream<Map<String, dynamic>> get receiptStream => receipts.stream;
  @override
  Stream<Map<String, dynamic>> get gameOverStream => results.stream;
  @override
  Stream<Map<String, dynamic>> get queueJoinedStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get queueLeftStream => departures.stream;
  @override
  Stream<Map<String, dynamic>> get scoreUpdateStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get timeSyncStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get opponentDisconnectedStream =>
      opponent.stream;
  @override
  Stream<String> get errorStream => errors.stream;
  @override
  void requestResult(String id, String? token) => queries.add(id);
  @override
  void joinQueue(int wager, String? token) {}
  @override
  void leaveQueue() {
    leaves++;
  }

  @override
  void dispose() {
    connections.close();
    matches.close();
    receipts.close();
    results.close();
    departures.close();
    opponent.close();
    errors.close();
  }
}

void main() {
  late _Socket socket;
  late DuelProvider duel;
  setUp(() {
    final api = ApiService()..setToken('fixture', userId: 1);
    socket = _Socket();
    duel = DuelProvider(api, openSocket: (url, token) => socket)..setAccount(1);
  });
  tearDown(() => duel.dispose());
  final match = {
    'matchId': 'm',
    'role': 'p1',
    'questions': <Map<String, dynamic>>[
      {
        'id': 1,
        'q': 'Q',
        'options': ['A', 'B'],
      },
    ],
  };
  final settled = {
    'matchId': 'm',
    'winner': 'p1',
    'potWon': 20,
    'myScore': 2,
    'opScore': 1,
  };
  Future<void> playing(WidgetTester tester) async {
    duel.joinQueue(10);
    socket.matches.add(match);
    await tester.pump();
    expect(duel.state, DuelState.playing);
  }

  testWidgets(
    'old queue and game events cannot overwrite the next duel or the final receipt',
    (tester) async {
      await playing(tester);
      socket.departures.add({'refundedWager': 0});
      await tester.pump();
      expect(duel.state, DuelState.playing);
      socket.results.add(settled);
      await tester.pump();
      socket.errors.add('late transport notice');
      await tester.pump();
      expect(duel.state, DuelState.finished);
      duel.joinQueue(5);
      socket.results.add(settled);
      await tester.pump();
      expect(duel.state, DuelState.searching);
      expect(duel.matchId, isNull);
      expect(duel.potWon, 0);
      duel.reset();
      socket.matches.add(match);
      await tester.pump();
      expect(duel.state, DuelState.idle);
    },
  );
  testWidgets('a closed receipt requires a valid wager and payout', (
    tester,
  ) async {
    await playing(tester);
    socket.connections.add(false);
    await tester.pump();
    socket.receipts.add({
      'matchId': 'm',
      'status': 'closed',
      'wager': 10,
      'potWon': 7,
    });
    await tester.pump();
    expect(duel.state, DuelState.error);
    expect(duel.isGameOver, isFalse);
    socket.receipts.add({
      'matchId': 'm',
      'status': 'closed',
      'wager': '10',
      'potWon': 0,
    });
    await tester.pump();
    expect(tester.takeException(), isNull);
    expect(duel.potWon, 0);
    socket.receipts.add({
      'matchId': 'm',
      'status': 'closed',
      'wager': 10,
      'potWon': 20,
    });
    await tester.pump();
    expect(duel.state, DuelState.finished);
    expect(duel.potWon, 20);
  });
  testWidgets('opponent disconnect needs a receipt before announcing a prize', (
    tester,
  ) async {
    await playing(tester);
    socket.opponent.add({'matchId': 'm'});
    await tester.pump();
    expect(duel.isGameOver, isFalse);
    expect(duel.potWon, 0);
    expect(socket.queries, ['m']);
    socket.receipts.add({
      'matchId': 'm',
      'status': 'closed',
      'wager': 10,
      'potWon': 10,
    });
    await tester.pump();
    expect(duel.winner, 'refund');
    expect(duel.potWon, 10);
  });
  testWidgets(
    'a missing receipt reply is retried once per timer and account changes cancel it',
    (tester) async {
      await playing(tester);
      socket.connections.add(false);
      socket.connections.add(true);
      await tester.pump();
      expect(socket.queries, ['m']);
      await tester.pump(const Duration(seconds: 10));
      expect(socket.queries, ['m', 'm']);
      duel.setAccount(2);
      await tester.pump(const Duration(seconds: 20));
      expect(socket.queries, ['m', 'm']);
      expect(duel.state, DuelState.idle);
    },
  );
  testWidgets(
    'a lost leave acknowledgement unlocks navigation without confirming a refund',
    (tester) async {
      duel.joinQueue(5);
      bool? cancelled;
      unawaited(
        duel.leaveQueue().then((v) {
          cancelled = v;
        }),
      );
      await tester.pump(const Duration(seconds: 10));
      expect(cancelled, isFalse);
      expect(duel.state, DuelState.searching);
      final retry = duel.leaveQueue();
      socket.departures.add({'refundedWager': 5});
      await tester.pump();
      expect(await retry, isTrue);
      expect(socket.leaves, 2);
    },
  );
}
