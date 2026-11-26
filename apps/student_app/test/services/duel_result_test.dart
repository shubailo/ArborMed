import 'dart:async';
import 'package:arbor_med/screens/game/duel_game_screen.dart';
import 'package:arbor_med/services/theme_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
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
  final answers = <dynamic>[];
  @override
  bool get isConnected => true;
  @override
  void submitAnswer(String matchId, String questionId, dynamic answer) => answers.add(answer);

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
  void joinQueue(int wager, String? token) {}
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
    duel = DuelProvider(api, openSocket: (url, token) => transport)
      ..setAccount(1)
      ..joinQueue(10);
    addTearDown(duel.dispose);
    transport.match.add({
      'matchId': 'm',
      'role': 'p2',
      'questions': [
        {
          'id': 1,
          'q': 'Test question',
          'options': ['Yes', 'No'],
          'hu': {'q': 'Tesztkérdés', 'options': ['Igen', 'Nem']},
        },
      ],
    });
    await tester.pump();
  }

  testWidgets('Hungarian duel displays translated choices and submits the canonical answer', (tester) async {
    await start(tester);
    transport.match.add({'matchId':'m','role':'p1','questions':<Map<String,dynamic>>[
      {'id':1,'q':'Test question','options':['Yes','No'],'hu':{'q':'Tesztkérdés','options':['Igen','Nem']}}
    ]});
    await tester.pump();
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(MultiProvider(providers: [
      ChangeNotifierProvider.value(value:duel),
      ChangeNotifierProvider(create: (_) => ThemeService()),
    ], child: const MaterialApp(
      locale:Locale('hu'), supportedLocales:[Locale('en'),Locale('hu')],
      localizationsDelegates:GlobalMaterialLocalizations.delegates, home:DuelGameScreen(),
    )));
    await tester.pump(const Duration(milliseconds:300));
    expect(find.text('Tesztkérdés'), findsOneWidget);
    await tester.tap(find.text('Igen'));
    await tester.pump(const Duration(milliseconds:300));
    expect(transport.answers, ['Yes']);
  });

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
