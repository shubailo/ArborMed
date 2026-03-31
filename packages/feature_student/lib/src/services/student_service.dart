import 'package:flutter/foundation.dart';
import 'package:isar/isar.dart';
import 'package:arbormed_core/arbormed_core.dart';
import 'package:core_interop/core_interop.dart';

class StudentService extends ChangeNotifier implements StudentContract {
  final Isar _isar;
  StudentProfileCollection? _profile;

  StudentService(this._isar);

  StudentProfileCollection? get profile => _profile;

  Future<void> loadProfile(String userId) async {
    _profile = await _isar.studentProfileCollections
        .filter()
        .userIdEqualTo(userId)
        .findFirst();
    
    if (_profile == null) {
      _profile = StudentProfileCollection()
        ..userId = userId
        ..displayName = 'New Student'
        ..xp = 0
        ..coins = 0
        ..level = 1;
      
      await _isar.writeTxn(() async {
        await _isar.studentProfileCollections.put(_profile!);
      });
    }
    notifyListeners();
  }

  @override
  Future<void> addXP(int amount) async {
    if (_profile == null) return;
    
    _profile!.xp += amount;
    // Simple level up logic: 100 XP per level
    _profile!.level = (_profile!.xp / 100).floor() + 1;

    await _saveProfile();
  }

  @override
  Future<void> addCoins(int amount) async {
    if (_profile == null) return;
    _profile!.coins += amount;
    await _saveProfile();
  }

  @override
  Future<int> getXP() async => _profile?.xp ?? 0;

  @override
  Future<int> getCoins() async => _profile?.coins ?? 0;

  @override
  Future<int> getLevel() async => _profile?.level ?? 1;

  Future<void> _saveProfile() async {
    if (_profile == null) return;
    await _isar.writeTxn(() async {
      await _isar.studentProfileCollections.put(_profile!);
    });
    notifyListeners();
  }
}
