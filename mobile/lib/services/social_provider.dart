import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/api_service.dart';
import '../models/user.dart';
import 'shop_provider.dart';

class SocialProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  List<User> _colleagues = [];
  List<User> _pendingRequests = [];
  User? _visitedUser; // If null, user is in their own room
  bool _isLoading = false;

  List<User> get colleagues => _colleagues;
  List<User> get pendingRequests => _pendingRequests;
  User? get visitedUser => _visitedUser;
  bool get isVisiting => _visitedUser != null;
  bool get isLoading => _isLoading;

  User? getVisitingDoctor() => _visitedUser;

  void startVisiting(User user, BuildContext context) {
    _visitedUser = user;
    Provider.of<ShopProvider>(context, listen: false).fetchRemoteInventory(user.id);
    notifyListeners();
  }

  void stopVisiting(BuildContext context) {
    _visitedUser = null;
    Provider.of<ShopProvider>(context, listen: false).clearVisitedInventory();
    notifyListeners();
  }

  Future<void> fetchNetwork() async {
    _isLoading = true;
    notifyListeners();
    try {
      final data = await _apiService.get('/social/network');
      _colleagues = (data['colleagues'] as List).map((u) => User.fromJson(u)).toList();
      _pendingRequests = (data['pending'] as List).map((u) => User.fromJson(u)).toList();
    } catch (e) {
      debugPrint("Error fetching network: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<List<User>> searchUsers(String query) async {
    try {
      final data = await _apiService.get('/social/search?query=$query');
      return (data as List).map((u) => User.fromJson(u)).toList();
    } catch (e) {
      debugPrint("Error searching users: $e");
      return [];
    }
  }

  Future<void> sendRequest(int receiverId) async {
    try {
      await _apiService.post('/social/request', {'receiverId': receiverId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> respondToRequest(int requesterId, String action) async {
    try {
      await _apiService.put('/social/request', {
        'requesterId': requesterId,
        'action': action, // 'accept' or 'decline'
      });
      await fetchNetwork();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> unfriend(int targetUserId) async {
    try {
      await _apiService.delete('/social/colleague/$targetUserId');
      await fetchNetwork();
    } catch (e) {
      rethrow;
    }
  }

  Future<void> likeRoom(int targetUserId) async {
    try {
      await _apiService.post('/social/like', {'targetUserId': targetUserId});
    } catch (e) {
      rethrow;
    }
  }

  Future<void> leaveNote(int targetUserId, String note) async {
    try {
      await _apiService.post('/social/note', {
        'targetUserId': targetUserId,
        'note': note,
      });
    } catch (e) {
      rethrow;
    }
  }

  Future<List<dynamic>> getNotes(int userId) async {
    try {
      return await _apiService.get('/social/notes/$userId');
    } catch (e) {
      debugPrint("Error fetching notes: $e");
      return [];
    }
  }
}
