import 'package:equatable/equatable.dart';

class RoomItem extends Equatable {
  final String id;
  final String name;
  final String category;
  final int price;
  final String spriteKey;

  const RoomItem({
    required this.id,
    required this.name,
    required this.category,
    required this.price,
    required this.spriteKey,
  });

  @override
  List<Object?> get props => [id, name, category, price, spriteKey];
}

class RoomPlacement extends Equatable {
  final RoomItem item;
  final int slotIndex; // 0-15 for 4x4 grid

  const RoomPlacement({required this.item, required this.slotIndex});

  @override
  List<Object?> get props => [item, slotIndex];
}

class RoomLayout extends Equatable {
  final List<RoomPlacement> items;

  const RoomLayout({required this.items});

  @override
  List<Object?> get props => [items];
}
