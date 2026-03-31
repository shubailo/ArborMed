import 'package:isar/isar.dart';

part 'student_profile_collection.g.dart';

@collection
class StudentProfileCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String userId; // Link to Auth system

  String? displayName;
  String? avatarUrl;

  // Gamification metrics
  int xp = 0;
  int level = 1;
  int coins = 0;

  // Inventory/Room state (Ids of unlocked furniture)
  List<String> unlockedItems = [];

  // Achievement slugs
  List<String> achievementIds = [];

  // Timestamps
  DateTime lastActive = DateTime.now();
  DateTime createdAt = DateTime.now();
}
