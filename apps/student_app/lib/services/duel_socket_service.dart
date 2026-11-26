import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// A specialized service that manages the Socket.IO connection for real-time duels.
/// It wraps the socket_io_client library and exposes a cleaner interface for the DuelProvider.
class DuelSocketService {
  io.Socket? _socket;
  final String _baseUrl;
  String? _token;
  int? _pendingWager;

  // Stream Controllers for exposed events
  final _connectionController = StreamController<bool>.broadcast();
  final _matchFoundController = StreamController<Map<String, dynamic>>.broadcast();
  final _queueJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _queueLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _scoreUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _timeSyncController = StreamController<int>.broadcast();
  final _receiptController = StreamController<Map<String, dynamic>>.broadcast();
  final _gameOverController = StreamController<Map<String, dynamic>>.broadcast();
  final _opponentDisconnectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  DuelSocketService(this._baseUrl, this._token,
      {io.Socket Function(String, Map<String, dynamic>) openSocket = io.io}) {
    _initSocket(openSocket);
  }

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get matchFoundStream => _matchFoundController.stream;
  Stream<Map<String, dynamic>> get queueJoinedStream => _queueJoinedController.stream;
  Stream<Map<String, dynamic>> get queueLeftStream => _queueLeftController.stream;
  Stream<Map<String, dynamic>> get scoreUpdateStream => _scoreUpdateController.stream;
  Stream<int> get timeSyncStream => _timeSyncController.stream;
  Stream<Map<String, dynamic>> get receiptStream => _receiptController.stream;
  Stream<Map<String, dynamic>> get gameOverStream => _gameOverController.stream;
  Stream<Map<String, dynamic>> get opponentDisconnectedStream => _opponentDisconnectedController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void _initSocket(io.Socket Function(String, Map<String, dynamic>) openSocket) {
    debugPrint('Initializing Duel Socket at $_baseUrl');
    
    _socket = openSocket(_baseUrl, io.OptionBuilder()
      .enableForceNew()
      .setTransports(['websocket'])
      .setAuth({'token': _token})
      .disableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(5)
      .setReconnectionDelay(1000)
      .build());

    _socket!.onConnect((_) {
      debugPrint('Duel Socket connected: ${_socket!.id}');
      final wager = _pendingWager;
      _pendingWager = null;
      if (wager != null) _emitJoin(wager);
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      _pendingWager = null;
      debugPrint('Duel Socket disconnected');
      _connectionController.add(false);
    });

    _socket!.onConnectError((err) {
      _pendingWager = null;
      debugPrint('Duel Socket connect error: $err');
      _errorController.add('Connection error: $err');
    });

    void forwardMap(String event, StreamController<Map<String, dynamic>> controller) {
      _socket!.on(event, (data) {
        if (data is Map<String, dynamic>) {
          controller.add(data);
        } else if (data is Map && data.keys.every((key) => key is String)) {
          controller.add(Map<String, dynamic>.from(data));
        }
      });
    }

    forwardMap('match_found', _matchFoundController);
    forwardMap('queue_joined', _queueJoinedController);
    forwardMap('queue_left', _queueLeftController);
    forwardMap('score_update', _scoreUpdateController);
    forwardMap('duel_result', _receiptController);
    forwardMap('game_over', _gameOverController);
    forwardMap('opponent_disconnected', _opponentDisconnectedController);
    _socket!.on('time_sync', (data) {
      final time = data is Map ? data['time'] : null;
      if (time is int && time >= 0) _timeSyncController.add(time);
    });
    _socket!.on('error', (data) {
      final message = data is Map ? data['message'] : data;
      _errorController.add(message is String ? message : 'Unknown socket error');
    });
    _socket!.connect();
  }

  void setToken(String? token) {
    if (_token == token) return;
    _token = token;
    _socket?.auth = {'token': token};
    if (token == null || token.isEmpty) _pendingWager = null;
    if (token != null && token.isNotEmpty && !isConnected) _socket?.connect();
  }

  void joinQueue(int wager, String? token) {
    if (token == null || token.isEmpty) {
      _pendingWager = null;
      _errorController.add('Sign in to join a duel.');
      return;
    }
    if (!isConnected) {
      _pendingWager = wager;
      if (_token == token) {
        _socket?.connect();
      } else {
        setToken(token);
      }
      return;
    }
    setToken(token);
    _emitJoin(wager);
  }

  void _emitJoin(int wager) {
    _socket!.emit('join_queue', {'wager': wager, 'token': _token});
  }

  void leaveQueue() {
    if (_pendingWager != null) {
      _pendingWager = null;
      _queueLeftController.add({'refundedWager': 0});
      return;
    }
    if (!isConnected) return;
    _socket!.emit('leave_queue');
  }

  void requestResult(String matchId, String? token) {
    setToken(token);
    if (isConnected) {
      _socket!.emit('duel_result_request', {'matchId': matchId, 'token': token});
    } else {
      _socket?.connect();
    }
  }

  void submitAnswer(String matchId, String questionId, dynamic answer) {
    if (!isConnected) return;
    _socket!.emit('submit_answer', {
      'matchId': matchId,
      'questionId': questionId,
      'answer': answer,
    });
  }

  void dispose() {
    _pendingWager = null;
    _socket?.dispose();
    _connectionController.close();
    _matchFoundController.close();
    _queueJoinedController.close();
    _queueLeftController.close();
    _scoreUpdateController.close();
    _timeSyncController.close();
    _gameOverController.close();
    _receiptController.close();
    _opponentDisconnectedController.close();
    _errorController.close();
  }
}
