import 'dart:async';
import 'package:arbor_med/services/api_service.dart';
import 'package:arbor_med/services/duel_provider.dart';
import 'package:arbor_med/services/duel_socket_service.dart';
import 'package:flutter_test/flutter_test.dart';

class _Transport extends Fake implements DuelSocketService {
  final connection = StreamController<bool>.broadcast();
  final match = StreamController<Map<String, dynamic>>.broadcast();
  final receipt = StreamController<Map<String, dynamic>>.broadcast();
  final over = StreamController<Map<String, dynamic>>.broadcast();
  final requests = <String>[];

  @override
  Stream<bool> get connectionStream => connection.stream;
  @override
  Stream<Map<String, dynamic>> get matchFoundStream => match.stream;
  @override
  Stream<Map<String, dynamic>> get receiptStream => receipt.stream;
  @override
  Stream<Map<String, dynamic>> get gameOverStream => over.stream;
  @override
  Stream<Map<String, dynamic>> get queueJoinedStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get queueLeftStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get scoreUpdateStream => const Stream.empty();
  @override
  Stream<int> get timeSyncStream => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get opponentDisconnectedStream => const Stream.empty();
  @override
  Stream<String> get errorStream => const Stream.empty();
  @override
  void requestResult(String matchId, String? token) => requests.add(matchId);
  @override
  void dispose() {
    connection.close();
    match.close();
    receipt.close();
    over.close();
  }
}

void main() {
  late DuelProvider duel;
  late _Transport transport;
  Future<void> start(WidgetTester tester) async {
    final api = ApiService()..setToken('test', userId: 1);
    transport = _Transport();
    duel = DuelProvider(api, openSocket: (url, token) => transport)..setAccount(1)..initialize();
    addTearDown(duel.dispose);
    transport.match.add({'matchId': 'm', 'role': 'p2', 'questions': <Map<String,dynamic>>[]});
    await tester.pump();
  }

  testWidgets('reconnect waits for the recorded wager payout', (tester) async {
    await start(tester);
    transport.connection.add(false);
    transport.connection.add(true);
    await tester.pump();
    expect(transport.requests, ['m']);
    transport.receipt.add({'matchId':'other','status':'closed','wager':10,'potWon':20});
    transport.receipt.add({'matchId':'m','status':'pending'});
    await tester.pump();
    expect(duel.state, DuelState.error);
    await tester.pump(const Duration(seconds:5));
    expect(transport.requests, ['m','m']);
    transport.receipt.add({'matchId':'m','status':'closed','wager':10,'potWon':10});
    await tester.pump();
    expect(duel.state, DuelState.finished);
    expect(duel.winner, 'refund');
    expect(duel.potWon, 10);
    expect(duel.hasFinalScores, isFalse);
  });

  testWidgets('game over carries final scores and old results cannot revive an exited match', (tester) async {
    await start(tester);
    transport.over.add({'matchId':'m','winner':'p2','potWon':20,'myScore':3,'opScore':1});
    await tester.pump();
    expect(duel.hasFinalScores, isTrue);
    expect([duel.p1Score,duel.p2Score], [1,3]);
    duel.reset();
    transport.over.add({'matchId':'m','winner':'p2','potWon':20});
    await tester.pump();
    expect(duel.state, DuelState.idle);
  });
}
