import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:socket_io_client/socket_io_client.dart' as io;

/// A specialized service that manages the Socket.IO connection for real-time duels.
/// It wraps the socket_io_client library and exposes a cleaner interface for the DuelProvider.
class DuelSocketService {
  io.Socket? _socket;
  final String _baseUrl;
  final String? _token;

  // Stream Controllers for exposed events
  final _connectionController = StreamController<bool>.broadcast();
  final _matchFoundController = StreamController<Map<String, dynamic>>.broadcast();
  final _queueJoinedController = StreamController<Map<String, dynamic>>.broadcast();
  final _queueLeftController = StreamController<Map<String, dynamic>>.broadcast();
  final _scoreUpdateController = StreamController<Map<String, dynamic>>.broadcast();
  final _timeSyncController = StreamController<int>.broadcast();
  final _gameOverController = StreamController<Map<String, dynamic>>.broadcast();
  final _opponentDisconnectedController = StreamController<Map<String, dynamic>>.broadcast();
  final _errorController = StreamController<String>.broadcast();

  DuelSocketService(this._baseUrl, this._token) {
    _initSocket();
  }

  Stream<bool> get connectionStream => _connectionController.stream;
  Stream<Map<String, dynamic>> get matchFoundStream => _matchFoundController.stream;
  Stream<Map<String, dynamic>> get queueJoinedStream => _queueJoinedController.stream;
  Stream<Map<String, dynamic>> get queueLeftStream => _queueLeftController.stream;
  Stream<Map<String, dynamic>> get scoreUpdateStream => _scoreUpdateController.stream;
  Stream<int> get timeSyncStream => _timeSyncController.stream;
  Stream<Map<String, dynamic>> get gameOverStream => _gameOverController.stream;
  Stream<Map<String, dynamic>> get opponentDisconnectedStream => _opponentDisconnectedController.stream;
  Stream<String> get errorStream => _errorController.stream;

  bool get isConnected => _socket?.connected ?? false;

  void _initSocket() {
    debugPrint('Initializing Duel Socket at $_baseUrl');
    
    _socket = io.io(_baseUrl, io.OptionBuilder()
      .setTransports(['websocket'])
      .setAuth({'token': _token})
      .enableAutoConnect()
      .enableReconnection()
      .setReconnectionAttempts(5)
      .setReconnectionDelay(1000)
      .build());

    _socket!.onConnect((_) {
      debugPrint('Duel Socket connected: ${_socket!.id}');
      _connectionController.add(true);
    });

    _socket!.onDisconnect((_) {
      debugPrint('Duel Socket disconnected');
      _connectionController.add(false);
    });

    _socket!.onConnectError((err) {
      debugPrint('Duel Socket connect error: $err');
      _errorController.add('Connection error: $err');
    });

    // --- Backend Event Subscriptions ---
    _socket!.on('match_found', (data) => _matchFoundController.add(Map<String, dynamic>.from(data)));
    _socket!.on('queue_joined', (data) => _queueJoinedController.add(Map<String, dynamic>.from(data)));
    _socket!.on('queue_left', (data) => _queueLeftController.add(Map<String, dynamic>.from(data)));
    _socket!.on('score_update', (data) => _scoreUpdateController.add(Map<String, dynamic>.from(data)));
    _socket!.on('time_sync', (data) => _timeSyncController.add(data['time'] as int));
    _socket!.on('game_over', (data) => _gameOverController.add(Map<String, dynamic>.from(data)));
    _socket!.on('opponent_disconnected', (data) => _opponentDisconnectedController.add(Map<String, dynamic>.from(data)));
    _socket!.on('error', (data) => _errorController.add(data['message'] ?? 'Unknown socket error'));
  }

  void joinQueue(int wager) {
    if (!isConnected) {
      _errorController.add('Not connected to game server');
      return;
    }
    _socket!.emit('join_queue', {'wager': wager});
  }

  void leaveQueue() {
    if (!isConnected) return;
    _socket!.emit('leave_queue');
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
    _socket?.dispose();
    _connectionController.close();
    _matchFoundController.close();
    _queueJoinedController.close();
    _queueLeftController.close();
    _scoreUpdateController.close();
    _timeSyncController.close();
    _gameOverController.close();
    _opponentDisconnectedController.close();
    _errorController.close();
  }
}
