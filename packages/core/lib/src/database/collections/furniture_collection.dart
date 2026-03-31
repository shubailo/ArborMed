import 'package:isar/isar.dart';

part 'furniture_collection.g.dart';

@collection
class FurnitureCollection {
  Id id = Isar.autoIncrement;

  @Index(unique: true, replace: true)
  late String slug;

  late String nameEn;
  late String nameHu;

  late String assetPath;
  late String type; // wall, floor, ornament, etc.

  // Position for the Room (Isar-backed positioning per user decision) 
  double x = 0.0;
  double y = 0.0;
  double z = 0.0;

  bool isPlaced = false;
  bool isLocked = true;
  int price = 0;

  // Metadata
  DateTime unlockedAt = DateTime.now();
  DateTime createdAt = DateTime.now();
}
