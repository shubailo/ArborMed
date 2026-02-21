import 'package:student_app/features/room/domain/entities/room_layout.dart';
import 'package:student_app/features/room/domain/entities/room_entities.dart';

class RoomVisitBeanDto {
  final String mood;

  RoomVisitBeanDto({required this.mood});

  factory RoomVisitBeanDto.fromJson(Map<String, dynamic> json) {
    return RoomVisitBeanDto(mood: json['mood'] ?? 'idle');
  }
}

class RoomVisitDto {
  final String userId;
  final String displayName;
  final String overallMasteryBand;
  final RoomLayout roomLayout;
  final List<RoomItem> roomItems;
  final RoomVisitBeanDto bean;

  RoomVisitDto({
    required this.userId,
    required this.displayName,
    required this.overallMasteryBand,
    required this.roomLayout,
    required this.roomItems,
    required this.bean,
  });

  factory RoomVisitDto.fromJson(Map<String, dynamic> json) {
    return RoomVisitDto(
      userId: json['userId'],
      displayName: json['displayName'],
      overallMasteryBand: json['overallMasteryBand'],
      roomLayout: RoomLayout.defaultClinical(),
      roomItems: (json['roomItems'] as List)
          .map((e) => RoomItem.fromJson(e))
          .toList(),
      bean: RoomVisitBeanDto.fromJson(json['bean']),
    );
  }
}
