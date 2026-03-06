import 'package:arbor_med/services/api_service.dart';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:arbor_med/services/auth_provider.dart';

enum WardState { idle, lobby, playing, summary }

class WardProvider with ChangeNotifier {
  final AuthProvider _auth;
  IO.Socket? _socket;

  String? _currentWardCode;
  String? _wardName;
  WardState _state = WardState.idle;
  int _userCount = 0;

  // Game state
  Map<String, dynamic>? _currentCase;
  int _votesCast = 0;
  Map<String, dynamic>? _roundResult;
  String? _errorMessage;

  WardProvider(this._auth) {
    _initSocket();
  }

  void updateAuth(AuthProvider auth) {
    if (auth.isAuthenticated && _socket == null) {
      _initSocket();
    } else if (!auth.isAuthenticated && _socket != null) {
      _socket?.disconnect();
      _socket = null;
    }
  }

  String? get currentWardCode => _currentWardCode;
  String? get wardName => _wardName;
  WardState get state => _state;
  int get userCount => _userCount;
  Map<String, dynamic>? get currentCase => _currentCase;
  int get votesCast => _votesCast;
  Map<String, dynamic>? get roundResult => _roundResult;
  String? get errorMessage => _errorMessage;
  bool _isHost = false;
  bool get isHost => _isHost;

  void _initSocket() {
    if (!_auth.isAuthenticated || _auth.token == null) return;

    final String baseUrl = ApiService.baseUrl;

    _socket = IO.io(
      baseUrl,
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .setAuth({'token': _auth.token})
          .build(),
    );

    _socket?.onConnect((_) {
      debugPrint('WardProvider: Connected to socket');
    });

    _socket?.on('ward_created', (data) {
      _currentWardCode = data['code'];
      _wardName = data['name'];
      _state = WardState.lobby;
      _userCount = 1;
      _isHost = true;
      _errorMessage = null;
      notifyListeners();
    });

    _socket?.on('ward_joined', (data) {
      _currentWardCode = data['code'];
      _isHost = false;
      _state = WardState.lobby;
      _errorMessage = null;
      notifyListeners();
    });

    _socket?.on('ward_updated', (data) {
      _userCount = data['usersCount'] ?? _userCount;
      if (data['state'] == 'LOBBY') _state = WardState.lobby;
      notifyListeners();
    });

    _socket?.on('ward_round_started', (data) {
      _state = WardState.playing;
      _currentCase = data['question'];
      _votesCast = 0;
      _roundResult = null;
      notifyListeners();
    });

    _socket?.on('ward_vote_update', (data) {
      _votesCast = data['votesCast'] ?? 0;
      notifyListeners();
    });

    _socket?.on('ward_round_ended', (data) {
      _state = WardState.summary;
      _roundResult = data;

      // Removing unsupported optimistic reward update for MVP
      notifyListeners();
    });

    _socket?.on('ward_error', (data) {
      _errorMessage = data['message'];
      notifyListeners();
    });

    _socket?.connect();
  }

  void createWard(String name) {
    _errorMessage = null;
    notifyListeners();
    _socket?.emit('ward_create', {'wardName': name});
  }

  void joinWard(String code) {
    _errorMessage = null;
    notifyListeners();
    _socket?.emit('ward_join', {'code': code});
  }

  void startRound() {
    if (_currentWardCode != null) {
      _socket?.emit('ward_start_round', {'code': _currentWardCode});
    }
  }

  void submitVote(String answerId) {
    if (_currentWardCode != null) {
      _socket?.emit('ward_submit_vote', {'code': _currentWardCode, 'answer': answerId});
    }
  }

  void leaveWard() {
    _socket?.emit('ward_leave');
    _currentWardCode = null;
    _wardName = null;
    _state = WardState.idle;
    _userCount = 0;
    _currentCase = null;
    _roundResult = null;
    _isHost = false;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _socket?.disconnect();
    _socket?.dispose();
    super.dispose();
  }
}
