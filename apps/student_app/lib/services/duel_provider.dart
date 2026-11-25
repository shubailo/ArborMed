import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arbor_med/services/duel_socket_service.dart';
import 'package:arbor_med/services/api_service.dart';

enum DuelState { idle, searching, playing, finished, error }

class DuelProvider with ChangeNotifier {
  final ApiService _apiService;
  final DuelSocketService Function(String, String?) _openSocket;
  Timer? _resultRetry;
  bool _hasFinalScores = false;
  DuelSocketService? _socketService;
  int? _accountId;
  Completer<bool>? _leaving;
  final List<StreamSubscription<dynamic>> _listeners = [];

  DuelState _state = DuelState.idle;
  int _currentWager = 0;
  String? _errorMessage;
  
  // Match Data
  String? _matchId;
  String? _role; // 'p1' or 'p2'
  List<Map<String, dynamic>> _rawQuestions = [];
  int _currentQuestionIndex = 0;
  int _p1Score = 0;
  int _p2Score = 0;
  int _timeRemaining = 60;
  bool _isGameOver = false;
  String? _winner; // 'p1', 'p2', or 'draw'
  String? _opponentName;
  int _potWon = 0;

  DuelProvider(this._apiService, {DuelSocketService Function(String, String?)? openSocket})
      : _openSocket = openSocket ?? DuelSocketService.new;

  // Getters
  DuelState get state => _state;
  int get currentWager => _currentWager;
  String? get errorMessage => _errorMessage;
  String? get matchId => _matchId;
  String? get role => _role;
  int get currentQuestionIndex => _currentQuestionIndex;
  int get p1Score => _p1Score;
  int get p2Score => _p2Score;
  int get timeRemaining => _timeRemaining;
  bool get isGameOver => _isGameOver;
  String? get winner => _winner;
  String? get opponentName => _opponentName;
  int get potWon => _potWon;
  bool get hasFinalScores => _hasFinalScores;
  List<Map<String, dynamic>> get questions => _rawQuestions;

  bool get isConnected => _socketService?.isConnected ?? false;

  void setAccount(int? userId) {
    if (userId == _accountId) {
      _socketService?.setToken(_apiService.token);
      return;
    }
    _disconnect();
    _accountId = userId;
    reset();
  }

  void initialize() {
    if (_socketService != null || _accountId == null || _apiService.token == null) return;
    
    final baseUrl = ApiService.baseUrl;
    final token = _apiService.token;
    
    _socketService = _openSocket(baseUrl, token);
    _setupListeners();
  }

  void _setupListeners() {
    _listeners.add(_socketService!.connectionStream.listen((connected) {
      if (connected && _state == DuelState.error && _matchId != null) {
        checkResult();
      } else if (!connected && _state != DuelState.finished) {
        _resultRetry?.cancel();
        _state = DuelState.error;
        _errorMessage = 'Disconnected from game server';
        _resolveLeave(true);
        notifyListeners();
      }
    }));

    _listeners.add(_socketService!.queueJoinedStream.listen((data) {
      if (_state == DuelState.searching) notifyListeners();
    }));

    _listeners.add(_socketService!.queueLeftStream.listen((data) {
      _state = DuelState.idle;
      _resolveLeave(true);
      _currentWager = 0;
      notifyListeners();
    }));

    _listeners.add(_socketService!.matchFoundStream.listen((data) {
      _resultRetry?.cancel();
      _hasFinalScores = false;
      _matchId = data['matchId'];
      _role = data['role'];
      _rawQuestions = List<Map<String, dynamic>>.from(data['questions']);
      _opponentName = data['opponentName'];
      _state = DuelState.playing;
      _resolveLeave(false);
      _currentQuestionIndex = 0;
      _p1Score = 0;
      _p2Score = 0;
      _timeRemaining = 60;
      _isGameOver = false;
      _potWon = 0;
      notifyListeners();
    }));

    _listeners.add(_socketService!.scoreUpdateStream.listen((data) {
      _p1Score = data['p1'];
      _p2Score = data['p2'];
      notifyListeners();
    }));

    _listeners.add(_socketService!.timeSyncStream.listen((time) {
      _timeRemaining = time;
      notifyListeners();
    }));

    _listeners.add(_socketService!.gameOverStream.listen((data) {
      if (_matchId == null || (data['matchId'] != null && data['matchId'] != _matchId)) return;
      _hasFinalScores = data['myScore'] is int && data['opScore'] is int;
      if (_hasFinalScores) {
        _p1Score = _role == 'p1' ? data['myScore'] : data['opScore'];
        _p2Score = _role == 'p2' ? data['myScore'] : data['opScore'];
      }
      final payout = data['potWon'];
      _finish(data['refunded'] == true ? 'refund' : data['winner'], payout is num ? payout.toInt() : 0);
    }));

    _listeners.add(_socketService!.receiptStream.listen((data) {
      if (data['matchId'] != _matchId || _matchId == null || _state != DuelState.error) return;
      _resultRetry?.cancel();
      if (data['status'] == 'closed') {
        _currentWager = data['wager'] as int;
        final payout = data['potWon'] as int;
        final opponent = _role == 'p1' ? 'p2' : 'p1';
        final winner = payout == _currentWager ? 'refund' : (payout == 0 ? opponent : _role);
        _finish(winner, payout);
        return;
      }
      if (data['status'] == 'pending' || data['status'] == 'retry') {
        _errorMessage = 'Waiting for the server to settle your wager.';
        _resultRetry = Timer(const Duration(seconds: 5), checkResult);
      } else {
        _errorMessage = 'The duel result is unavailable. Check your wallet for the final balance.';
      }
      notifyListeners();
    }));

    _listeners.add(_socketService!.opponentDisconnectedStream.listen((data) {
      _isGameOver = true;
      _winner = _role; // Survivor wins
      _potWon = (data['potWon'] is num) ? (data['potWon'] as num).toInt() : _currentWager * 2;
      _state = DuelState.finished;
      notifyListeners();
    }));

    _listeners.add(_socketService!.errorStream.listen((msg) {
      _state = DuelState.error;
      _errorMessage = msg;
      _resolveLeave(true);
      notifyListeners();
    }));
  }

  void _finish(String? winner, int payout) {
    _resultRetry?.cancel();
    _winner = winner;
    _potWon = payout;
    _isGameOver = true;
    _state = DuelState.finished;
    notifyListeners();
  }

  void checkResult() {
    _resultRetry?.cancel();
    if (_matchId != null && _state == DuelState.error) {
      _socketService!.requestResult(_matchId!, _apiService.token);
    }
  }

  void joinQueue(int wager) {
    if (_socketService == null) initialize();
    if (_state == DuelState.searching || _state == DuelState.playing || _socketService == null) return;
    _state = DuelState.searching;
    _currentWager = wager;
    _errorMessage = null;
    _potWon = 0;
    notifyListeners();
    _socketService?.joinQueue(wager, _apiService.token);
  }

  Future<bool> leaveQueue() {
    if (_state != DuelState.searching) return Future.value(_state != DuelState.playing);
    if (_leaving != null) return _leaving!.future;
    final completion = _leaving = Completer<bool>();
    if (isConnected) {
      _socketService!.leaveQueue();
    } else {
      _resolveLeave(true);
    }
    return completion.future;
  }

  void _resolveLeave(bool cancelled) {
    _leaving?.complete(cancelled);
    _leaving = null;
  }

  void submitAnswer(dynamic answer) {
    if (_matchId == null || _state != DuelState.playing) return;
    
    final currentQ = _rawQuestions[_currentQuestionIndex];
    _socketService!.submitAnswer(_matchId!, currentQ['id'].toString(), answer);
    
    // Move to next question locally if possible
    if (_currentQuestionIndex < _rawQuestions.length - 1) {
      _currentQuestionIndex++;
      notifyListeners();
    }
  }

  void reset() {
    _resultRetry?.cancel();
    _hasFinalScores = false;
    _resolveLeave(true);
    _state = DuelState.idle;
    _currentWager = 0;
    _matchId = null;
    _role = null;
    _rawQuestions = [];
    _currentQuestionIndex = 0;
    _p1Score = 0;
    _p2Score = 0;
    _isGameOver = false;
    _winner = null;
    _opponentName = null;
    _errorMessage = null;
    _potWon = 0;
    notifyListeners();
  }

  void _disconnect() {
    _resultRetry?.cancel();
    _resolveLeave(true);
    for (final subscription in _listeners) {
      unawaited(subscription.cancel());
    }
    _listeners.clear();
    _socketService?.dispose();
    _socketService = null;
  }

  @override
  void dispose() {
    _disconnect();
    super.dispose();
  }
}
