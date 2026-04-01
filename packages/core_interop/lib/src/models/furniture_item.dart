import 'package:meta/meta.dart';

@immutable
class FurnitureItem {
  final String id;
  final int numericId;
  final String name;
  final int price;
  final String type;
  final String slotType;
  final String assetPath;

  const FurnitureItem({
    required this.id,
    required this.numericId,
    required this.name,
    required this.price,
    required this.type,
    required this.slotType,
    required this.assetPath,
  });

  factory FurnitureItem.fromJson(Map<String, dynamic> json, Map<String, dynamic> defaults) {
    return FurnitureItem(
      id: json['id'] as String,
      numericId: json['numeric_id'] as int? ?? 0,
      name: json['name'] as String,
      price: json['price'] as int? ?? (defaults['price'] as int? ?? 100),
      type: json['type'] as String? ?? (defaults['type'] as String? ?? 'furniture'),
      slotType: json['slot_type'] as String? ?? 'unknown',
      assetPath: json['asset_path'] as String,
    );
  }
}

@immutable
class PlacedFurniture {
  final String slotId;
  final String itemId;
  final DateTime updatedAt;

  const PlacedFurniture({
    required this.slotId,
    required this.itemId,
    required this.updatedAt,
  });
}
