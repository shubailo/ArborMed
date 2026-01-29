import 'package:flutter/material.dart';

class SocialDoctor {
  final String id;
  final String name;
  final String avatar;
  final String level;
  final List<Map<String, dynamic>> layout;

  SocialDoctor({
    required this.id,
    required this.name,
    required this.avatar,
    required this.level,
    this.layout = const [],
  });
}

class SocialProvider with ChangeNotifier {
  String? _visitingUserId;
  String? get visitingUserId => _visitingUserId;
  bool get isVisiting => _visitingUserId != null;

  final List<SocialDoctor> _friends = [
    SocialDoctor(
      id: 'dr_smith', 
      name: 'Dr. Alex Smith', 
      avatar: 'profile', 
      level: 'Lvl 12 Resident',
      layout: [
        {'name': 'Vintage Doctor Bed', 'asset_path': 'assets/images/furniture/gurney.png', 'x': 2, 'y': -1, 'slot_type': 'exam_table'},
        {'name': 'Modern Glass Desk', 'asset_path': 'assets/images/furniture/desk.png', 'x': 0, 'y': 2, 'slot_type': 'desk'},
        {'name': 'Vital Monitor stand', 'asset_path': 'assets/images/furniture/monitor.png', 'x': 3, 'y': -1, 'slot_type': 'monitor'},
      ]
    ),
    SocialDoctor(
      id: 'dr_jones', 
      name: 'Dr. Sarah Jones', 
      avatar: 'profile', 
      level: 'Lvl 8 Intern',
      layout: [
        {'name': 'Blue Gurney', 'asset_path': 'assets/images/furniture/gurney.png', 'x': 1, 'y': -2, 'slot_type': 'exam_table'},
        {'name': 'Simple Desk', 'asset_path': 'assets/images/furniture/desk.png', 'x': 1, 'y': 2, 'slot_type': 'desk'},
      ]
    ),
  ];

  List<SocialDoctor> get friends => _friends;

  void startVisiting(String userId) {
    _visitingUserId = userId;
    notifyListeners();
  }

  void stopVisiting() {
    _visitingUserId = null;
    notifyListeners();
  }

  SocialDoctor? getVisitingDoctor() {
    if (_visitingUserId == null) return null;
    return _friends.firstWhere((d) => d.id == _visitingUserId, orElse: () => _friends[0]);
  }
}
