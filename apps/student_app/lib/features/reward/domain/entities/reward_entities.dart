import 'package:equatable/equatable.dart';

class RewardBalance extends Equatable {
  final String userId;
  final int balance;

  const RewardBalance({required this.userId, required this.balance});

  @override
  List<Object?> get props => [userId, balance];
}

class ShopItem extends Equatable {
  final String id;
  final String key;
  final String name;
  final String? description;
  final int price;
  final String category;
  final bool isActive;

  const ShopItem({
    required this.id,
    required this.key,
    required this.name,
    this.description,
    required this.price,
    required this.category,
    required this.isActive,
  });

  @override
  List<Object?> get props => [
    id,
    key,
    name,
    description,
    price,
    category,
    isActive,
  ];

  factory ShopItem.fromJson(Map<String, dynamic> json) {
    return ShopItem(
      id: json['id'],
      key: json['key'],
      name: json['name'],
      description: json['description'],
      price: json['price'],
      category: json['category'],
      isActive: json['isActive'] ?? true,
    );
  }
}

class UserInventoryItem extends Equatable {
  final String userId;
  final String shopItemId;
  final int quantity;
  final ShopItem? shopItem;

  const UserInventoryItem({
    required this.userId,
    required this.shopItemId,
    required this.quantity,
    this.shopItem,
  });

  @override
  List<Object?> get props => [userId, shopItemId, quantity, shopItem];

  factory UserInventoryItem.fromJson(Map<String, dynamic> json) {
    return UserInventoryItem(
      userId: json['userId'],
      shopItemId: json['shopItemId'],
      quantity: json['quantity'],
      shopItem: json['shopItem'] != null
          ? ShopItem.fromJson(json['shopItem'])
          : null,
    );
  }
}
