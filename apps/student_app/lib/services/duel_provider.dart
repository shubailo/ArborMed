import 'package:flutter/material.dart';
import 'package:arbor_med/services/duel_socket_service.dart';
import 'package:arbor_med/services/api_service.dart';

enum DuelState { idle, searching, playing, finished, error }

class DuelProvider with ChangeNotifier {
  final ApiService _apiService;
  DuelSocketService? _socketService;

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

  DuelProvider(this._apiService);

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
  List<Map<String, dynamic>> get questions => _rawQuestions;

  bool get isConnected => _socketService?.isConnected ?? false;

  void initialize() {
    if (_socketService != null) return;
    
    final baseUrl = ApiService.baseUrl;
    final token = _apiService.token;
    
    _socketService = DuelSocketService(baseUrl, token);
    _setupListeners();
  }

  void _setupListeners() {
    _socketService!.connectionStream.listen((connected) {
      if (!connected && _state != DuelState.finished) {
        _state = DuelState.error;
        _errorMessage = 'Disconnected from game server';
        notifyListeners();
      }
    });

    _socketService!.queueJoinedStream.listen((data) {
      _state = DuelState.searching;
      notifyListeners();
    });

    _socketService!.queueLeftStream.listen((data) {
      _state = DuelState.idle;
      _currentWager = 0;
      notifyListeners();
    });

    _socketService!.matchFoundStream.listen((data) {
      _matchId = data['matchId'];
      _role = data['role'];
      _rawQuestions = List<Map<String, dynamic>>.from(data['questions']);
      _opponentName = data['opponentName'];
      _state = DuelState.playing;
      _currentQuestionIndex = 0;
      _p1Score = 0;
      _p2Score = 0;
      _timeRemaining = 60;
      _isGameOver = false;
      _potWon = 0;
      notifyListeners();
    });

    _socketService!.scoreUpdateStream.listen((data) {
      _p1Score = data['p1'];
      _p2Score = data['p2'];
      notifyListeners();
    });

    _socketService!.timeSyncStream.listen((time) {
      _timeRemaining = time;
      notifyListeners();
    });

    _socketService!.gameOverStream.listen((data) {
      _isGameOver = true;
      _winner = data['winner'];
      _potWon = (data['potWon'] is num) ? (data['potWon'] as num).toInt() : 0;
      _state = DuelState.finished;
      notifyListeners();
    });

    _socketService!.opponentDisconnectedStream.listen((data) {
      _isGameOver = true;
      _winner = _role; // Survivor wins
      _potWon = (data['potWon'] is num) ? (data['potWon'] as num).toInt() : _currentWager * 2;
      _state = DuelState.finished;
      notifyListeners();
    });

    _socketService!.errorStream.listen((msg) {
      _state = DuelState.error;
      _errorMessage = msg;
      notifyListeners();
    });
  }

  void joinQueue(int wager) {
    if (_socketService == null) initialize();
    _currentWager = wager;
    _errorMessage = null;
    _potWon = 0;
    _socketService!.joinQueue(wager);
  }

  void leaveQueue() {
    _socketService?.leaveQueue();
    _state = DuelState.idle;
    _currentWager = 0;
    notifyListeners();
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
    _state = DuelState.idle;
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

  @override
  void dispose() {
    _socketService?.dispose();
    super.dispose();
  }
}
