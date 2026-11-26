import 'dart:async';
import 'package:flutter/material.dart';
import 'package:arbor_med/services/duel_socket_service.dart';
import 'package:arbor_med/services/api_service.dart';

enum DuelState { idle, searching, playing, finished, error }

class DuelProvider with ChangeNotifier {
  final ApiService _apiService;
  final DuelSocketService Function(String, String?) _openSocket;
  Timer? _resultRetry;
  Timer? _leaveTimeout;
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
  bool _answeredLastQuestion = false;
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
  bool get canSubmitAnswer => _state == DuelState.playing && isConnected &&
      _timeRemaining > 0 && !_answeredLastQuestion;
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
      if (_state != DuelState.searching) return;
      _state = DuelState.idle;
      _resolveLeave(true);
      _currentWager = 0;
      notifyListeners();
    }));

    _listeners.add(_socketService!.matchFoundStream.listen((data) {
      if (_state != DuelState.searching) return;
      _resultRetry?.cancel();
      _hasFinalScores = false;
      final id = data['matchId'];
      final role = data['role'];
      final questions = data['questions'];
      if (id is! String || id.isEmpty || (role != 'p1' && role != 'p2') ||
          questions is! List || questions.isEmpty || !questions.every((q) => q is Map<String,dynamic> && q['id'] != null)) {
        _matchId = id is String && id.isNotEmpty ? id : null;
        _role = role == 'p1' || role == 'p2' ? role as String : null;
        _state = DuelState.error;
        _errorMessage = 'Invalid match details. Check the result before playing again.';
        _resolveLeave(false);
        if (_matchId != null && _role != null) checkResult();
        notifyListeners();
        return;
      }
      _matchId = id;
      _role = role as String;
      _rawQuestions = List<Map<String, dynamic>>.from(questions);
      final opponent = data['opponentName'];
      _opponentName = opponent is String ? opponent : null;
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
      if (!_isCurrentUpdate(data) || data['p1'] is! int || data['p2'] is! int ||
          data['p1'] < _p1Score || data['p2'] < _p2Score) {
        return;
      }
      _p1Score = data['p1'];
      _p2Score = data['p2'];
      notifyListeners();
    }));

    _listeners.add(_socketService!.timeSyncStream.listen((data) {
      final time = data['time'];
      if (!_isCurrentUpdate(data) || time is! int || time < 0 || time > _timeRemaining) return;
      _timeRemaining = time;
      notifyListeners();
    }));

    _listeners.add(_socketService!.gameOverStream.listen((data) {
      if ((_state != DuelState.playing && _state != DuelState.error) ||
          _matchId == null || data['matchId'] != _matchId) {
        return;
      }
      final payout = data['potWon'];
      final winner = data['winner'];
      final refunded = data['refunded'] == true;
      final expectedPayout = refunded || winner == 'draw' ? _currentWager : (winner == _role ? 2*_currentWager : 0);
      if (payout is! int || payout != expectedPayout || !(winner == 'p1' || winner == 'p2' || winner == 'draw')) {
        _awaitReceipt();
        return;
      }
      _hasFinalScores = data['myScore'] is int && data['opScore'] is int;
      if (_hasFinalScores) {
        _p1Score = _role == 'p1' ? data['myScore'] : data['opScore'];
        _p2Score = _role == 'p2' ? data['myScore'] : data['opScore'];
      }
      _finish(refunded ? 'refund' : winner as String, payout);
    }));

    _listeners.add(_socketService!.receiptStream.listen((data) {
      if (data['matchId'] != _matchId || _matchId == null || _state != DuelState.error) return;
      _resultRetry?.cancel();
      if (data['status'] == 'closed') {
        final wager = data['wager'];
        final payout = data['potWon'];
        if (wager is! int || wager <= 0 || wager != _currentWager || payout is! int ||
            (payout != 0 && payout != wager && payout != wager*2) || _role == null) {
          _errorMessage = 'Invalid duel receipt. Check your wallet for the final balance.';
          notifyListeners();
          return;
        }
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
      if (_state != DuelState.playing ||
          (data['matchId'] != null && data['matchId'] != _matchId)) {
        return;
      }
      _awaitReceipt();
    }));

    _listeners.add(_socketService!.errorStream.listen((msg) {
      if (_state == DuelState.finished) return;
      _state = DuelState.error;
      _errorMessage = msg;
      _resolveLeave(true);
      notifyListeners();
    }));
  }

  bool _isCurrentUpdate(Map<String, dynamic> data) =>
      _state == DuelState.playing && (data['matchId'] == null || data['matchId'] == _matchId);

  void _awaitReceipt() {
    _state = DuelState.error;
    _errorMessage = 'Waiting for the server to settle your wager.';
    checkResult();
    notifyListeners();
  }

  void _finish(String? winner, int payout) {
    _resultRetry?.cancel();
    _errorMessage = null;
    _winner = winner;
    _potWon = payout;
    _isGameOver = true;
    _state = DuelState.finished;
    notifyListeners();
  }

  void checkResult() {
    _resultRetry?.cancel();
    if (_matchId != null && _state == DuelState.error) {
      _resultRetry = Timer(const Duration(seconds: 10), checkResult);
      _socketService!.requestResult(_matchId!, _apiService.token);
    }
  }

  void joinQueue(int wager) {
    if (_socketService == null) initialize();
    if (_state == DuelState.searching || _state == DuelState.playing || _socketService == null) return;
    _clearMatch();
    _state = DuelState.searching;
    _currentWager = wager;
    notifyListeners();
    _socketService?.joinQueue(wager, _apiService.token);
  }

  Future<bool> leaveQueue() {
    if (_state != DuelState.searching) return Future.value(_state != DuelState.playing);
    if (_leaving != null) return _leaving!.future;
    final completion = _leaving = Completer<bool>();
    if (isConnected) {
      _leaveTimeout = Timer(const Duration(seconds: 10), () => _resolveLeave(false));
      _socketService!.leaveQueue();
    } else {
      _socketService?.leaveQueue(); // Cancel any wager waiting for the initial handshake.
      _resolveLeave(true);
    }
    return completion.future;
  }

  void _resolveLeave(bool cancelled) {
    _leaveTimeout?.cancel();
    _leaving?.complete(cancelled);
    _leaving = null;
  }

  void submitAnswer(dynamic answer) {
    if (!canSubmitAnswer) return;
    
    final currentQ = _rawQuestions[_currentQuestionIndex];
    _socketService!.submitAnswer(_matchId!, currentQ['id'].toString(), answer);
    
    // Move to next question locally if possible
    if (_currentQuestionIndex < _rawQuestions.length - 1) {
      _currentQuestionIndex++;
    } else {
      _answeredLastQuestion = true;
    }
    notifyListeners();
  }

  void reset() {
    _clearMatch();
    notifyListeners();
  }

  void _clearMatch() {
    _resultRetry?.cancel();
    _hasFinalScores = false;
    _resolveLeave(true);
    _state = DuelState.idle;
    _currentWager = 0;
    _answeredLastQuestion = false;
    _matchId = null;
    _role = null;
    _rawQuestions = [];
    _currentQuestionIndex = 0;
    _p1Score = 0;
    _p2Score = 0;
    _timeRemaining = 60;
    _isGameOver = false;
    _winner = null;
    _opponentName = null;
    _errorMessage = null;
    _potWon = 0;
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
