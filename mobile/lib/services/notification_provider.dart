import 'package:flutter/material.dart';
import 'auth_provider.dart';

class PagerMessage {
  final int id;
  final String message;
  final String type; // 'admin_alert', 'peer_note', etc.
  final bool isRead;
  final DateTime createdAt;
  final String? senderName;

  PagerMessage({
    required this.id,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    this.senderName,
  });

  factory PagerMessage.fromJson(Map<String, dynamic> json) {
    return PagerMessage(
      id: json['id'],
      message: json['message'],
      type: json['type'],
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(json['created_at']),
      senderName: json['sender_name'],
    );
  }
}

class NotificationProvider with ChangeNotifier {
  final AuthProvider authProvider;
  List<PagerMessage> _messages = [];
  bool _isLoading = false;
  int _unreadCount = 0;

  NotificationProvider(this.authProvider);

  List<PagerMessage> get messages => _messages;
  bool get isLoading => _isLoading;
  int get unreadCount => _unreadCount;

  Future<void> fetchInbox() async {
    _isLoading = true;
    notifyListeners();

    try {
      final List<dynamic> data = await authProvider.apiService.get('/notifications/inbox');
      _messages = data.map((m) => PagerMessage.fromJson(m)).toList();
      _unreadCount = _messages.where((m) => !m.isRead).length;
    } catch (e) {
      debugPrint('Error fetching inbox: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> markAsRead(int id) async {
    try {
      await authProvider.apiService.put('/notifications/$id/read', {});
      
      // Update local state
      final idx = _messages.indexWhere((m) => m.id == id);
      if (idx != -1) {
        _messages[idx] = PagerMessage(
          id: _messages[idx].id,
          message: _messages[idx].message,
          type: _messages[idx].type,
          isRead: true,
          createdAt: _messages[idx].createdAt,
          senderName: _messages[idx].senderName,
        );
        _unreadCount = _messages.where((m) => !m.isRead).length;
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  Future<void> deleteMessage(int id, String type) async {
    try {
      // Optimistic delete
      _messages.removeWhere((m) => m.id == id && m.type == type);
      _unreadCount = _messages.where((m) => !m.isRead).length;
      notifyListeners();

      await authProvider.apiService.delete('/notifications/$id?type=$type');
    } catch (e) {
      debugPrint('Error deleting message: $e');
      // Re-fetch on error to ensure sync
      fetchInbox();
    }
  }

  /// 🧹 Resets the in-memory state of the notification system.
  void resetState() {
    _messages = [];
    _unreadCount = 0;
    _isLoading = false;
    notifyListeners();
  }
}
