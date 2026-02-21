import 'package:student_app/features/reward/domain/entities/reward_entities.dart';

class RoomItem {
  final String id;
  final String userId;
  final String shopItemId;
  final String slotKey;
  final ShopItem shopItem;

  RoomItem({
    required this.id,
    required this.userId,
    required this.shopItemId,
    required this.slotKey,
    required this.shopItem,
  });

  factory RoomItem.fromJson(Map<String, dynamic> json) {
    return RoomItem(
      id: json['id'],
      userId: json['userId'],
      shopItemId: json['shopItemId'],
      slotKey: json['slotKey'],
      shopItem: ShopItem.fromJson(json['shopItem']),
    );
  }
}

class RoomState {
  final List<RoomItem> items;

  RoomState({required this.items});

  factory RoomState.fromJson(List<dynamic> json) {
    return RoomState(items: json.map((i) => RoomItem.fromJson(i)).toList());
  }
}
